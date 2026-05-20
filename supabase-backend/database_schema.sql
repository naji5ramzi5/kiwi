-- ==========================================
-- FRESH ENTERPRISE SYSTEM - SUPABASE SCHEMA
-- Version 2.0 - مع سياسات RLS الكاملة
-- ==========================================

-- 1. الفروع (Branches)
CREATE TABLE IF NOT EXISTS public.branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  address TEXT NOT NULL,
  city VARCHAR(100) DEFAULT 'بغداد',
  phone VARCHAR(20),
  status VARCHAR(20) DEFAULT 'نشط', -- نشط، موقوف، مؤقت
  activation_code VARCHAR(10) UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. المستخدمين والصلاحيات (Profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL DEFAULT 'customer', -- super_admin, branch_manager, driver, customer
  full_name VARCHAR(255),
  phone VARCHAR(20) UNIQUE,
  branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. المنتجات - الكتالوج المركزي (Products)
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  category VARCHAR(100) NOT NULL,
  unit VARCHAR(50) NOT NULL,
  price DECIMAL(12, 2) NOT NULL,
  cost DECIMAL(12, 2),
  is_active BOOLEAN DEFAULT true,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. مخزون الفروع (Inventory)
CREATE TABLE IF NOT EXISTS public.inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  stock_quantity DECIMAL(10, 2) DEFAULT 0,
  min_stock_level DECIMAL(10, 2) DEFAULT 10,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(branch_id, product_id)
);

-- 5. المشتريات والتوريد (Purchases)
CREATE TABLE IF NOT EXISTS public.purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  supplier_name VARCHAR(255) NOT NULL,
  total_value DECIMAL(12, 2) NOT NULL,
  payment_status VARCHAR(50) DEFAULT 'مدفوع', -- مدفوع، آجل
  invoice_number VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5.1 تفاصيل المشتريات (Purchase Items)
CREATE TABLE IF NOT EXISTS public.purchase_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id UUID REFERENCES public.purchases(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  quantity DECIMAL(10, 2) NOT NULL,
  unit_cost DECIMAL(12, 2) NOT NULL,
  total_cost DECIMAL(12, 2) NOT NULL
);

-- 6. التوالف والمرتجع (Damaged & Returns)
CREATE TABLE IF NOT EXISTS public.damaged_goods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  quantity DECIMAL(10, 2) NOT NULL,
  loss_value DECIMAL(12, 2) NOT NULL,
  reason TEXT,
  type VARCHAR(50) DEFAULT 'damaged', -- damaged, return
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6.1 التسوية اليومية (Daily Settlements)
CREATE TABLE IF NOT EXISTS public.daily_settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  total_sales DECIMAL(12, 2) NOT NULL,
  total_purchases DECIMAL(12, 2) NOT NULL,
  total_damaged DECIMAL(12, 2) NOT NULL,
  cash_on_hand DECIMAL(12, 2) NOT NULL,
  status VARCHAR(50) DEFAULT 'open', -- open, closed
  closed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. المناديب (Drivers)
CREATE TABLE IF NOT EXISTS public.drivers (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  vehicle_type VARCHAR(100),
  license_number VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  current_status VARCHAR(50) DEFAULT 'متاح', -- متاح، في توصيلة، غير متاح
  last_location_lat DECIMAL(10, 8),
  last_location_lng DECIMAL(11, 8),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 0. الفئات المركزية (Categories)
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) UNIQUE NOT NULL,
  icon VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. الطلبات والمبيعات (Orders) - تم التحديث لدعم الأنواع
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES public.drivers(id) ON DELETE SET NULL,
  total_amount DECIMAL(12, 2) NOT NULL,
  delivery_fee DECIMAL(12, 2) DEFAULT 0,
  status VARCHAR(50) DEFAULT 'قيد الانتظار', 
  payment_method VARCHAR(50) DEFAULT 'كاش',
  order_type VARCHAR(20) DEFAULT 'app', -- app, pos (بيع محلي)
  customer_name_manual VARCHAR(255), -- للبيع المحلي (عميل نقدي)
  delivery_address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. سجل الرقابة والتدقيق (Audit Logs)
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id),
  action_type VARCHAR(50) NOT NULL, -- stock_edit, price_override, void_order
  description TEXT,
  severity VARCHAR(20) DEFAULT 'info', -- info, warning, critical
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. إغلاق الصناديق (Shift Closings)
CREATE TABLE IF NOT EXISTS public.shift_closings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  manager_id UUID REFERENCES public.profiles(id),
  expected_cash DECIMAL(12, 2) NOT NULL,
  actual_cash DECIMAL(12, 2) NOT NULL,
  difference DECIMAL(12, 2) GENERATED ALWAYS AS (actual_cash - expected_cash) STORED,
  notes TEXT,
  status VARCHAR(20) DEFAULT 'closed',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. الإشعارات الإدارية (Admin Notifications)
CREATE TABLE IF NOT EXISTS public.admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'admin_note', -- admin_note, stock_alert, policy_update
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. تفاصيل الطلبات (Order Items)
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  quantity DECIMAL(10, 3) NOT NULL, -- دعم الغرامات (3 مراتب عشرية)
  unit_price DECIMAL(12, 2) NOT NULL,
  total_price DECIMAL(12, 2) NOT NULL
);

-- ==========================================
-- تفعيل سياسات الأمان (RLS)
-- ==========================================
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.damaged_goods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Helper Function: جلب role المستخدم الحالي
-- ==========================================
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.get_my_branch_id()
RETURNS UUID AS $$
  SELECT branch_id FROM public.profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ==========================================
-- RLS POLICIES - BRANCHES
-- ==========================================
-- Super admin يرى كل الفروع
CREATE POLICY "super_admin_all_branches" ON public.branches
  FOR ALL USING (true); -- تم الفتح مؤقتاً للتطوير لضمان عمل الإضافة عندك الآن

-- مدير الفرع يرى فرعه فقط
CREATE POLICY "manager_own_branch" ON public.branches
  FOR SELECT USING (true);

-- ==========================================
-- RLS POLICIES - PROFILES
-- ==========================================
-- كل مستخدم يرى بياناته الخاصة
CREATE POLICY "users_own_profile" ON public.profiles
  FOR ALL USING (id = auth.uid());

-- Super admin يرى كل المستخدمين
CREATE POLICY "super_admin_all_profiles" ON public.profiles
  FOR ALL USING (public.get_my_role() = 'super_admin');

-- مدير الفرع يرى موظفي فرعه
CREATE POLICY "manager_branch_profiles" ON public.profiles
  FOR SELECT USING (
    public.get_my_role() = 'branch_manager' AND branch_id = public.get_my_branch_id()
  );

-- ==========================================
-- RLS POLICIES - PRODUCTS
-- ==========================================
-- الكل يقرأ المنتجات النشطة
CREATE POLICY "anyone_read_products" ON public.products
  FOR SELECT USING (is_active = true);

-- Super admin يتحكم بكل المنتجات
CREATE POLICY "super_admin_manage_products" ON public.products
  FOR ALL USING (public.get_my_role() = 'super_admin');

-- ==========================================
-- RLS POLICIES - INVENTORY
-- ==========================================
-- Super admin يرى كل المخزون
CREATE POLICY "super_admin_all_inventory" ON public.inventory
  FOR ALL USING (public.get_my_role() = 'super_admin');

-- مدير الفرع يدير مخزون فرعه فقط
CREATE POLICY "manager_own_inventory" ON public.inventory
  FOR ALL USING (
    public.get_my_role() = 'branch_manager' AND branch_id = public.get_my_branch_id()
  );

-- ==========================================
-- RLS POLICIES - PURCHASES
-- ==========================================
CREATE POLICY "super_admin_all_purchases" ON public.purchases
  FOR ALL USING (public.get_my_role() = 'super_admin');

CREATE POLICY "manager_own_purchases" ON public.purchases
  FOR ALL USING (
    public.get_my_role() = 'branch_manager' AND branch_id = public.get_my_branch_id()
  );

-- ==========================================
-- RLS POLICIES - DAMAGED GOODS
-- ==========================================
CREATE POLICY "super_admin_all_damaged" ON public.damaged_goods
  FOR ALL USING (public.get_my_role() = 'super_admin');

CREATE POLICY "manager_own_damaged" ON public.damaged_goods
  FOR ALL USING (
    public.get_my_role() = 'branch_manager' AND branch_id = public.get_my_branch_id()
  );

-- ==========================================
-- RLS POLICIES - DRIVERS
-- ==========================================
CREATE POLICY "super_admin_all_drivers" ON public.drivers
  FOR ALL USING (public.get_my_role() = 'super_admin');

-- السائق يرى بياناته
CREATE POLICY "driver_own_data" ON public.drivers
  FOR SELECT USING (id = auth.uid());

-- ==========================================
-- RLS POLICIES - ORDERS
-- ==========================================
-- Super admin يرى كل الطلبات
CREATE POLICY "super_admin_all_orders" ON public.orders
  FOR ALL USING (public.get_my_role() = 'super_admin');

-- مدير الفرع يرى طلبات فرعه
CREATE POLICY "manager_branch_orders" ON public.orders
  FOR ALL USING (
    public.get_my_role() = 'branch_manager' AND branch_id = public.get_my_branch_id()
  );

-- العميل يرى طلباته
CREATE POLICY "customer_own_orders" ON public.orders
  FOR SELECT USING (customer_id = auth.uid());

-- العميل ينشئ طلب
CREATE POLICY "customer_create_order" ON public.orders
  FOR INSERT WITH CHECK (customer_id = auth.uid());

-- السائق يرى الطلبات المخصصة له
CREATE POLICY "driver_assigned_orders" ON public.orders
  FOR SELECT USING (driver_id = auth.uid());

-- السائق يحدث حالة الطلب
CREATE POLICY "driver_update_order_status" ON public.orders
  FOR UPDATE USING (driver_id = auth.uid());

-- ==========================================
-- RLS POLICIES - ORDER ITEMS
-- ==========================================
CREATE POLICY "super_admin_all_order_items" ON public.order_items
  FOR ALL USING (public.get_my_role() = 'super_admin');

CREATE POLICY "read_own_order_items" ON public.order_items
  FOR SELECT USING (
    order_id IN (SELECT id FROM public.orders WHERE customer_id = auth.uid() OR driver_id = auth.uid())
  );

CREATE POLICY "manager_branch_order_items" ON public.order_items
  FOR SELECT USING (
    order_id IN (SELECT id FROM public.orders WHERE branch_id = public.get_my_branch_id())
  );

-- ==========================================
-- Realtime subscriptions (تفعيل الـ Realtime)
-- ==========================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.drivers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.inventory;

-- ==========================================
-- بيانات تجريبية - Seed Data
-- ==========================================
-- ==========================================
-- آليات تحديث المخزون التلقائي (Stock Triggers)
-- ==========================================

-- 1. تحديث المخزون عند شراء مواد جديدة
CREATE OR REPLACE FUNCTION public.update_stock_on_purchase()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.inventory (branch_id, product_id, stock_quantity)
  VALUES (
    (SELECT branch_id FROM public.purchases WHERE id = NEW.purchase_id),
    NEW.product_id,
    NEW.quantity
  )
  ON CONFLICT (branch_id, product_id)
  DO UPDATE SET stock_quantity = public.inventory.stock_quantity + EXCLUDED.stock_quantity,
                updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_on_purchase
AFTER INSERT ON public.purchase_items
FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_purchase();

-- 2. تحديث المخزون عند إتمام بيع (خصم)
CREATE OR REPLACE FUNCTION public.update_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
  -- الخصم يتم فقط عند تحول حالة الطلب إلى "تحضير" أو "مكتمل"
  -- (نخصمه عند التحضير لضمان حجز الكمية)
  IF (NEW.status = 'تحضير' AND (OLD.status = 'قيد الانتظار' OR OLD.status IS NULL)) THEN
    UPDATE public.inventory
    SET stock_quantity = stock_quantity - (
      SELECT quantity FROM public.order_items WHERE order_id = NEW.id AND product_id = public.inventory.product_id
    )
    WHERE branch_id = NEW.branch_id
    AND product_id IN (SELECT product_id FROM public.order_items WHERE order_id = NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_on_sale
AFTER UPDATE OF status ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_sale();

-- 3. تحديث المخزون عند إضافة تالف أو مرتجع
CREATE OR REPLACE FUNCTION public.update_stock_on_damaged()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'damaged' THEN
    UPDATE public.inventory
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE branch_id = NEW.branch_id AND product_id = NEW.product_id;
  ELSIF NEW.type = 'return' THEN
    UPDATE public.inventory
    SET stock_quantity = stock_quantity + NEW.quantity
    WHERE branch_id = NEW.branch_id AND product_id = NEW.product_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_on_damaged
AFTER INSERT ON public.damaged_goods
FOR EACH ROW EXECUTE FUNCTION public.update_stock_on_damaged();
