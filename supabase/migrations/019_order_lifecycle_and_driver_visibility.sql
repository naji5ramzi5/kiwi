-- ============================================================
-- Migration 019: Order Lifecycle (manual progression) +
-- Driver Zone Visibility
--
-- 1. Orders always start as 'pending' (new). Nothing auto-jumps
--    to 'preparing'. Progression is manual from the Branch POS:
--      pending  -> preparing -> prepared -> shipped -> delivered
-- 2. Drivers can now READ (and therefore see in-app) new orders
--    that belong to their branch zone, so the order card renders
--    the moment the FCM notification arrives — even before the
--    branch assigns it to a specific driver.
-- ============================================================

-- ── 1. Helper: driver's own branch ──
CREATE OR REPLACE FUNCTION public.get_driver_branch_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT branch_id
  FROM public.delivery_employees
  WHERE user_id = auth.uid()
  LIMIT 1;
$$;

-- ── 2. RLS: drivers may read new orders in their zone ──
-- Drivers can still read/update orders assigned to them, and they
-- can additionally READ (view-only) unassigned new orders that
-- belong to their branch so the card shows immediately.
DROP POLICY IF EXISTS "driver_orders_select" ON public.orders;
CREATE POLICY "driver_orders_select"
  ON public.orders
  FOR SELECT
  TO authenticated
  USING (
    driver_id = auth.uid()
    OR (
      branch_id = public.get_driver_branch_id()
      AND status IN ('pending', 'preparing', 'prepared', 'ready')
    )
  );

-- ── 3. Branch managers: keep full access (idempotent) ──
DROP POLICY IF EXISTS "branch_orders_all" ON public.orders;
CREATE POLICY "branch_orders_all"
  ON public.orders
  FOR ALL
  TO authenticated
  USING (
    public.get_my_role() = 'branch_manager'
    AND branch_id = public.get_my_branch_id()
  )
  WITH CHECK (
    public.get_my_role() = 'branch_manager'
    AND branch_id = public.get_my_branch_id()
  );

-- ── 4. Ensure orders table is in the realtime publication ──
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  END IF;
END;
$$;

-- ── 5. Notify driver again when order moves to 'prepared' ──
-- (kept simple: the existing trg_notify_driver_assignment fires on
--  'assigned'; here we only log 'prepared' into notifications)
CREATE OR REPLACE FUNCTION public.notify_prepared_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status = 'prepared'
     AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'prepared')
     AND NEW.assigned_delivery_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, data, order_id)
    SELECT
      de.user_id,
      'طلبك جاهز',
      'الطلب أصبح جاهزاً للتوصيل',
      'order_prepared',
      jsonb_build_object('order_id', NEW.id, 'type', 'order_prepared'),
      NEW.id
    FROM public.delivery_employees de
    WHERE de.id = NEW.assigned_delivery_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_prepared ON public.orders;
CREATE TRIGGER trg_notify_prepared
  AFTER UPDATE OF status
  ON public.orders
  FOR EACH ROW
  WHEN (NEW.status = 'prepared')
  EXECUTE FUNCTION public.notify_prepared_status();
