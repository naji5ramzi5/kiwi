-- ============================================================
-- naji2.sql — التعديلات النهائية لقاعدة بيانات Kiwi
-- تاريخ: 26 يونيو 2026
-- ============================================================
-- هذا الملف يجمع كل التعديلات المطلوبة:
-- 1. أعمدة جديدة لجداول الطلبات والمنتجات
-- 2. جداول جديدة: العناوين، سجل الحالة، الدردشة، الفواتير، إدخال المخزون
-- 3. سياسات RLS لجميع الجداول
-- 4. دوال مساعدة للأدوار والفروع
-- 5. السماح للعامة بقراءة المنتجات والفروع
-- ============================================================

-- ─── 1. دوال المساعدة للأدوار والفروع ──────────────────────
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

-- ─── 2. تحديث جدول الطلبات (orders) ─────────────────────────
ALTER TABLE IF EXISTS public.orders
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
  ADD COLUMN IF NOT EXISTS status_history JSONB DEFAULT '[]'::jsonb;

UPDATE public.orders SET status = 'pending' WHERE status = 'قيد الانتظار';

-- ─── 3. تحديث جدول تفاصيل الطلبات (order_items) ─────────────
ALTER TABLE IF EXISTS public.order_items
  ADD COLUMN IF NOT EXISTS product_name TEXT,
  ADD COLUMN IF NOT EXISTS image_url TEXT;

UPDATE public.order_items oi
SET product_name = p.name, image_url = p.image_url
FROM public.products p
WHERE oi.product_id = p.id::text::uuid
  AND (oi.product_name IS NULL OR oi.product_name = '');

-- ─── 4. تحديث جدول الملفات الشخصية (profiles) ───────────────
ALTER TABLE IF EXISTS public.profiles
  ADD COLUMN IF NOT EXISTS name_change_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS phone_changed BOOLEAN DEFAULT FALSE;

-- ─── 5. إنشاء جدول العناوين المحفوظة (addresses) ────────────
CREATE TABLE IF NOT EXISTS public.addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  label TEXT NOT NULL DEFAULT 'منزل',
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 6. إنشاء جدول سجل حالة الطلب (order_status_history) ─────
CREATE TABLE IF NOT EXISTS public.order_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL,
  note TEXT,
  changed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 7. إنشاء جدول الدردشة الداخلية (order_chat) ────────────
CREATE TABLE IF NOT EXISTS public.order_chat (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  sender_role TEXT NOT NULL DEFAULT 'customer',
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 8. إنشاء جدول الفواتير (invoices) ──────────────────────
CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id TEXT,
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  branch_name TEXT,
  items JSONB DEFAULT '[]'::jsonb,
  subtotal DECIMAL(12,2) DEFAULT 0,
  discount DECIMAL(12,2) DEFAULT 0,
  total DECIMAL(12,2) NOT NULL,
  payment_method TEXT DEFAULT 'نقداً',
  customer_name TEXT,
  cashier_name TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 9. إنشاء جدول إدخال المخزون (stock_entries) ────────────
CREATE TABLE IF NOT EXISTS public.stock_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  quantity DECIMAL(10,2) NOT NULL,
  unit_cost DECIMAL(12,2) DEFAULT 0,
  total_cost DECIMAL(12,2) DEFAULT 0,
  entered_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 10. تفعيل Row Level Security ───────────────────────────
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
ALTER TABLE IF EXISTS public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.order_chat ENABLE ROW LEVEL SECURITY;

-- ─── 11. حذف جميع السياسات القديمة ──────────────────────────
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN (
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public' AND tablename IN (
      'inventory','orders','order_items','invoices','purchases',
      'purchase_items','stock_entries','damaged_goods','waste_records',
      'products','branches','drivers','daily_settlements',
      'addresses','order_status_history','order_chat'
    )
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

-- ─── 12. سياسات RLS: المستخدم المصادق يفعل كل شيء ──────────
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

-- ─── 13. سياسات RLS للجداول الجديدة ─────────────────────────
CREATE POLICY "Users can manage their own addresses"
  ON public.addresses
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their order history"
  ON public.order_status_history
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_status_history.order_id
      AND orders.customer_id = auth.uid()
  ));

CREATE POLICY "Users can view their order chat"
  ON public.order_chat
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_chat.order_id
      AND orders.customer_id = auth.uid()
  ));

CREATE POLICY "Users can send messages to their orders"
  ON public.order_chat
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_chat.order_id
        AND orders.customer_id = auth.uid()
    )
    AND auth.uid() = sender_id
    AND sender_role = 'customer'
  );

-- ─── 14. السماح للعامة بقراءة المنتجات والفروع ──────────────
DROP POLICY IF EXISTS "public_read_products" ON public.products;
CREATE POLICY "public_read_products" ON public.products
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "public_read_branches" ON public.branches;
CREATE POLICY "public_read_branches" ON public.branches
  FOR SELECT USING (true);
