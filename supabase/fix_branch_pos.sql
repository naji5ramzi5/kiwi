-- ============================================================
-- fix_branch_pos.sql — حل شامل لمشاكل RLS في تطبيق الفروع
-- شغّل هذا الملف كامل في Supabase SQL Editor
-- ============================================================

-- ─── 1. دوال المساعدة ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE SQL STABLE
AS $$
  SELECT COALESCE(
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()),
    'customer'
  );
$$;

CREATE OR REPLACE FUNCTION public.get_my_branch_id()
RETURNS UUID
LANGUAGE SQL STABLE
AS $$
  SELECT COALESCE(
    (SELECT (raw_user_meta_data->>'branch_id')::UUID FROM auth.users WHERE id = auth.uid()),
    NULL
  );
$$;

-- ─── 2. تفعيل RLS على كل الجداول ────────────────────────────
ALTER TABLE IF EXISTS public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.purchase_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.stock_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.damaged_goods ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.waste_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.daily_settlements ENABLE ROW LEVEL SECURITY;

-- ─── 3. حذف كل السياسات القديمة ─────────────────────────────
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN (
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public' AND tablename IN (
      'inventory','orders','order_items','invoices','purchases',
      'purchase_items','stock_entries','damaged_goods','waste_records',
      'products','branches','drivers','daily_settlements'
    )
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

-- ─── 4. سياسات: المستخدم المصادق يفعل كل شيء ───────────────
-- (لأن تطبيق الفروع يستخدم auth.role() = 'authenticated')

CREATE POLICY "auth_all_inventory" ON public.inventory
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_orders" ON public.orders
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_order_items" ON public.order_items
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_invoices" ON public.invoices
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_purchases" ON public.purchases
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_purchase_items" ON public.purchase_items
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_stock_entries" ON public.stock_entries
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_damaged_goods" ON public.damaged_goods
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_waste_records" ON public.waste_records
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_products" ON public.products
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_branches" ON public.branches
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_drivers" ON public.drivers
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_all_daily_settlements" ON public.daily_settlements
  FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- ─── 5. أعمدة ناقصة في جداول الطلبات ────────────────────────
ALTER TABLE IF EXISTS public.order_items
  ADD COLUMN IF NOT EXISTS product_name TEXT,
  ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ─── 6. السماح للعامة بقراءة المنتجات والفروع (لشاشة الدخول) ─
DROP POLICY IF EXISTS "public_read_products" ON public.products;
CREATE POLICY "public_read_products" ON public.products
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_branches" ON public.branches;
CREATE POLICY "public_read_branches" ON public.branches
  FOR SELECT USING (true);
