-- ============================================================
-- Migration 006: Order Status History (Audit Trail)
-- ============================================================
-- Creates the order_status_history table and a trigger that
-- logs every status change on the orders table automatically.
-- Also provides an RPC to safely decrement branch inventory
-- stock when an order is placed, and to increment it back when
-- an order is cancelled (restock).
-- ============================================================

-- ─── 1. order_status_history table ──────────────────────────
CREATE TABLE IF NOT EXISTS public.order_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  old_status TEXT,
  new_status TEXT,
  changed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  changed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id
  ON public.order_status_history(order_id);

ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated read order_status_history"
  ON public.order_status_history;
CREATE POLICY "Authenticated read order_status_history"
  ON public.order_status_history FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated write order_status_history"
  ON public.order_status_history;
CREATE POLICY "Authenticated write order_status_history"
  ON public.order_status_history FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- ─── 2. Trigger to log every status change ──────────────────
CREATE OR REPLACE FUNCTION public.log_order_status_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  -- Only log when the status actually changed
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.order_status_history (order_id, old_status, new_status, changed_by, changed_at)
  VALUES (NEW.id, OLD.status, NEW.status, auth.uid(), now());

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_order_status_change ON public.orders;

CREATE TRIGGER trg_log_order_status_change
  AFTER UPDATE OF status
  ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.log_order_status_change();

-- ─── 3. RPC: decrement branch inventory stock ───────────────
CREATE OR REPLACE FUNCTION public.decrement_branch_inventory(
  p_branch_id UUID,
  p_product_id UUID,
  p_quantity INT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  UPDATE public.branch_inventory
  SET actual_stock = GREATEST(0, COALESCE(actual_stock, 0) - p_quantity)
  WHERE branch_id = p_branch_id
    AND product_id = p_product_id;
END;
$$;

-- ─── 4. RPC: increment (restock) branch inventory stock ─────
CREATE OR REPLACE FUNCTION public.increment_branch_inventory(
  p_branch_id UUID,
  p_product_id UUID,
  p_quantity INT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  UPDATE public.branch_inventory
  SET actual_stock = COALESCE(actual_stock, 0) + p_quantity
  WHERE branch_id = p_branch_id
    AND product_id = p_product_id;
END;
$$;
