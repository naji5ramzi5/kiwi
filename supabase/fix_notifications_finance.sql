-- ============================================================
-- fix_notifications_finance.sql — إصلاح الإشعارات والتسويات المالية
-- شغّل هذا الملف في Supabase SQL Editor (بعد fix_security_rls.sql)
--
-- المشاكل الجذرية المكتشفة:
-- 1) دالة handle-order-completion (توزيع أرباح الشركاء) لا يستدعيها
--    أي تطبيق أبداً + تستخدم أعمدة غير موجودة (dev_profit, order_id,
--    is_settled) → التسويات المالية لا تُسجل إطلاقاً.
-- 2) جدول notifications ينقصه عمودا type و data المستخدمان في الكود.
-- 3) لا حماية من تكرار تسجيل التسوية لنفس الطلب.
-- الحل: نقل منطق التسوية إلى تريغر داخل قاعدة البيانات يعمل تلقائياً
-- عند اكتمال الطلب، بدون الاعتماد على استدعاءات خارجية.
-- ============================================================

-- ─── 1. أعمدة ناقصة ─────────────────────────────────────────
ALTER TABLE IF EXISTS public.notifications
  ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'info',
  ADD COLUMN IF NOT EXISTS data JSONB;

ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- ربط التسوية بالطلب + منع التكرار
ALTER TABLE IF EXISTS public.partner_settlements
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_partner_settlements_order
  ON public.partner_settlements(order_id) WHERE order_id IS NOT NULL;

-- ─── 2. تريغر التسوية المالية عند اكتمال الطلب ──────────────
CREATE OR REPLACE FUNCTION public.record_partner_settlement()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  v_dev_ratio NUMERIC := 0.35;
  v_maint_ratio NUMERIC := 0.10;
  v_total NUMERIC;
  v_dev NUMERIC;
  v_maint NUMERIC;
BEGIN
  -- فقط عند الانتقال إلى حالة التوصيل النهائية
  IF NEW.status IN ('delivered', 'تم التوصيل', 'مكتمل', 'completed')
     AND (OLD.status IS DISTINCT FROM NEW.status) THEN

    -- قراءة النسب من الإعدادات مع قيم افتراضية آمنة
    BEGIN
      SELECT COALESCE(
        (SELECT value_decimal FROM public.system_settings WHERE key = 'dev_partner_ratio'),
        0.35) INTO v_dev_ratio;
      SELECT COALESCE(
        (SELECT value_decimal FROM public.system_settings WHERE key = 'system_maintenance_ratio'),
        0.10) INTO v_maint_ratio;
    EXCEPTION WHEN OTHERS THEN
      v_dev_ratio := 0.35; v_maint_ratio := 0.10;
    END;

    v_total := COALESCE(NEW.total_amount, 0);
    v_dev   := ROUND(v_total * v_dev_ratio, 2);
    v_maint := ROUND(v_total * v_maint_ratio, 2);

    INSERT INTO public.partner_settlements
      (order_id, branch_id, total_revenue, dev_partner_share, maintenance_fund, branch_profit)
    VALUES
      (NEW.id, NEW.branch_id, v_total, v_dev, v_maint, v_total - v_dev - v_maint)
    ON CONFLICT (order_id) WHERE order_id IS NOT NULL DO NOTHING;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- عزل الأخطاء: فشل التسوية لا يفشل تحديث الطلب
  RAISE WARNING 'record_partner_settlement failed: %', SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_record_partner_settlement ON public.orders;
CREATE TRIGGER trg_record_partner_settlement
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.record_partner_settlement();

-- ─── 3. تفعيل Realtime على جدول الإشعارات (يعمل بدون FCM) ────
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ─── 4. تحقق نهائي ──────────────────────────────────────────
SELECT 'settlement trigger' AS item,
       COUNT(*)::TEXT AS installed
FROM pg_trigger WHERE tgname = 'trg_record_partner_settlement'
UNION ALL
SELECT 'notifications.type column',
       COUNT(*)::TEXT
FROM information_schema.columns
WHERE table_name='notifications' AND column_name='type';
