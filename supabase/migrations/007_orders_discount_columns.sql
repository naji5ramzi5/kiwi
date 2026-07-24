-- Add coupon / discount columns to the orders table (Task 2: Discount Coupons).
-- Safe to re-run: each ALTER guards against an already-existing column.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'orders'
      AND column_name = 'discount_code'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN discount_code TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'orders'
      AND column_name = 'discount_amount'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN discount_amount NUMERIC DEFAULT 0;
  END IF;
END $$;
