-- ============================================================
-- Migration 022: Missing view + Employee stats + Storage bucket
--
-- ROOT-CAUSE FIXES:
--  1. delivery_employees_with_profiles was referenced by the
--     Admin Dashboard (TransferDelivery), branch_pos
--     (pos_orders_controller, delivery_employees_screen) but had
--     NO definition anywhere -> every new deploy crashed those
--     pages. This migration defines it permanently.
--  2. delivery_employees_report now exposes daily / monthly /
--     lifetime deliveries AND earnings + last_active_at so the
--     reports page can show everything the spec requires.
--  3. The delivery_proofs storage bucket (used by the driver app
--     when uploading the delivery-confirmation photo) is now
--     guaranteed to exist.
-- ============================================================

-- ── 1. delivery_proofs storage bucket (idempotent) ──
INSERT INTO storage.buckets (id, name, public)
SELECT 'delivery_proofs', 'delivery_proofs', true
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'delivery_proofs');

-- ── 2. delivery_employees_with_profile view (missing definition) ──
CREATE OR REPLACE VIEW public.delivery_employees_with_profiles
WITH (security_invoker = true) AS
SELECT
    de.id,
    de.user_id,
    de.branch_id,
    de.phone,
    de.status,
    de.is_active,
    de.joined_at,
    de.transferred_at,
    de.total_deliveries,
    de.created_at,
    de.updated_at,
    p.full_name,
    p.email,
    p.vehicle_type,
    p.is_online,
    p.is_approved,
    p.plate_number,
    b.name AS branch_name
FROM public.delivery_employees de
LEFT JOIN public.profiles p ON p.id = de.user_id
LEFT JOIN public.branches b ON b.id = de.branch_id;

-- ── 3. Richer delivery_employees_report (daily/monthly/lifetime) ──
CREATE OR REPLACE VIEW public.delivery_employees_report
WITH (security_invoker = true) AS
SELECT
    de.id,
    de.user_id,
    p.full_name,
    p.phone,
    p.email,
    p.vehicle_type,
    p.is_approved AS account_status,
    p.is_online,
    de.branch_id,
    b.name AS branch_name,
    de.status AS online_status,
    de.is_active,
    de.joined_at,
    de.total_deliveries,
    COALESCE(w.balance, 0) AS wallet_balance,
    COALESCE(stat.today_deliveries, 0)   AS today_deliveries,
    COALESCE(stat.month_deliveries, 0)   AS month_deliveries,
    COALESCE(stat.today_earnings, 0)     AS today_earnings,
    COALESCE(stat.month_earnings, 0)     AS month_earnings,
    COALESCE(stat.total_earnings, 0)     AS total_earnings,
    COALESCE(dr.updated_at, de.updated_at) AS last_active_at
FROM public.delivery_employees de
LEFT JOIN public.profiles p ON p.id = de.user_id
LEFT JOIN public.branches b ON b.id = de.branch_id
LEFT JOIN public.driver_wallets w ON w.driver_id = de.user_id
LEFT JOIN public.drivers dr ON dr.id = de.user_id
LEFT JOIN LATERAL (
    SELECT
        COUNT(*) FILTER (WHERE e.created_at::date = CURRENT_DATE) AS today_deliveries,
        COUNT(*) FILTER (WHERE e.created_at >= date_trunc('month', now())) AS month_deliveries,
        COALESCE(SUM(e.amount) FILTER (WHERE e.created_at::date = CURRENT_DATE), 0) AS today_earnings,
        COALESCE(SUM(e.amount) FILTER (WHERE e.created_at >= date_trunc('month', now())), 0) AS month_earnings,
        COALESCE(SUM(e.amount), 0) AS total_earnings
    FROM public.delivery_earnings e
    WHERE e.delivery_employee_id = de.id
) stat ON true;

-- ── 4. Realtime publication for the employee list (dashboard) ──
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_earnings;

-- ── 5. Index: earnings lookups used by the driver app & reports ──
CREATE INDEX IF NOT EXISTS idx_delivery_earnings_employee_created
    ON public.delivery_earnings(delivery_employee_id, created_at DESC);