-- ═══════════════════════════════════════════════════════════════
-- Patch: تفعيل نظام الإشعارات الحقيقي لتطبيق العميل
-- شغّل هذا الملف في Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. سياسات RLS: كل مستخدم يدير إشعاراته فقط ───────────────
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin full access on notifications" ON public.notifications;
DROP POLICY IF EXISTS "users_read_own_notifications" ON public.notifications;
DROP POLICY IF EXISTS "users_update_own_notifications" ON public.notifications;
DROP POLICY IF EXISTS "users_delete_own_notifications" ON public.notifications;
DROP POLICY IF EXISTS "system_insert_notifications" ON public.notifications;

CREATE POLICY "users_read_own_notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "users_update_own_notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "users_delete_own_notifications"
  ON public.notifications FOR DELETE
  USING (auth.uid() = user_id);

-- السماح لأي جهة موثّقة (لوحة التحكم/الفرع) بإنشاء إشعارات
CREATE POLICY "system_insert_notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'service_role');

-- ─── 2. تفعيل Realtime على جدول الإشعارات ─────────────────────
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION WHEN duplicate_object THEN
  NULL; -- الجدول مضاف مسبقاً
END $$;

-- ─── 3. Trigger: إشعار تلقائي عند تغيّر حالة الطلب ─────────────
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
  -- فقط عند تغيّر الحالة فعلياً ولطلبات التطبيق التي لها عميل
  IF NEW.customer_id IS NULL OR NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  v_short_id := UPPER(LEFT(NEW.id::text, 6));

  CASE NEW.status
    WHEN 'جاري التحضير' THEN
      v_title := '✅ تم تأكيد طلبك';
      v_body  := 'طلبك #' || v_short_id || ' قيد التجهيز في الفرع وسيتم توصيله قريباً';
    WHEN 'في الطريق', 'قيد التوصيل', 'في الطريق إليك' THEN
      v_title := '🛵 طلبك في الطريق!';
      v_body  := 'المندوب انطلق بطلبك #' || v_short_id || '، تجهز لاستلامه';
    WHEN 'تم التوصيل', 'تم التسليم', 'مكتمل' THEN
      v_title := '🎉 تم توصيل طلبك';
      v_body  := 'نتمنى لك تجربة رائعة! لا تنسَ تقييم المندوب لطلبك #' || v_short_id;
    WHEN 'ملغي', 'مرفوض' THEN
      v_title := '❌ تم إلغاء طلبك';
      v_body  := 'نأسف، تم إلغاء طلبك #' || v_short_id || '. تواصل معنا إذا كان لديك استفسار';
    ELSE
      RETURN NEW; -- حالات أخرى لا تولّد إشعاراً
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

-- ─── 4. إشعار ترحيبي عند إنشاء الطلب ──────────────────────────
CREATE OR REPLACE FUNCTION public.notify_order_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.customer_id IS NOT NULL AND COALESCE(NEW.order_type, 'app') = 'app' THEN
    INSERT INTO public.notifications (user_id, title, body, is_read)
    VALUES (
      NEW.customer_id,
      '🛒 تم استلام طلبك',
      'طلبك #' || UPPER(LEFT(NEW.id::text, 6)) || ' وصل للفرع وجاري مراجعته الآن',
      false
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_order_created ON public.orders;
CREATE TRIGGER trg_notify_order_created
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_order_created();

-- ─── 5. تنظيف تلقائي: حذف الإشعارات الأقدم من 30 يوم ──────────
-- (تُنفذ عند كل إدخال جديد بشكل خفيف)
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.notifications WHERE created_at < now() - INTERVAL '30 days';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cleanup_notifications ON public.notifications;
CREATE TRIGGER trg_cleanup_notifications
  AFTER INSERT ON public.notifications
  FOR EACH STATEMENT
  EXECUTE FUNCTION public.cleanup_old_notifications();
