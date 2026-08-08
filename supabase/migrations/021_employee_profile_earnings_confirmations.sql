-- ============================================================
-- Migration 021: Employee Profile, Per-Vehicle Earnings,
-- Approval FIX, Delivery Confirmations, Report Views
--
-- ROOT-CAUSE FIXES included:
--  1. sync_delivery_employee() CHECK violation (approval fails):
--     COALESCE(NEW.is_online::text,'offline') produced 'false'
--     which violates delivery_employees_status_check. Now uses
--     CASE WHEN NEW.is_online THEN 'online' ELSE 'offline' END.
--  2. Per-vehicle-type delivery earnings:
--     delivery_earnings_motorcycle / _car / _van / _truck
--     (0 => falls back to delivery_earnings_per_order => delivery_fee)
--  3. Delivery confirmation records (photo, time, employee, order,
--     GPS) linked permanently via delivery_confirmations + RPC.
--  4. assign_order_to_delivery now syncs drivers.phone +
--     drivers.vehicle_type so the customer app can display the
--     assigned employee's contact info.
--  5. Employee statistics views for the Admin Dashboard reports.
-- ============================================================

-- ── 1. FIX sync_delivery_employee (root cause of approval failure) ──
CREATE OR REPLACE FUNCTION public.sync_delivery_employee()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.role = 'driver' AND NEW.is_approved = true THEN
        INSERT INTO public.delivery_employees (user_id, phone, status, is_active, branch_id)
        VALUES (
            NEW.id,
            NEW.phone,
            CASE WHEN NEW.is_online THEN 'online' ELSE 'offline' END,
            true,
            NEW.branch_id
        )
        ON CONFLICT (user_id)
        DO UPDATE SET
            phone      = EXCLUDED.phone,
            branch_id  = COALESCE(EXCLUDED.branch_id, delivery_employees.branch_id),
            status     = CASE WHEN NEW.is_online THEN 'online' ELSE 'offline' END,
            is_active  = true,
            updated_at = now();
    ELSIF NEW.role = 'driver' AND NEW.is_approved = false THEN
        UPDATE public.delivery_employees
        SET is_active = false, updated_at = now()
        WHERE user_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

-- ── 2. Per-vehicle-type delivery earnings settings ──
INSERT INTO public.system_settings (key, value_decimal) VALUES
    ('delivery_earnings_motorcycle', 0),
    ('delivery_earnings_car',        0),
    ('delivery_earnings_van',        0),
    ('delivery_earnings_truck',      0)
ON CONFLICT (key) DO NOTHING;

-- ── 3. Rewrite earnings trigger: amount = per-vehicle setting ──
CREATE OR REPLACE FUNCTION public.record_delivery_earning()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_amount DECIMAL(12,2);
    v_employee_user_id UUID;
    v_vehicle_type TEXT;
    v_rate_key TEXT;
BEGIN
    IF NEW.status = 'delivered'
       AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'delivered')
       AND NEW.assigned_delivery_id IS NOT NULL THEN

        -- Resolve the employee's vehicle type (profiles.vehicle_type)
        SELECT de.user_id, p.vehicle_type
        INTO v_employee_user_id, v_vehicle_type
        FROM public.delivery_employees de
        LEFT JOIN public.profiles p ON p.id = de.user_id
        WHERE de.id = NEW.assigned_delivery_id;

        v_rate_key := CASE COALESCE(v_vehicle_type, '')
            WHEN 'truck' THEN 'delivery_earnings_truck'
            WHEN 'car'   THEN 'delivery_earnings_car'
            WHEN 'van'   THEN 'delivery_earnings_van'
            WHEN 'bike'  THEN 'delivery_earnings_motorcycle'
            ELSE 'delivery_earnings_per_order'
        END;

        v_amount := COALESCE(
            NULLIF((SELECT value_decimal FROM public.system_settings WHERE key = v_rate_key), 0),
            NULLIF((SELECT value_decimal FROM public.system_settings WHERE key = 'delivery_earnings_per_order'), 0),
            COALESCE(NEW.delivery_fee, 0)
        );

        INSERT INTO public.delivery_earnings (order_id, delivery_employee_id, branch_id, amount)
        VALUES (NEW.id, NEW.assigned_delivery_id, NEW.branch_id, v_amount)
        ON CONFLICT (order_id) DO UPDATE SET
            delivery_employee_id = EXCLUDED.delivery_employee_id,
            branch_id = EXCLUDED.branch_id,
            amount = EXCLUDED.amount;

        IF v_employee_user_id IS NOT NULL THEN
            INSERT INTO public.driver_wallets (driver_id, balance)
            VALUES (v_employee_user_id, v_amount)
            ON CONFLICT (driver_id) DO UPDATE SET
                balance = driver_wallets.balance + EXCLUDED.balance,
                updated_at = now();
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- ── 4. Delivery confirmations (permanent, linked to the order) ──
CREATE TABLE IF NOT EXISTS public.delivery_confirmations (
    id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id             UUID NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
    delivery_employee_id UUID REFERENCES public.delivery_employees(id) ON DELETE SET NULL,
    branch_id            UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    confirmation_photo   TEXT,
    delivered_at         TIMESTAMPTZ DEFAULT now(),
    latitude             NUMERIC(10,8),
    longitude            NUMERIC(11,8),
    created_at           TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_delivery_confirmations_employee
    ON public.delivery_confirmations(delivery_employee_id, delivered_at DESC);
CREATE INDEX IF NOT EXISTS idx_delivery_confirmations_branch
    ON public.delivery_confirmations(branch_id, delivered_at DESC);

ALTER TABLE public.delivery_confirmations ENABLE ROW LEVEL SECURITY;

-- admin/staff full access
DROP POLICY IF EXISTS admin_all_delivery_confirmations ON public.delivery_confirmations;
CREATE POLICY admin_all_delivery_confirmations ON public.delivery_confirmations
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR public.is_staff())
    WITH CHECK (public.is_admin() OR public.is_staff());

-- branch managers see their branch
DROP POLICY IF EXISTS branch_delivery_confirmations_select ON public.delivery_confirmations;
CREATE POLICY branch_delivery_confirmations_select ON public.delivery_confirmations
    FOR SELECT
    TO authenticated
    USING (branch_id = public.get_my_branch_id());

-- employee sees own confirmations
DROP POLICY IF EXISTS employee_own_confirmations ON public.delivery_confirmations;
CREATE POLICY employee_own_confirmations ON public.delivery_confirmations
    FOR SELECT
    TO authenticated
    USING (
        delivery_employee_id IN (
            SELECT id FROM public.delivery_employees WHERE user_id = auth.uid()
        )
    );

-- employee may insert own confirmation
DROP POLICY IF EXISTS employee_insert_confirmation ON public.delivery_confirmations;
CREATE POLICY employee_insert_confirmation ON public.delivery_confirmations
    FOR INSERT
    TO authenticated
    WITH CHECK (
        delivery_employee_id IN (
            SELECT id FROM public.delivery_employees WHERE user_id = auth.uid()
        )
    );

-- ── 5. confirm_delivery RPC: photo + GPS + order close atomically ──
CREATE OR REPLACE FUNCTION public.confirm_delivery(
    p_order_id UUID,
    p_photo_url TEXT DEFAULT NULL,
    p_latitude NUMERIC DEFAULT NULL,
    p_longitude NUMERIC DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_employee_id UUID;
    v_employee_user_id UUID;
    v_branch_id UUID;
BEGIN
    -- The caller must be the assigned delivery employee (or an admin/staff)
    SELECT id, user_id INTO v_employee_id, v_employee_user_id
    FROM public.delivery_employees
    WHERE user_id = auth.uid();

    IF v_employee_id IS NULL AND NOT (public.is_admin() OR public.is_staff()) THEN
        RAISE EXCEPTION 'Only the assigned employee or admin can confirm delivery';
    END IF;

    SELECT branch_id INTO v_branch_id FROM public.orders WHERE id = p_order_id;

    -- Guard: assigned employee must match the order
    IF v_employee_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.orders
            WHERE id = p_order_id AND assigned_delivery_id = v_employee_id
        ) THEN
            RAISE EXCEPTION 'This order is not assigned to you';
        END IF;
    END IF;

    -- Record confirmation (upsert; idempotent)
    INSERT INTO public.delivery_confirmations
        (order_id, delivery_employee_id, branch_id, confirmation_photo, latitude, longitude, delivered_at)
    VALUES
        (p_order_id, v_employee_id, v_branch_id, p_photo_url, p_latitude, p_longitude, now())
    ON CONFLICT (order_id) DO UPDATE SET
        delivery_employee_id = EXCLUDED.delivery_employee_id,
        branch_id = EXCLUDED.branch_id,
        confirmation_photo = COALESCE(EXCLUDED.confirmation_photo, delivery_confirmations.confirmation_photo),
        latitude = COALESCE(EXCLUDED.latitude, delivery_confirmations.latitude),
        longitude = COALESCE(EXCLUDED.longitude, delivery_confirmations.longitude),
        delivered_at = now();

    -- Close the order (only if not already closed; idempotent)
    UPDATE public.orders
    SET status = 'delivered',
        proof_image = COALESCE(p_photo_url, proof_image),
        delivered_at = COALESCE(delivered_at, now()),
        updated_at = now()
    WHERE id = p_order_id
      AND status NOT IN ('delivered', 'cancelled', 'rejected');
END;
$$;

-- ── 6. FIX assign_order_to_delivery: sync drivers.phone/vehicle_type ──
ALTER TABLE public.drivers ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

CREATE OR REPLACE FUNCTION public.assign_order_to_delivery(
    p_order_id UUID,
    p_employee_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_branch_id UUID;
    v_emp_branch_id UUID;
    v_user_id UUID;
    v_phone VARCHAR(20);
    v_vehicle_type VARCHAR(50);
BEGIN
    SELECT branch_id INTO v_branch_id FROM public.orders WHERE id = p_order_id;
    SELECT de.branch_id, de.user_id, COALESCE(de.phone, p.phone), p.vehicle_type
    INTO v_emp_branch_id, v_user_id, v_phone, v_vehicle_type
    FROM public.delivery_employees de
    LEFT JOIN public.profiles p ON p.id = de.user_id
    WHERE de.id = p_employee_id;

    IF v_emp_branch_id IS DISTINCT FROM v_branch_id THEN
        RAISE EXCEPTION 'Employee belongs to a different branch';
    END IF;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Employee has no linked user account';
    END IF;

    INSERT INTO public.drivers (id, branch_id, is_active, phone, vehicle_type, current_status)
    VALUES (v_user_id, v_branch_id, true, v_phone, v_vehicle_type, 'مشغول')
    ON CONFLICT (id) DO UPDATE SET
        branch_id = EXCLUDED.branch_id,
        is_active = true,
        phone = COALESCE(EXCLUDED.phone, drivers.phone),
        vehicle_type = COALESCE(EXCLUDED.vehicle_type, drivers.vehicle_type),
        current_status = 'مشغول',
        updated_at = now();

    UPDATE public.orders
    SET assigned_delivery_id = p_employee_id,
        driver_id = v_user_id,
        status = 'assigned',
        assigned_at = now()
    WHERE id = p_order_id;
END;
$$;

-- ── 7. Report views for the Admin Dashboard ──
-- Delivered orders (joined with employee + branch + earnings)
CREATE OR REPLACE VIEW public.delivered_orders_report
WITH (security_invoker = true) AS
SELECT
    o.id,
    upper(substr(o.id::text, 1, 8)) AS order_number,
    o.customer_name_manual,
    o.customer_phone,
    o.delivery_address,
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

-- Delivery employee report
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
    de.branch_id,
    b.name AS branch_name,
    de.status AS online_status,
    de.is_active,
    de.joined_at,
    de.total_deliveries,
    COALESCE(w.balance, 0) AS wallet_balance
FROM public.delivery_employees de
LEFT JOIN public.profiles p ON p.id = de.user_id
LEFT JOIN public.branches b ON b.id = de.branch_id
LEFT JOIN public.driver_wallets w ON w.driver_id = de.user_id;

-- ── 8. Customer can view the profile (name + phone) of the driver
--        currently assigned to one of their active orders ──
DROP POLICY IF EXISTS customer_view_assigned_driver_profile ON public.profiles;
CREATE POLICY customer_view_assigned_driver_profile
ON public.profiles
FOR SELECT
TO authenticated, anon
USING (
    id IN (
        SELECT o.driver_id
        FROM public.orders o
        WHERE o.customer_id = auth.uid()
          AND o.status NOT IN ('delivered', 'cancelled', 'returned', 'رفض')
    )
);
