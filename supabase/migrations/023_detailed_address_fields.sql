-- ============================================================
-- Migration 023: Detailed address fields for orders
-- Adds Area, Street, Building columns to support PART 2 requirements
-- ============================================================

-- ── 1. Add detailed address columns to orders ──
ALTER TABLE public.orders
ADD COLUMN IF NOT EXISTS area VARCHAR(255),
ADD COLUMN IF NOT EXISTS street VARCHAR(255),
ADD COLUMN IF NOT EXISTS building VARCHAR(255);

-- ── 2. Index for address-based queries ──
CREATE INDEX IF NOT EXISTS idx_orders_area ON public.orders(area);
CREATE INDEX IF NOT EXISTS idx_orders_branch_area ON public.orders(branch_id, area);

-- ── 3. Update delivered_orders_report view to include new fields ──
CREATE OR REPLACE VIEW public.delivered_orders_report
WITH (security_invoker = true) AS
SELECT
    o.id,
    upper(substr(o.id::text, 1, 8)) AS order_number,
    o.customer_name_manual,
    o.customer_phone,
    o.delivery_address,
    o.area,
    o.street,
    o.building,
    o.total_amount,
    o.delivery_fee,
    o.status,
    o.delivered_at,
    o.proof_image,
    o.branch_id,
    b.name  AS branch_name,
    de.id   AS delivery_employee_id,
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

-- ── 4. Add comment for documentation ──
COMMENT ON COLUMN public.orders.area IS 'منطقة/حي العميل (مثال: الكرادة، المنصور)';
COMMENT ON COLUMN public.orders.street IS 'اسم الشارع';
COMMENT ON COLUMN public.orders.building IS 'رقم/اسم البناء أو المجمع';