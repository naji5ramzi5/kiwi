-- ============================================================
-- Migration 020: Delivery Earnings + Notification FIXES
--
-- CRITICAL FIX: the live `notify_driver_on_assignment` trigger
-- crashed EVERY order assignment because:
--   1. It calls current_setting('app.settings.supabase_url') /
--      current_setting('app.settings.service_key') which are NOT
--      configured on this project -> raises 42704 on assignment.
--   2. It calls net.http_post but the pg_net extension is NOT
--      installed -> function not found at trigger runtime.
--   3. Its Arabic strings were corrupted (double-encoded UTF-8).
-- Fix: install pg_net, hardcode the (public) edge-function URL,
--      wrap HTTP in exception so notification can never block
--      order lifecycle, and use clean Arabic text.
--
-- Earnings: on status -> 'delivered', record a delivery_earnings
-- row for the assigned employee and credit driver_wallets.balance.
-- Amount = system_settings.delivery_earnings_per_order if set,
-- else order.delivery_fee.
-- ============================================================

-- ── 1. Enable pg_net (needed for net.http_post) ──
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ── 2. Index for branch delivery queries ──
CREATE INDEX IF NOT EXISTS idx_orders_branch_status_created
  ON public.orders (branch_id, status, created_at DESC);

-- ── 3. FIX notify_driver_on_assignment (clean UTF-8 + safe HTTP) ──
CREATE OR REPLACE FUNCTION public.notify_driver_on_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
BEGIN
    IF NEW.status = 'assigned' AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'assigned') THEN
        -- Create in-app notification for the driver
        INSERT INTO public.notifications (user_id, title, body, type, data, order_id)
        SELECT
            de.user_id,
            'طلب جديد',
            'تم إسناد طلب جديد إليك',
            'order_assigned',
            jsonb_build_object('order_id', NEW.id, 'type', 'new_assignment'),
            NEW.id
        FROM public.delivery_employees de
        WHERE de.id = NEW.assigned_delivery_id;

        -- Send FCM push via edge function (best effort - must never
        -- block the order assignment if the HTTP call fails).
        SELECT user_id INTO v_user_id
        FROM public.delivery_employees WHERE id = NEW.assigned_delivery_id;

        IF v_user_id IS NOT NULL THEN
            BEGIN
                PERFORM
                    net.http_post(
                        url := 'https://pftjlvtdzokbzuioqfug.functions.supabase.co/send-notification',
                        headers := jsonb_build_object('Content-Type', 'application/json'),
                        body := jsonb_build_object(
                            'userId', v_user_id,
                            'title', 'طلب جديد',
                            'body', 'تم إسناد طلب جديد إليك',
                            'data', jsonb_build_object('orderId', NEW.id, 'type', 'new_assignment')
                        )
                    );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'notify_driver_on_assignment FCM failed: %', SQLERRM;
            END;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_driver_assignment ON public.orders;
CREATE TRIGGER trg_notify_driver_assignment
    AFTER UPDATE OF status
    ON public.orders
    FOR EACH ROW
    WHEN (NEW.status = 'assigned')
    EXECUTE FUNCTION public.notify_driver_on_assignment();

-- ── 4. FIX notify_drivers_on_new_order (use pg_net, per-branch tokens) ──
CREATE OR REPLACE FUNCTION public.notify_drivers_on_new_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tokens TEXT[];
  v_payload JSONB;
BEGIN
  -- Only online, active delivery drivers of THIS branch (candidates).
  SELECT array_agg(DISTINCT fcm_token) INTO v_tokens
  FROM public.profiles p
  JOIN public.delivery_employees de ON de.user_id = p.id
  WHERE de.branch_id = NEW.branch_id
    AND p.role = 'driver'
    AND p.is_online = true
    AND de.is_active = true
    AND p.fcm_token IS NOT NULL;

  IF v_tokens IS NOT NULL THEN
    v_payload := jsonb_build_object(
      'tokens', v_tokens,
      'title', '📦 طلب جديد في فرعك!',
      'body', 'لديك طلب جديد ينتظر التحضير، يرجى استلامه فوراً.'
    );

    BEGIN
      PERFORM net.http_post(
        url := 'https://pftjlvtdzokbzuioqfug.functions.supabase.co/send-notification',
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := v_payload
      );
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'notify_drivers_on_new_order error: %', SQLERRM;
    END;
  END IF;

  RETURN NEW;
END;
$$;

-- ── 5. Delivery Earnings table ──
CREATE TABLE IF NOT EXISTS public.delivery_earnings (
    id                    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id              UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    delivery_employee_id  UUID REFERENCES public.delivery_employees(id) ON DELETE SET NULL,
    branch_id             UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    amount                DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at            TIMESTAMPTZ DEFAULT now(),
    UNIQUE(order_id)
);

CREATE INDEX IF NOT EXISTS idx_delivery_earnings_employee
  ON public.delivery_earnings(delivery_employee_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_delivery_earnings_branch
  ON public.delivery_earnings(branch_id, created_at DESC);

ALTER TABLE public.delivery_earnings ENABLE ROW LEVEL SECURITY;

-- earnings: admin/staff full access
DROP POLICY IF EXISTS admin_all_delivery_earnings ON public.delivery_earnings;
CREATE POLICY admin_all_delivery_earnings ON public.delivery_earnings
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR public.is_staff())
    WITH CHECK (public.is_admin() OR public.is_staff());

-- earnings: branch managers see their branch
DROP POLICY IF EXISTS branch_delivery_earnings_select ON public.delivery_earnings;
CREATE POLICY branch_delivery_earnings_select ON public.delivery_earnings
    FOR SELECT
    TO authenticated
    USING (
        branch_id = public.get_my_branch_id()
    );

-- earnings: driver sees own earnings
DROP POLICY IF EXISTS driver_own_earnings ON public.delivery_earnings;
CREATE POLICY driver_own_earnings ON public.delivery_earnings
    FOR SELECT
    TO authenticated
    USING (
        delivery_employee_id IN (
            SELECT id FROM public.delivery_employees WHERE user_id = auth.uid()
        )
    );

-- ── 6. Trigger: record earnings on delivered ──
CREATE OR REPLACE FUNCTION public.record_delivery_earning()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_amount DECIMAL(12,2);
  v_employee_user_id UUID;
BEGIN
    IF NEW.status = 'delivered'
       AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'delivered')
       AND NEW.assigned_delivery_id IS NOT NULL THEN

        v_amount := COALESCE(
            NULLIF((SELECT value_decimal FROM public.system_settings WHERE key = 'delivery_earnings_per_order'), 0),
            COALESCE(NEW.delivery_fee, 0)
        );

        INSERT INTO public.delivery_earnings (order_id, delivery_employee_id, branch_id, amount)
        VALUES (NEW.id, NEW.assigned_delivery_id, NEW.branch_id, v_amount)
        ON CONFLICT (order_id) DO UPDATE SET
            delivery_employee_id = EXCLUDED.delivery_employee_id,
            branch_id = EXCLUDED.branch_id,
            amount = EXCLUDED.amount;

        SELECT user_id INTO v_employee_user_id
        FROM public.delivery_employees
        WHERE id = NEW.assigned_delivery_id;

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

DROP TRIGGER IF EXISTS trg_record_delivery_earning ON public.orders;
CREATE TRIGGER trg_record_delivery_earning
    AFTER UPDATE OF status
    ON public.orders
    FOR EACH ROW
    WHEN (NEW.status = 'delivered')
    EXECUTE FUNCTION public.record_delivery_earning();

-- ── 7. Default earnings setting (0/absent => use order.delivery_fee) ──
INSERT INTO public.system_settings (key, value_decimal)
VALUES ('delivery_earnings_per_order', 0)
ON CONFLICT (key) DO NOTHING;

-- ── 8. FIX assign_order_to_delivery: the live version failed with a
-- foreign-key violation (orders.driver_id -> drivers.id) because no
-- drivers row is created for delivery employees. Creating it here so
-- claiming/assignment actually works end-to-end.
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
BEGIN
    -- Get the branch of the order
    SELECT branch_id INTO v_branch_id FROM public.orders WHERE id = p_order_id;
    -- Get the branch of the employee
    SELECT branch_id, user_id INTO v_emp_branch_id, v_user_id
    FROM public.delivery_employees WHERE id = p_employee_id;

    IF v_emp_branch_id IS DISTINCT FROM v_branch_id THEN
        RAISE EXCEPTION 'Employee belongs to a different branch';
    END IF;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Employee has no linked user account';
    END IF;

    -- Ensure a drivers row exists (FK: orders.driver_id -> drivers.id)
    INSERT INTO public.drivers (id, branch_id, is_active)
    VALUES (v_user_id, v_branch_id, true)
    ON CONFLICT (id) DO UPDATE SET
        branch_id = EXCLUDED.branch_id,
        is_active = true;

    UPDATE public.orders
    SET assigned_delivery_id = p_employee_id,
        driver_id = v_user_id,
        status = 'assigned',
        assigned_at = now()
    WHERE id = p_order_id;
END;
$$;
