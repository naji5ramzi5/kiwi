-- ============================================================================
-- FIX: Order Lifecycle Sync - Inventory, Notifications, Driver Status
-- ============================================================================
-- تاريخ: 2026-07-06
-- المشاكل المعالجة:
-- 1. خصم المخزون معطل (يبحث عن حالات عربية بينما الكود يستخدم إنجليزي)
-- 2. إشعارات الحالة معطلة (نفس المشكلة)
-- 3. حالة السائق لا تتزامن
-- 4. تريغر FCM يستخدم عمود خاطئ
-- ============================================================================

-- ============================================================================
-- 1️⃣ إعادة كتابة تريغر خصم المخزون
-- ============================================================================
DROP TRIGGER IF EXISTS update_stock_on_sale ON orders;
DROP FUNCTION IF EXISTS fn_update_stock_on_sale();

CREATE OR REPLACE FUNCTION fn_update_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
  -- خصم المخزون عند الانتقال من pending إلى أي حالة أخرى (preparing/shipped/delivered)
  IF OLD.status = 'pending' AND NEW.status != 'pending' THEN
    -- إنقاص المخزون
    UPDATE branch_inventory
    SET actual_stock = actual_stock - oi.quantity
    FROM order_items oi
    WHERE oi.order_id = NEW.id
      AND branch_inventory.product_id = oi.product_id
      AND branch_inventory.branch_id = NEW.branch_id;
  END IF;

  -- إرجاع المخزون عند الإلغاء أو الرفض (بعد الخصم)
  IF OLD.status IN ('preparing', 'shipped', 'in_delivery') 
     AND NEW.status IN ('cancelled', 'rejected') THEN
    UPDATE branch_inventory
    SET actual_stock = actual_stock + oi.quantity
    FROM order_items oi
    WHERE oi.order_id = NEW.id
      AND branch_inventory.product_id = oi.product_id
      AND branch_inventory.branch_id = NEW.branch_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_stock_on_sale
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION fn_update_stock_on_sale();

-- ============================================================================
-- 2️⃣ إعادة كتابة تريغر الإشعارات (دعم الحالات الإنجليزية + العربية للتوافق)
-- ============================================================================
DROP TRIGGER IF EXISTS notify_order_status_change ON orders;
DROP FUNCTION IF EXISTS fn_notify_order_status_change();

CREATE OR REPLACE FUNCTION fn_notify_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_message TEXT;
  v_title TEXT;
BEGIN
  IF OLD.status != NEW.status THEN
    -- رسائل الحالات الإنجليزية
    CASE NEW.status
      WHEN 'preparing' THEN
        v_title := 'تم استلام طلبك';
        v_message := 'الفرع بدأ تجهيز طلبك. سيكون جاهزاً قريباً.';
      WHEN 'shipped' THEN
        v_title := 'طلبك في الطريق';
        v_message := 'تم إسناد طلبك لسائق. سيصل قريباً.';
      WHEN 'in_delivery' THEN
        v_title := 'السائق في الطريق';
        v_message := 'السائق في طريقه إليك الآن.';
      WHEN 'delivered' THEN
        v_title := 'تم التسليم';
        v_message := 'وصل طلبك بنجاح! شكراً لك.';
      WHEN 'cancelled' THEN
        v_title := 'تم إلغاء الطلب';
        v_message := 'تم إلغاء طلبك. سيتم استرجاع أموالك.';
      WHEN 'rejected' THEN
        v_title := 'تم رفض الطلب';
        v_message := 'للأسف، الفرع غير قادر على تجهيز طلبك.';
      ELSE
        v_title := 'تحديث الطلب';
        v_message := 'تم تحديث حالة طلبك إلى: ' || NEW.status;
    END CASE;

    -- إدراج الإشعار في جدول notifications (إن وُجد)
    -- أو استدعاء Edge Function للإشعارات
    INSERT INTO notifications (user_id, title, message, order_id, created_at)
    VALUES (
      NEW.customer_id,
      v_title,
      v_message,
      NEW.id,
      NOW()
    ) ON CONFLICT DO NOTHING;

  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notify_order_status_change
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION fn_notify_order_status_change();

-- ============================================================================
-- 3️⃣ تريغر جديد: مزامنة حالة السائق
-- ============================================================================
DROP TRIGGER IF EXISTS sync_driver_status_on_assignment ON orders;
DROP FUNCTION IF EXISTS fn_sync_driver_status();

CREATE OR REPLACE FUNCTION fn_sync_driver_status()
RETURNS TRIGGER AS $$
BEGIN
  -- عندما يتم إسناد السائق (driver_id != null)
  IF NEW.driver_id IS NOT NULL AND OLD.driver_id IS NULL THEN
    UPDATE drivers
    SET current_status = 'on_delivery'
    WHERE id = NEW.driver_id;
  END IF;

  -- عندما يتم التسليم
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
    UPDATE drivers
    SET current_status = 'available'
    WHERE id = NEW.driver_id;
  END IF;

  -- عندما يتم إلغاء/رفض الطلب
  IF NEW.status IN ('cancelled', 'rejected') AND OLD.status != NEW.status THEN
    UPDATE drivers
    SET current_status = 'available'
    WHERE id = NEW.driver_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_driver_status_on_assignment
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION fn_sync_driver_status();

-- ============================================================================
-- 4️⃣ تريغر حماية: منع تعديل الطلبات المنتهية
-- ============================================================================
DROP TRIGGER IF EXISTS prevent_completed_order_changes ON orders;
DROP FUNCTION IF EXISTS fn_prevent_completed_order_changes();

CREATE OR REPLACE FUNCTION fn_prevent_completed_order_changes()
RETURNS TRIGGER AS $$
BEGIN
  -- منع تعديل الطلبات المنتهية (delivered, cancelled, rejected)
  IF OLD.status IN ('delivered', 'cancelled', 'rejected') THEN
    RAISE EXCEPTION 'لا يمكن تعديل طلب منتهي';
  END IF;

  -- منع العميل من إلغاء طلب انطلق مع السائق (يجب على الإدارة فقط)
  IF OLD.status IN ('shipped', 'in_delivery') 
     AND NEW.status = 'cancelled'
     AND auth.uid() = OLD.customer_id THEN
    RAISE EXCEPTION 'لا يمكن إلغاء طلب في طريقه';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_completed_order_changes
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_completed_order_changes();

-- ============================================================================
-- 5️⃣ إصلاح تريغر FCM (العمود الصحيح + عزل الأخطاء)
-- ============================================================================
DROP TRIGGER IF EXISTS send_fcm_on_order_update ON orders;
DROP FUNCTION IF EXISTS fn_send_fcm_on_order_update();

CREATE OR REPLACE FUNCTION fn_send_fcm_on_order_update()
RETURNS TRIGGER AS $$
DECLARE
  v_fcm_token TEXT;
  v_total_amount DECIMAL;
BEGIN
  -- الحصول على FCM token والمبلغ الصحيح
  SELECT fcm_token INTO v_fcm_token
  FROM profiles
  WHERE id = NEW.customer_id;

  -- استخدام العمود الصحيح: total_amount بدل total_price
  v_total_amount := NEW.total_amount;

  -- عزل الأخطاء: إذا فشل إرسال FCM، لا نوقف الطلب
  BEGIN
    IF v_fcm_token IS NOT NULL AND NEW.status != OLD.status THEN
      -- استدعاء Edge Function لإرسال الإشعار
      -- (يتم تنفيذها بشكل غير متزامن)
      PERFORM
        net.http_post(
          url:='https://pftjlvtdzokbzuioqfug.supabase.co/functions/v1/send-fcm-notification',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('request.headers')::json->>'authorization' || '"}'::jsonb,
          body:=jsonb_build_object(
            'user_id', NEW.customer_id,
            'order_id', NEW.id,
            'status', NEW.status,
            'total_amount', v_total_amount
          )
        );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- تسجيل الخطأ ولكن لا نوقف الطلب
    RAISE WARNING 'FCM notification error: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER send_fcm_on_order_update
AFTER UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION fn_send_fcm_on_order_update();

-- ============================================================================
-- 6️⃣ التحقق من وجود جدول notifications (إنشاء إن لم يكن موجوداً)
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_notification UNIQUE(user_id, order_id, title, message)
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================================================
-- 7️⃣ تحديث RLS لجدول notifications
-- ============================================================================
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notifications_select_own ON notifications;
CREATE POLICY notifications_select_own
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS notifications_delete_own ON notifications;
CREATE POLICY notifications_delete_own
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- ملاحظات مهمة:
-- ============================================================================
-- ✅ جميع الحالات الآن موحدة: pending, preparing, shipped, in_delivery, delivered, cancelled, rejected
-- ✅ المخزون ينخصم مرة واحدة عند أول تحديث من pending
-- ✅ الإشعارات تعمل مع الحالات الإنجليزية
-- ✅ حالة السائق تتزامن تلقائياً
-- ✅ تريغر FCM معزول: إذا فشل، لا يُفشل الطلب
-- ✅ الطلبات المنتهية محمية من التعديل
-- ============================================================================
