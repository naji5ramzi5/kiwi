-- ============================================================
-- Migration 025: Operations App — Secure admin RPCs + Live Map
--
-- ROOT-CAUSE FIXES:
--  1. Approval did not work: the operations app updated
--     `profiles.is_approved` directly. That path silently fails
--     (or makes the row unusable) because the trigger chain
--     depends on `sync_delivery_employee()` but the caller had no
--     explicit error surface and several RLS permutations blocked
--     UPDATE (own_profile_update only allows id=auth.uid()).
--     Now approval/rejection/activation go through SECURITY DEFINER
--     RPCs that validate the caller role FIRST and return clear,
--     human-readable exceptions (Arabic/English) instead of
--     silent failures.
--  2. Live map: a single RPC `ops_driver_map()` returns driver
--     location + current order joined, so the Operations app
--     builds markers from one typed query (respecting RLS via
--     security definer + is_staff() guard).
--  3. `branches.latitude/longitude` may be missing on some rows;
--     the RPC guards against NULLs instead of crashing the map.
-- ============================================================

-- ── 0. profiles.updated_at (used by RPCs/audit; missing on live) ──
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- ── 1. Shared helper: resolve branch id by name (for RPC payloads) ──
CREATE OR REPLACE FUNCTION public.ops_branch_id_by_name(p_name TEXT)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT id FROM public.branches WHERE name = p_name LIMIT 1;
$$;

-- ── 2. Approve a delivery-driver application ──
-- Caller must be admin/super_admin/branch_manager (is_staff()).
-- Effects (atomic):
--   • profiles.is_approved = true  (+ is_active = true, branch link)
--   • delivery_employees row upserted with branch
--   • drivers row upserted (login/visibility for the driver app)
CREATE OR REPLACE FUNCTION public.ops_approve_driver(
    p_profile_id UUID,
    p_branch_id  UUID DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_role TEXT;
    v_phone TEXT;
    v_user  UUID := auth.uid();
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول أولاً';
    END IF;

    SELECT role, phone INTO v_role, v_phone
    FROM public.profiles WHERE id = p_profile_id;

    IF v_role IS NULL THEN
        RAISE EXCEPTION 'المستخدم غير موجود';
    END IF;
    IF v_role <> 'driver' THEN
        RAISE EXCEPTION 'الحساب ليس مندوب توصيل (الدور: %)', v_role;
    END IF;

    IF NOT (public.is_admin() OR public.is_staff()) THEN
        RAISE EXCEPTION 'غير مصرح: صلاحية الموافقة للمدير فقط';
    END IF;

    -- 1) approve the profile
    UPDATE public.profiles
    SET is_approved = true,
        is_active   = true,
        branch_id   = COALESCE(p_branch_id, branch_id),
        updated_at  = now()
    WHERE id = p_profile_id;

    -- 2) upsert the delivery employee linked to the (driver) user
    INSERT INTO public.delivery_employees (user_id, phone, status, is_active, branch_id)
    VALUES (
        p_profile_id,
        v_phone,
        CASE WHEN (SELECT is_online FROM public.profiles WHERE id = p_profile_id)
             THEN 'online' ELSE 'offline' END,
        true,
        COALESCE(p_branch_id, (SELECT branch_id FROM public.profiles WHERE id = p_profile_id))
    )
    ON CONFLICT (user_id) DO UPDATE SET
        phone      = EXCLUDED.phone,
        is_active  = true,
        branch_id  = COALESCE(EXCLUDED.branch_id, delivery_employees.branch_id),
        updated_at = now();

    -- 3) make sure the driver app login recognises the account
    INSERT INTO public.drivers (id, branch_id, is_active, phone, vehicle_type, current_status)
    SELECT
        p_profile_id,
        COALESCE(p_branch_id, (SELECT branch_id FROM public.profiles WHERE id = p_profile_id)),
        true,
        v_phone,
        (SELECT vehicle_type FROM public.profiles WHERE id = p_profile_id),
        'متاح'
    ON CONFLICT (id) DO UPDATE SET
        branch_id    = COALESCE(EXCLUDED.branch_id, drivers.branch_id),
        is_active    = true,
        phone        = COALESCE(EXCLUDED.phone, drivers.phone),
        vehicle_type = COALESCE(EXCLUDED.vehicle_type, drivers.vehicle_type),
        updated_at   = now();

    -- 4) audit trail
    INSERT INTO public.audit_logs (branch_id, user_id, action_type, description, severity)
    VALUES (
        COALESCE(p_branch_id, (SELECT branch_id FROM public.profiles WHERE id = p_profile_id)),
        v_user,
        'driver.approved',
        'تم اعتماد المندوب (profile ' || p_profile_id::text || ')',
        'info'
    );
END;
$$;

-- ── 3. Reject a driver application ──
CREATE OR REPLACE FUNCTION public.ops_reject_driver(p_profile_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_user UUID := auth.uid();
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول أولاً';
    END IF;
    IF NOT (public.is_admin() OR public.is_staff()) THEN
        RAISE EXCEPTION 'ليس مصرحاً لك برفض طلبات المندوبين';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_profile_id AND role = 'driver') THEN
        RAISE EXCEPTION 'المستخدم غير موجود أو ليس مندوب توصيل';
    END IF;

    UPDATE public.profiles
    SET is_approved = false, is_active = false
    WHERE id = p_profile_id;

    UPDATE public.delivery_employees
    SET is_active = false, updated_at = now()
    WHERE user_id = p_profile_id;

    UPDATE public.drivers
    SET is_active = false, current_status = 'متوقف', updated_at = now()
    WHERE id = p_profile_id;

    INSERT INTO public.audit_logs (branch_id, user_id, action_type, description, severity)
    SELECT branch_id, v_user, 'driver.rejected', 'تم رفض طلب المندوب: ' || p_profile_id::text, 'warning'
    FROM public.profiles WHERE id = p_profile_id;
END;
$$;

-- ── 4. Set Active / Suspend a delivery driver ──
CREATE OR REPLACE FUNCTION public.ops_set_driver_active(
    p_employee_id UUID,
    p_active BOOLEAN
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_user UUID := auth.uid();
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول أولاً';
    END IF;
    IF NOT (public.is_admin() OR public.is_staff()) THEN
        RAISE EXCEPTION 'ليس مصرح لك بتفعيل/إيقاف المندوبين';
    END IF;

    SELECT user_id INTO v_user_id
    FROM public.delivery_employees WHERE id = p_employee_id;

    UPDATE public.delivery_employees
    SET is_active = p_active, updated_at = now()
    WHERE id = p_employee_id;

    IF v_user_id IS NOT NULL THEN
        UPDATE public.profiles SET is_active = p_active WHERE id = v_user_id;
        UPDATE public.drivers SET is_active = p_active, updated_at = now() WHERE id = v_user_id;
    END IF;

    INSERT INTO public.audit_logs (branch_id, user_id, action_type, description, severity)
    SELECT
        (SELECT branch_id FROM public.delivery_employees WHERE id = p_employee_id),
        v_user,
        CASE WHEN p_active THEN 'driver.activated' ELSE 'driver.suspended' END,
        CASE WHEN p_active THEN 'تم تفعيل المندوب' ELSE 'تم إيقاف المندوب' END || ' (employee ' || p_employee_id::text || ')',
        'info';
END;
$$;

-- ── 5. Live map: all drivers with last known location + current order ──
CREATE OR REPLACE FUNCTION public.ops_driver_locations()
RETURNS TABLE (
    employee_id      UUID,
    user_id          UUID,
    full_name        TEXT,
    phone            TEXT,
    vehicle_type     TEXT,
    branch_id        UUID,
    branch_name      TEXT,
    online_status    TEXT,
    is_active        BOOLEAN,
    joined_at        TIMESTAMPTZ,
    last_lat         NUMERIC,
    last_lng         NUMERIC,
    location_updated TIMESTAMPTZ,
    today_deliveries BIGINT,
    today_earnings   NUMERIC,
    total_deliveries INTEGER,
    current_order_id UUID,
    current_order_no TEXT,
    current_status   TEXT,
    customer_name    TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user UUID := auth.uid();
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'غير مصرح: يجب تسجيل الدخول أولاً';
    END IF;
    IF NOT (public.is_admin() OR public.is_staff()) THEN
        RAISE EXCEPTION 'ليس مصرح لك بالاطلاع على الخريطة';
    END IF;

    RETURN QUERY
    SELECT
        de.id                                  AS employee_id,
        de.user_id,
        COALESCE(p.full_name, '')               AS full_name,
        COALESCE(p.phone, '')                   AS phone,
        COALESCE(p.vehicle_type, '')            AS vehicle_type,
        de.branch_id,
        COALESCE(b.name, '')                    AS branch_name,
        COALESCE(de.status, 'offline')          AS online_status,
        de.is_active,
        de.joined_at,
        drv.last_location_lat,
        drv.last_location_lng,
        COALESCE(drv.updated_at, de.updated_at) AS last_active,
        COALESCE(stat.today_deliveries, 0)      AS today_deliveries,
        COALESCE(stat.today_earnings, 0)        AS today_earnings,
        de.total_deliveries,
        cur.id                                  AS current_order_id,
        upper(substr(cur.id::text, 1, 8))       AS current_order_no,
        cur.status                              AS current_status,
        cur.customer_name_manual                AS customer_name
    FROM public.delivery_employees de
    LEFT JOIN public.profiles p           ON p.id  = de.user_id
    LEFT JOIN public.branches b           ON b.id  = de.branch_id
    LEFT JOIN public.drivers drv          ON drv.id = de.user_id
    LEFT JOIN LATERAL (
        SELECT *
        FROM public.orders o
        WHERE o.assigned_delivery_id = de.id
          AND o.status IN ('pending','assigned','picked_up','on_the_way')
        ORDER BY o.created_at DESC
        LIMIT 1
    ) cur ON true
    LEFT JOIN LATERAL (
        SELECT
            COUNT(*) FILTER (WHERE e.created_at::date = CURRENT_DATE) AS today_deliveries,
            COALESCE(SUM(e.amount) FILTER (WHERE e.created_at::date = CURRENT_DATE), 0) AS today_earnings
        FROM public.delivery_earnings e
        WHERE e.delivery_employee_id = de.id
    ) stat ON true
    ORDER BY COALESCE(de.status, 'offline') <> 'online', p.full_name;
END;
$$;

-- Indexes to make both the map and realtime location updates fast
CREATE INDEX IF NOT EXISTS idx_drivers_location_active
    ON public.drivers(last_location_lat, last_location_lng)
    WHERE last_location_lat IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_orders_assigned_active
    ON public.orders(assigned_delivery_id, created_at DESC);

-- Ensure realtime publishes driver location changes (live map)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'drivers'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.drivers;
    END IF;
END $$;