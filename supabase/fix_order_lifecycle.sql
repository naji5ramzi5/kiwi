-- ============================================================
-- fix_order_lifecycle.sql — إصلاح جذري لدورة حياة الطلب
-- شغّل هذا الملف يدوياً في Supabase SQL Editor
-- ============================================================
-- المشاكل المُصلحة:
-- 1. تريغر خصم المخزون كان يعمل فقط مع الحالات العربية القديمة
--    ('قيد الانتظار' → 'تحضير') بينما التطبيقات تستخدم
--    pending/preparing/shipped — فالمخزون لم يكن يُخصم أبداً.
-- 2. لا يوجد إرجاع للمخزون عند إلغاء طلب بعد خصمه.
-- 3. تريغر إشعارات تغيير الحالة كان يقارن بحالات عربية فلا يرسل شيئاً.
-- 4. حالة السائق (current_status) لا تتحدث تلقائياً عند الإسناد/التسليم.
-- 5. حماية: منع تعديل حالة طلب مكتمل/ملغي، ومنع إلغاء الزبون لطلب في الطريق.
-- 6. تريغر FCM (notify_order_change) كان يستخدم عمود total_price غير الموجود
--    (الصحيح total_amount) وأي فشل فيه كان قد يُفشل تحديث الطلب نفسه.
-- ============================================================

-- ─── 1+2. خصم المخزون عند التحضير + إرجاعه عند الإلغاء ─────────
CREATE OR REPLACE FUNCTION public.update_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
  -- الخصم مرة واحدة فقط: عند خروج الطلب من حالة الانتظار إلى التحضير/الشحن
  IF (OLD.status IN ('pending', 'قيد الانتظار')
      AND NEW.status IN ('preparing', 'shipped', 'تحضير')) THEN
    UPDATE public.inventory inv
    SET stock_quantity = inv.stock_quantity - COALESCE((
          SELECT SUM(oi.quantity) FROM public.order_items oi
          WHERE oi.order_id = NEW.id AND oi.product_id = inv.product_id
        ), 0),
        updated_at = NOW()
    WHERE inv.branch_id = NEW.branch_id
      AND inv.product_id IN (SELECT product_id FROM public.order_items WHERE order_id = NEW.id);

  -- الإرجاع: إذا أُلغي/رُفض طلب سبق خصم مخزونه
  ELSIF (OLD.status IN ('preparing', 'shipped', 'تحضير')
         AND NEW.status IN ('cancelled', 'rejected', 'ملغي', 'مرفوض')) THEN
    UPDATE public.inventory inv
    SET stock_quantity = inv.stock_quantity + COALESCE((
          SELECT SUM(oi.quantity) FROM public.order_items oi
          WHERE oi.order_id = NEW.id AND oi.product_id = inv.product_id
        ), 0),
        updated_at = NOW()
    WHERE inv.branch_id = NEW.branch_id
      AND inv.product_id IN (SELECT product_id FROM public.order_items WHERE order_id = NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_stock_on_sale ON public.orders;
CREATE TRIGGER trigger_update_stock_on_sale
AFTER UPDATE OF status ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_sale();

-- ─── 3. إشعارات تغيير الحالة بالحالات الإنجليزية الفعلية ────────
CREATE OR REPLACE FUNCTION public.notify_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_title TEXT;
  v_body  TEXT;
  v_short_id TEXT;
BEGIN
  IF NEW.customer_id IS NULL OR NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  v_short_id := UPPER(LEFT(NEW.id::text, 6));

  CASE NEW.status
    WHEN 'preparing', 'جاري التحضير', 'تحضير' THEN
      v_title := '✅ تم تأكيد طلبك';
      v_body  := 'طلبك #' || v_short_id || ' قيد التجهيز في الفرع وسيتم توصيله قريباً';
    WHEN 'shipped', 'في الطريق', 'قيد التوصيل', 'في الطريق إليك' THEN
      v_title := '🛵 طلبك في الطريق!';
      v_body  := 'المندوب انطلق بطلبك #' || v_short_id || '، تجهز لاستلامه';
    WHEN 'delivered', 'تم التوصيل', 'تم التسليم', 'مكتمل' THEN
      v_title := '🎉 تم توصيل طلبك';
      v_body  := 'نتمنى لك تجربة رائعة! لا تنسَ تقييم المندوب لطلبك #' || v_short_id;
    WHEN 'cancelled', 'rejected', 'ملغي', 'مرفوض' THEN
      v_title := '❌ تم إلغاء طلبك';
      v_body  := 'نأسف، تم إلغاء طلبك #' || v_short_id || '. تواصل معنا إذا كان لديك استفسار';
    ELSE
      RETURN NEW;
  END CASE;

  INSERT INTO public.notifications (user_id, title, body, is_read)
  VALUES (NEW.customer_id, v_title, v_body, false);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_order_status ON public.orders;
CREATE TRIGGER trg_notify_order_status
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_order_status_change();

-- ─── 4. تحديث حالة السائق تلقائياً ──────────────────────────────
CREATE OR REPLACE FUNCTION public.sync_driver_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- عند إسناد الطلب وانطلاقه: السائق "في توصيلة"
  IF NEW.driver_id IS NOT NULL AND NEW.status = 'shipped' THEN
    UPDATE public.drivers SET current_status = 'في توصيلة', updated_at = NOW()
    WHERE id = NEW.driver_id;

  -- عند التسليم أو الإلغاء: السائق يعود "متاح" إذا لا توجد طلبات أخرى بعهدته
  ELSIF NEW.driver_id IS NOT NULL
        AND NEW.status IN ('delivered', 'cancelled', 'rejected') THEN
    UPDATE public.drivers d SET current_status = 'متاح', updated_at = NOW()
    WHERE d.id = NEW.driver_id
      AND NOT EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.driver_id = d.id AND o.status = 'shipped' AND o.id <> NEW.id
      );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_driver_status ON public.orders;
CREATE TRIGGER trg_sync_driver_status
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_driver_status();

-- ─── 5. حماية انتقالات الحالة ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.guard_order_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_role TEXT := COALESCE(public.get_my_role(), 'customer');
BEGIN
  -- الطلب المكتمل أو الملغي حالة نهائية لا تتغير
  IF OLD.status IN ('delivered', 'cancelled', 'rejected')
     AND NEW.status IS DISTINCT FROM OLD.status THEN
    RAISE EXCEPTION 'لا يمكن تغيير حالة طلب منتهي (%).', OLD.status;
  END IF;

  -- الزبون لا يستطيع إلغاء طلب انطلق مع السائق
  IF NEW.status IN ('cancelled') AND OLD.status IN ('shipped')
     AND v_role NOT IN ('admin', 'super_admin', 'branch_manager', 'staff') THEN
    RAISE EXCEPTION 'لا يمكن إلغاء الطلب بعد انطلاقه مع المندوب.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_order_status ON public.orders;
CREATE TRIGGER trg_guard_order_status
  BEFORE UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_order_status_transition();

-- ─── 6. إصلاح تريغر FCM: عمود خاطئ + عزل الأخطاء ────────────────
-- (يُطبق فقط إذا كنت قد شغّلت vx.sql سابقاً — آمن في كل الأحوال)
CREATE OR REPLACE FUNCTION public.notify_order_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  admin_id UUID;
BEGIN
  BEGIN  -- أي فشل في الإشعار يجب ألا يُفشل عملية الطلب نفسها
    IF TG_OP = 'INSERT' THEN
      FOR admin_id IN
        SELECT id FROM public.profiles WHERE role IN ('admin', 'super_admin')
      LOOP
        PERFORM net.http_post(
          url := current_setting('app.settings.edge_function_url') || '/send-fcm-notification',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
          ),
          body := jsonb_build_object(
            'userId', admin_id,
            'title', 'طلب جديد',
            'body', 'تم استلام طلب جديد بقيمة ' || NEW.total_amount::text || ' د.ع',
            'data', jsonb_build_object('orderId', NEW.id, 'type', 'new_order')
          )::text
        );
      END LOOP;
    ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
      PERFORM net.http_post(
        url := current_setting('app.settings.edge_function_url') || '/send-fcm-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
        ),
        body := jsonb_build_object(
          'userId', NEW.customer_id,
          'title', 'تحديث حالة الطلب',
          'body', 'تم تغيير حالة طلبك إلى: ' || NEW.status,
          'data', jsonb_build_object('orderId', NEW.id, 'type', 'status_update', 'status', NEW.status)
        )::text
      );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'FCM notify failed for order %: %', NEW.id, SQLERRM;
  END;
  RETURN NEW;
END;
$$;
