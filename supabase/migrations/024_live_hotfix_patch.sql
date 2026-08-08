-- PATCH للقاعدة الحية fresh-app — مبني على تعريف القاعدة الفعلية (فحص 2026-08-08)

-- ── 1. أعمدة العنوان التفصيلي في orders ────────────────────────────────
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS area VARCHAR(255);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS street VARCHAR(255);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS building VARCHAR(255);

CREATE INDEX IF NOT EXISTS idx_orders_area ON public.orders(area);
CREATE INDEX IF NOT EXISTS idx_orders_branch_area ON public.orders(branch_id, area);
COMMENT ON COLUMN public.orders.area IS 'منطقة التوصيل (تعبأ تلقائياً من GPS)';
COMMENT ON COLUMN public.orders.street IS 'شارع التوصيل (تعبأ تلقائياً من GPS)';
COMMENT ON COLUMN public.orders.building IS 'رقم/اسم البناء (اختياري)';

-- ── 2. مفاتيح الأرباح حسب نوع المركبة ─────────────────────────────────
INSERT INTO public.system_settings (key, value_decimal) VALUES
    ('delivery_earnings_motorcycle', 0),
    ('delivery_earnings_car',        0),
    ('delivery_earnings_van',        0),
    ('delivery_earnings_truck',      0)
ON CONFLICT (key) DO NOTHING;

-- ── 3. Storage bucket لصور إثبات التوصيل ───────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('delivery_proofs', 'delivery_proofs', true)
ON CONFLICT (id) DO NOTHING;

-- ── 4. إعادة بناء delivered_orders_report (بنية مطابقة للقاعدة) ────────
DROP VIEW IF EXISTS public.delivered_orders_report;
CREATE VIEW public.delivered_orders_report AS
SELECT
    o.id,
    upper(substr((o.id)::text, 1, 8)) AS order_number,
    o.customer_name_manual,
    o.customer_phone,
    o.delivery_address,
    o.area,
    o.street,
    o.building,
    o.total_amount,
    o.delivery_fee,
    o.delivered_at,
    o.proof_image,
    o.customer_lat,
    o.customer_lng,
    o.notes,
    b.name AS branch_name,
    de.id AS delivery_employee_id,
    p.full_name AS employee_name,
    p.phone AS employee_phone,
    p.vehicle_type,
    de.joined_at AS employee_joined_at,
    e.amount AS delivery_earnings
FROM public.orders o
LEFT JOIN public.branches b ON b.id = o.branch_id
LEFT JOIN public.delivery_employees de ON de.id = o.assigned_delivery_id
LEFT JOIN public.profiles p ON p.id = de.user_id
LEFT JOIN public.delivery_earnings e ON e.order_id = o.id
WHERE o.status = 'delivered';

COMMENT ON VIEW public.delivered_orders_report IS 'تقرير الطلبات المسلمة مع أرباح التوصيل والعنوان التفصيلي';

-- ── 5. إعادة بناء delivery_employees_report (إضافة أرباح يوم/شهر + آخر نشاط) ─
DROP VIEW IF EXISTS public.delivery_employees_report;
CREATE VIEW public.delivery_employees_report AS
SELECT
    de.id,
    de.user_id,
    p.full_name,
    p.phone,
    p.email,
    p.vehicle_type,
    p.is_approved AS account_status,
    de.branch_id,
    b.name AS branch_name,
    de.status AS online_status,
    de.is_active,
    de.joined_at,
    de.total_deliveries,
    COALESCE(w.balance, 0) AS wallet_balance,
    (SELECT COUNT(*) FROM public.delivery_earnings e
      WHERE e.delivery_employee_id = de.id AND e.created_at::date = CURRENT_DATE) AS today_deliveries,
    (SELECT COUNT(*) FROM public.delivery_earnings e
      WHERE e.delivery_employee_id = de.id AND e.created_at >= date_trunc('month', CURRENT_DATE)) AS month_deliveries,
    (SELECT COALESCE(SUM(e.amount), 0) FROM public.delivery_earnings e
      WHERE e.delivery_employee_id = de.id AND e.created_at::date = CURRENT_DATE) AS today_earnings,
    (SELECT COALESCE(SUM(e.amount), 0) FROM public.delivery_earnings e
      WHERE e.delivery_employee_id = de.id AND e.created_at >= date_trunc('month', CURRENT_DATE)) AS month_earnings,
    (SELECT COALESCE(SUM(e.amount), 0) FROM public.delivery_earnings e
      WHERE e.delivery_employee_id = de.id) AS total_earnings,
    GREATEST(de.updated_at,
      COALESCE((SELECT MAX(e2.created_at) FROM public.delivery_earnings e2
        WHERE e2.delivery_employee_id = de.id), de.updated_at)) AS last_active_at
FROM public.delivery_employees de
LEFT JOIN public.profiles p ON p.id = de.user_id
LEFT JOIN public.branches b ON b.id = de.branch_id
LEFT JOIN public.driver_wallets w ON w.driver_id = de.user_id;

COMMENT ON VIEW public.delivery_employees_report IS 'تقرير موظفي التوصيل: حالة، فرع، أرباح يوم/شهر/إجمالي، آخر نشاط';

-- ── 5. فهرس لأرباح التوصيل ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_delivery_earnings_employee_created
ON public.delivery_earnings(delivery_employee_id, created_at DESC);

-- ── 6. realtime على delivery_earnings ───────────────────────────────────
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_earnings;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

SELECT 'تم تطبيق الفحص على القاعدة الحية' AS status;