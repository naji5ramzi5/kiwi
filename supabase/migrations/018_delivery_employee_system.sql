-- ============================================================================
-- Delivery Employee Management System
-- Migration 018: Tables, triggers, functions, RLS, and sync
-- ============================================================================

-- ── 1. Delivery Employees Table ──
CREATE TABLE IF NOT EXISTS public.delivery_employees (
    id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    branch_id    UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    phone        VARCHAR(20),
    status       VARCHAR(20) DEFAULT 'offline' CHECK (status IN ('online','offline')),
    is_active    BOOLEAN DEFAULT true,
    joined_at    TIMESTAMPTZ DEFAULT now(),
    transferred_at TIMESTAMPTZ,
    total_deliveries INTEGER DEFAULT 0,
    created_at   TIMESTAMPTZ DEFAULT now(),
    updated_at   TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

CREATE INDEX idx_delivery_employees_branch_id ON public.delivery_employees(branch_id);
CREATE INDEX idx_delivery_employees_user_id ON public.delivery_employees(user_id);
CREATE INDEX idx_delivery_employees_status ON public.delivery_employees(status);

ALTER TABLE public.delivery_employees ENABLE ROW LEVEL SECURITY;

-- ── 2. Delivery Transfer History ──
CREATE TABLE IF NOT EXISTS public.delivery_transfer_history (
    id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    delivery_employee_id UUID NOT NULL REFERENCES public.delivery_employees(id) ON DELETE CASCADE,
    old_branch_id        UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    new_branch_id        UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    transferred_by       UUID REFERENCES auth.users(id),
    reason               TEXT,
    transferred_at       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_transfer_history_employee ON public.delivery_transfer_history(delivery_employee_id);
CREATE INDEX idx_transfer_history_new_branch ON public.delivery_transfer_history(new_branch_id);

ALTER TABLE public.delivery_transfer_history ENABLE ROW LEVEL SECURITY;

-- ── 3. Orders – new columns ──
ALTER TABLE public.orders
    ADD COLUMN IF NOT EXISTS assigned_delivery_id UUID REFERENCES public.delivery_employees(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS assigned_at           TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS picked_up_at          TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS on_the_way_at         TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS delivered_at          TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_orders_assigned_delivery ON public.orders(assigned_delivery_id);

-- ── 4. Branches – delivery_employees_count ──
ALTER TABLE public.branches
    ADD COLUMN IF NOT EXISTS delivery_employees_count INTEGER DEFAULT 0;

-- ── 5. Trigger: auto-sync profiles → delivery_employees ──
CREATE OR REPLACE FUNCTION public.sync_delivery_employee()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.role = 'driver' AND NEW.is_approved = true THEN
        INSERT INTO public.delivery_employees (user_id, phone, status, is_active)
        VALUES (NEW.id, NEW.phone, COALESCE(NEW.is_online::text, 'offline'), true)
        ON CONFLICT (user_id)
        DO UPDATE SET
            phone      = EXCLUDED.phone,
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

DROP TRIGGER IF EXISTS trg_sync_delivery_employee ON public.profiles;
CREATE TRIGGER trg_sync_delivery_employee
    AFTER INSERT OR UPDATE OF role, is_approved, is_online, phone
    ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_delivery_employee();

-- Sync existing approved drivers
INSERT INTO public.delivery_employees (user_id, phone, status, is_active, joined_at, total_deliveries)
SELECT
    p.id,
    p.phone,
    CASE WHEN p.is_online THEN 'online' ELSE 'offline' END,
    true,
    COALESCE(p.created_at, now()),
    COALESCE((SELECT COUNT(*) FROM public.orders o WHERE o.driver_id = p.id AND o.status = 'delivered'), 0)
FROM public.profiles p
WHERE p.role = 'driver' AND p.is_approved = true
ON CONFLICT (user_id) DO NOTHING;

-- ── 6. Trigger: count employees per branch ──
CREATE OR REPLACE FUNCTION public.update_branch_employee_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE public.branches
        SET delivery_employees_count = (
            SELECT COUNT(*) FROM public.delivery_employees
            WHERE branch_id = NEW.branch_id AND is_active = true
        )
        WHERE id = NEW.branch_id;
        -- also recount old branch on update
        IF TG_OP = 'UPDATE' AND OLD.branch_id IS DISTINCT FROM NEW.branch_id AND OLD.branch_id IS NOT NULL THEN
            UPDATE public.branches
            SET delivery_employees_count = (
                SELECT COUNT(*) FROM public.delivery_employees
                WHERE branch_id = OLD.branch_id AND is_active = true
            )
            WHERE id = OLD.branch_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.branch_id IS NOT NULL THEN
            UPDATE public.branches
            SET delivery_employees_count = (
                SELECT COUNT(*) FROM public.delivery_employees
                WHERE branch_id = OLD.branch_id AND is_active = true
            )
            WHERE id = OLD.branch_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_update_branch_employee_count ON public.delivery_employees;
CREATE TRIGGER trg_update_branch_employee_count
    AFTER INSERT OR UPDATE OR DELETE
    ON public.delivery_employees
    FOR EACH ROW
    EXECUTE FUNCTION public.update_branch_employee_count();

-- ── 7. Trigger: update transferred_at on branch change ──
CREATE OR REPLACE FUNCTION public.on_delivery_employee_transfer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF OLD.branch_id IS DISTINCT FROM NEW.branch_id THEN
        NEW.transferred_at = now();
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_delivery_employee_transfer ON public.delivery_employees;
CREATE TRIGGER trg_delivery_employee_transfer
    BEFORE UPDATE OF branch_id
    ON public.delivery_employees
    FOR EACH ROW
    EXECUTE FUNCTION public.on_delivery_employee_transfer();

-- ── 8. Trigger: update delivered_at & total_deliveries ──
CREATE OR REPLACE FUNCTION public.on_order_delivered()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.status = 'delivered' AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'delivered') THEN
        NEW.delivered_at = now();
        IF NEW.assigned_delivery_id IS NOT NULL THEN
            UPDATE public.delivery_employees
            SET total_deliveries = total_deliveries + 1,
                updated_at = now()
            WHERE id = NEW.assigned_delivery_id;
        END IF;
    END IF;
    IF NEW.status = 'picked_up' AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'picked_up') THEN
        NEW.picked_up_at = now();
    END IF;
    IF NEW.status = 'shipped' AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'shipped') THEN
        NEW.on_the_way_at = now();
    END IF;
    IF NEW.status = 'assigned' AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'assigned') THEN
        NEW.assigned_at = now();
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_order_delivery_timestamps ON public.orders;
CREATE TRIGGER trg_order_delivery_timestamps
    BEFORE UPDATE OF status
    ON public.orders
    FOR EACH ROW
    WHEN (NEW.status IS DISTINCT FROM OLD.status)
    EXECUTE FUNCTION public.on_order_delivered();

-- ── 9. Helper functions ──

-- Get delivery employees for a branch
CREATE OR REPLACE FUNCTION public.get_branch_delivery_employees(p_branch_id UUID)
RETURNS SETOF public.delivery_employees
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT * FROM public.delivery_employees
    WHERE branch_id = p_branch_id AND is_active = true
    ORDER BY created_at DESC;
$$;

-- Transfer a delivery employee
CREATE OR REPLACE FUNCTION public.transfer_delivery_employee(
    p_employee_id UUID,
    p_new_branch_id UUID,
    p_transferred_by UUID DEFAULT auth.uid(),
    p_reason TEXT DEFAULT ''
)
RETURNS public.delivery_employees
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_old_branch_id UUID;
    v_employee public.delivery_employees;
BEGIN
    SELECT branch_id INTO v_old_branch_id
    FROM public.delivery_employees
    WHERE id = p_employee_id;

    IF v_old_branch_id IS NULL THEN
        RAISE EXCEPTION 'Employee not found';
    END IF;

    -- Record transfer history
    INSERT INTO public.delivery_transfer_history
        (delivery_employee_id, old_branch_id, new_branch_id, transferred_by, reason)
    VALUES
        (p_employee_id, v_old_branch_id, p_new_branch_id, p_transferred_by, p_reason);

    -- Update employee branch
    UPDATE public.delivery_employees
    SET branch_id = p_new_branch_id,
        transferred_at = now(),
        updated_at = now()
    WHERE id = p_employee_id
    RETURNING * INTO v_employee;

    -- Update profile branch_id for backward compat
    UPDATE public.profiles
    SET branch_id = p_new_branch_id
    WHERE id = (SELECT user_id FROM public.delivery_employees WHERE id = p_employee_id);

    RETURN v_employee;
END;
$$;

-- Assign order to delivery employee
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
BEGIN
    -- Get the branch of the order
    SELECT branch_id INTO v_branch_id FROM public.orders WHERE id = p_order_id;
    -- Get the branch of the employee
    SELECT branch_id INTO v_emp_branch_id FROM public.delivery_employees WHERE id = p_employee_id;

    IF v_emp_branch_id IS DISTINCT FROM v_branch_id THEN
        RAISE EXCEPTION 'Employee belongs to a different branch';
    END IF;

    UPDATE public.orders
    SET assigned_delivery_id = p_employee_id,
        driver_id = (SELECT user_id FROM public.delivery_employees WHERE id = p_employee_id),
        status = 'assigned',
        assigned_at = now()
    WHERE id = p_order_id;
END;
$$;

-- Reject/release order from delivery
CREATE OR REPLACE FUNCTION public.release_order_from_delivery(p_order_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.orders
    SET assigned_delivery_id = NULL,
        driver_id = NULL,
        status = 'ready',
        assigned_at = NULL
    WHERE id = p_order_id AND status = 'assigned';
END;
$$;

-- Accept assigned order
CREATE OR REPLACE FUNCTION public.accept_delivery_order(p_order_id UUID, p_employee_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.orders
    SET status = 'picked_up',
        picked_up_at = now()
    WHERE id = p_order_id
      AND assigned_delivery_id = p_employee_id
      AND status = 'assigned';
END;
$$;

-- ── 10. RLS Policies ──

-- delivery_employees: admin full access
DROP POLICY IF EXISTS admin_all_delivery_employees ON public.delivery_employees;
CREATE POLICY admin_all_delivery_employees ON public.delivery_employees
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR public.is_staff())
    WITH CHECK (public.is_admin() OR public.is_staff());

-- delivery_employees: branch managers see only their branch
DROP POLICY IF EXISTS branch_delivery_employees_select ON public.delivery_employees;
CREATE POLICY branch_delivery_employees_select ON public.delivery_employees
    FOR SELECT
    TO authenticated
    USING (
        branch_id = public.get_my_branch_id()
        OR
        user_id = auth.uid()
    );

-- delivery_employees: employees see only themselves
DROP POLICY IF EXISTS employee_self ON public.delivery_employees;
CREATE POLICY employee_self ON public.delivery_employees
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- delivery_employees: employee update own status
DROP POLICY IF EXISTS employee_update_own ON public.delivery_employees;
CREATE POLICY employee_update_own ON public.delivery_employees
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- delivery_transfer_history: admin full access
DROP POLICY IF EXISTS admin_all_transfer_history ON public.delivery_transfer_history;
CREATE POLICY admin_all_transfer_history ON public.delivery_transfer_history
    FOR ALL
    TO authenticated
    USING (public.is_admin() OR public.is_staff())
    WITH CHECK (public.is_admin() OR public.is_staff());

-- delivery_transfer_history: branch managers see transfers involving their branch
DROP POLICY IF EXISTS branch_transfer_history_select ON public.delivery_transfer_history;
CREATE POLICY branch_transfer_history_select ON public.delivery_transfer_history
    FOR SELECT
    TO authenticated
    USING (
        old_branch_id = public.get_my_branch_id()
        OR
        new_branch_id = public.get_my_branch_id()
    );

-- ── 11. Add to realtime publication ──
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_employees;
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_transfer_history;

-- ── 12. Add 'assigned' and 'ready' status to notify trigger ──
CREATE OR REPLACE FUNCTION public.notify_driver_on_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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

        -- Send FCM push via edge function
        PERFORM
            net.http_post(
                url := current_setting('app.settings.supabase_url') || '/functions/v1/send-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.settings.service_key')
                ),
                body := jsonb_build_object(
                    'userId', (SELECT user_id FROM public.delivery_employees WHERE id = NEW.assigned_delivery_id),
                    'title', 'طلب جديد',
                    'body', 'تم إسناد طلب جديد إليك',
                    'data', jsonb_build_object('orderId', NEW.id, 'type', 'new_assignment')
                )
            );
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
