CREATE OR REPLACE FUNCTION get_branch_daily_stats(p_branch_id UUID)
RETURNS JSON AS $$
  SELECT json_build_object(
    'total_sales', COALESCE((
      SELECT SUM(total_amount) FROM orders
      WHERE branch_id = p_branch_id
        AND status = 'delivered'
        AND created_at >= date_trunc('day', now())
    ), 0),
    'orders_count', COALESCE((
      SELECT COUNT(*) FROM orders
      WHERE branch_id = p_branch_id
        AND status = 'delivered'
        AND created_at >= date_trunc('day', now())
    ), 0),
    'total_purchases', COALESCE((
      SELECT SUM(total_amount) FROM purchases
      WHERE branch_id = p_branch_id
        AND created_at >= date_trunc('day', now())
    ), 0),
    'total_damaged', 0
  );
$$ LANGUAGE sql STABLE;
