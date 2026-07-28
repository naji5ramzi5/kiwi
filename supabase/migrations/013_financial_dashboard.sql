-- 013: Financial Dashboard - RPCs & Driver Wallets
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor)

-- 1. Driver wallets table
CREATE TABLE IF NOT EXISTS driver_wallets (
  driver_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  last_payout_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create wallet for new drivers
CREATE OR REPLACE FUNCTION auto_create_driver_wallet()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'driver' THEN
    INSERT INTO driver_wallets (driver_id, balance)
    VALUES (NEW.id, 0.00)
    ON CONFLICT (driver_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_auto_create_driver_wallet ON profiles;
CREATE TRIGGER trg_auto_create_driver_wallet
AFTER INSERT ON profiles
FOR EACH ROW
EXECUTE FUNCTION auto_create_driver_wallet();

-- Create wallets for existing drivers
INSERT INTO driver_wallets (driver_id, balance)
SELECT id, 0.00 FROM profiles WHERE role = 'driver'
ON CONFLICT (driver_id) DO NOTHING;

-- 2. Financial summary RPC
CREATE OR REPLACE FUNCTION get_financial_summary(
  period_type TEXT DEFAULT 'daily',
  from_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  to_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
  date_trunc_field TEXT;
BEGIN
  date_trunc_field := CASE period_type
    WHEN 'daily' THEN 'day'
    WHEN 'weekly' THEN 'week'
    WHEN 'monthly' THEN 'month'
    ELSE 'day'
  END;

  WITH period_sales AS (
    SELECT
      DATE_TRUNC(date_trunc_field, o.created_at::DATE) AS period_start,
      COUNT(DISTINCT o.id) AS order_count,
      COALESCE(SUM(o.total_amount), 0) AS total_revenue,
      COALESCE(SUM(o.delivery_fee), 0) AS total_delivery_fees,
      COALESCE(AVG(o.total_amount), 0) AS avg_order_value
    FROM orders o
    WHERE o.status IN ('delivered', 'completed')
      AND o.created_at::DATE >= from_date
      AND o.created_at::DATE <= to_date
    GROUP BY period_start
    ORDER BY period_start DESC
  ),
  branch_metrics AS (
    SELECT
      b.id AS branch_id,
      b.name AS branch_name,
      COUNT(DISTINCT o.id) AS order_count,
      COALESCE(SUM(o.total_amount), 0) AS branch_revenue
    FROM branches b
    LEFT JOIN orders o ON o.branch_id = b.id
      AND o.status IN ('delivered', 'completed')
      AND o.created_at::DATE >= from_date
      AND o.created_at::DATE <= to_date
    GROUP BY b.id, b.name
    ORDER BY branch_revenue DESC
  ),
  totals AS (
    SELECT
      COALESCE(SUM(total_revenue), 0) AS total_revenue,
      COALESCE(SUM(order_count), 0) AS total_orders
    FROM period_sales
  )
  SELECT jsonb_build_object(
    'period_type', period_type,
    'from_date', from_date::TEXT,
    'to_date', to_date::TEXT,
    'sales_by_period', COALESCE(jsonb_agg(
      jsonb_build_object(
        'period', period_start::TEXT,
        'orders', order_count,
        'revenue', total_revenue,
        'delivery_fees', total_delivery_fees,
        'avg_order', ROUND(avg_order_value::NUMERIC, 2)
      ) ORDER BY period_start DESC
    ), '[]'::jsonb),
    'branch_metrics', COALESCE(jsonb_agg(
      jsonb_build_object(
        'branch_id', branch_id,
        'branch_name', branch_name,
        'orders', order_count,
        'revenue', branch_revenue
      ) ORDER BY branch_revenue DESC
    ), '[]'::jsonb),
    'totals', jsonb_build_object(
      'total_revenue', (SELECT total_revenue FROM totals),
      'total_orders', (SELECT total_orders FROM totals)
    )
  ) INTO result
  FROM period_sales, branch_metrics;

  RETURN COALESCE(result, '{}'::jsonb);
END;
$$;

-- 3. RPC: Record salary payout (clears driver wallet + logs expense)
CREATE OR REPLACE FUNCTION record_driver_salary_payout(
  p_driver_id UUID,
  p_amount DECIMAL,
  p_note TEXT DEFAULT 'راتب شهري'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_balance DECIMAL;
  v_result JSONB;
BEGIN
  SELECT balance INTO v_balance
  FROM driver_wallets
  WHERE driver_id = p_driver_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'المندوب غير موجود');
  END IF;

  UPDATE driver_wallets
  SET balance = 0,
      last_payout_date = NOW(),
      updated_at = NOW()
  WHERE driver_id = p_driver_id;

  INSERT INTO system_expenses (description, amount, category, driver_id, created_at)
  VALUES (p_note, p_amount, 'driver_salary', p_driver_id, NOW());

  RETURN jsonb_build_object(
    'success', true,
    'driver_id', p_driver_id,
    'amount', p_amount,
    'previous_balance', v_balance
  );
END;
$$;

-- 4. System expenses table (for salary logging)
CREATE TABLE IF NOT EXISTS system_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  description TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  category TEXT NOT NULL DEFAULT 'other',
  driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Ensure system_settings has defaults
INSERT INTO system_settings (key, value_decimal)
VALUES
  ('dev_partner_ratio', 0.35),
  ('owner_partner_ratio', 0.55),
  ('system_maintenance_ratio', 0.10)
ON CONFLICT (key) DO NOTHING;
