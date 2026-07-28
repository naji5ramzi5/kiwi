-- =============================================================
-- Fix branch_inventory: add stock_quantity column (backward compat)
-- The app uses both 'actual_stock' and 'stock_quantity'
-- =============================================================

-- 1. Add stock_quantity as an alias column
ALTER TABLE branch_inventory
ADD COLUMN IF NOT EXISTS stock_quantity DOUBLE PRECISION
GENERATED ALWAYS AS (actual_stock) STORED;

-- 2. Create statistics RPC for the dashboard
CREATE OR REPLACE FUNCTION get_branch_statistics(
  p_branch_id UUID,
  p_period TEXT DEFAULT 'today'
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_start TIMESTAMPTZ;
  v_end TIMESTAMPTZ := NOW();
  v_result JSONB;
BEGIN
  -- Determine time range
  v_start := CASE p_period
    WHEN 'today' THEN DATE_TRUNC('day', v_end)
    WHEN 'week' THEN DATE_TRUNC('week', v_end)
    WHEN 'month' THEN DATE_TRUNC('month', v_end)
    ELSE DATE_TRUNC('day', v_end)
  END;

  SELECT JSONB_BUILD_OBJECT(
    'total_sales', COALESCE(SUM(o.total_amount), 0),
    'orders_count', COUNT(o.id),
    'avg_order_value', COALESCE(AVG(o.total_amount), 0),
    'total_purchases', COALESCE((SELECT SUM(p.total_amount) FROM purchases p WHERE p.branch_id = p_branch_id AND p.created_at >= v_start), 0),
    'total_stock_value', COALESCE((SELECT SUM(bi.actual_stock * COALESCE((SELECT pr.default_price FROM products pr WHERE pr.id = bi.product_id), 0)) FROM branch_inventory bi WHERE bi.branch_id = p_branch_id), 0)
  ) INTO v_result
  FROM orders o
  WHERE o.branch_id = p_branch_id
    AND o.status = 'delivered'
    AND o.created_at >= v_start;

  RETURN v_result;
END;
$$;

-- 3. Create top_products RPC for statistics chart
CREATE OR REPLACE FUNCTION get_top_products(
  p_branch_id UUID,
  p_limit INT DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT JSONB_AGG(row_to_json(t))
  INTO v_result
  FROM (
    SELECT
      p.name,
      SUM(oi.quantity) AS total_quantity,
      SUM(oi.total_price) AS total_revenue,
      COUNT(DISTINCT oi.order_id) AS order_count
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    JOIN products p ON p.id = oi.product_id
    WHERE o.branch_id = p_branch_id
      AND o.status = 'delivered'
    GROUP BY p.name
    ORDER BY total_quantity DESC
    LIMIT p_limit
  ) t;

  RETURN COALESCE(v_result, '[]'::JSONB);
END;
$$;
