-- ============================================================
-- Fresh App - Complete Schema + RLS Policies
-- Run this in Supabase SQL Editor to fix all missing tables & permissions
-- ============================================================

-- ─── 1. Create Missing Tables ───────────────────────────────

-- Branches: add missing columns
ALTER TABLE IF EXISTS public.branches ADD COLUMN IF NOT EXISTS access_code TEXT;
ALTER TABLE IF EXISTS public.branches ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'نشط';

-- Products: add missing columns
ALTER TABLE IF EXISTS public.products ADD COLUMN IF NOT EXISTS default_price NUMERIC DEFAULT 0;
ALTER TABLE IF EXISTS public.products ADD COLUMN IF NOT EXISTS price NUMERIC DEFAULT 0;

-- banner ads table
CREATE TABLE IF NOT EXISTS public.banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url TEXT NOT NULL,
  link_type TEXT DEFAULT 'none',
  link_value TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- story groups (like Instagram stories)
CREATE TABLE IF NOT EXISTS public.story_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  thumbnail_url TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- individual story items within a group
CREATE TABLE IF NOT EXISTS public.story_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES public.story_groups(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL DEFAULT 'image',
  media_url TEXT,
  text_content TEXT,
  bg_color TEXT DEFAULT '#10b981',
  duration INT DEFAULT 5,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- discount/coupon codes
CREATE TABLE IF NOT EXISTS public.discount_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  discount_amount NUMERIC NOT NULL DEFAULT 10,
  type TEXT NOT NULL DEFAULT 'percent',
  max_uses INT DEFAULT 100,
  used_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  min_order_amount NUMERIC,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- delivery zones per branch
CREATE TABLE IF NOT EXISTS public.delivery_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'منطقة جديدة',
  color TEXT DEFAULT '#10b981',
  delivery_fee NUMERIC DEFAULT 1000,
  min_order NUMERIC DEFAULT 5000,
  max_delivery_time INT DEFAULT 45,
  is_active BOOLEAN DEFAULT true,
  geojson JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- branch inventory (per-branch stock levels)
CREATE TABLE IF NOT EXISTS public.branch_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  actual_stock NUMERIC DEFAULT 0,
  buffer_limit NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(branch_id, product_id)
);

-- purchase line items
CREATE TABLE IF NOT EXISTS public.purchase_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id UUID REFERENCES public.purchases(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  quantity NUMERIC NOT NULL DEFAULT 1,
  unit_price NUMERIC NOT NULL DEFAULT 0,
  total_price NUMERIC NOT NULL DEFAULT 0
);

-- daily financial settlements
CREATE TABLE IF NOT EXISTS public.daily_settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  total_sales NUMERIC DEFAULT 0,
  total_expenses NUMERIC DEFAULT 0,
  net_profit NUMERIC DEFAULT 0,
  settled_at DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- system settings (key-value store)
CREATE TABLE IF NOT EXISTS public.system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- waste records
CREATE TABLE IF NOT EXISTS public.waste_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
  quantity NUMERIC NOT NULL DEFAULT 0,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- internal notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- driver ratings by customers
CREATE TABLE IF NOT EXISTS public.driver_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- partner settlements (financial distribution)
CREATE TABLE IF NOT EXISTS public.partner_settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  total_revenue NUMERIC DEFAULT 0,
  dev_partner_share NUMERIC DEFAULT 0,
  maintenance_fund NUMERIC DEFAULT 0,
  branch_profit NUMERIC DEFAULT 0,
  settled_at DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add missing columns to profiles
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE IF EXISTS public.profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- ─── 2. Insert default system settings ──────────────────────
INSERT INTO public.system_settings (key, value) VALUES
  ('dev_partner_ratio', '0.35'),
  ('system_maintenance_ratio', '0.10'),
  ('app_name', '"Fresh"'),
  ('default_currency', '"IQD"')
ON CONFLICT (key) DO NOTHING;

-- ─── 3. Enable RLS on all tables ────────────────────────────
-- (Only if not already enabled)
DO $$ 
BEGIN
  EXECUTE 'ALTER TABLE IF EXISTS public.banners ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.story_groups ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.story_items ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.discount_codes ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.delivery_zones ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.branch_inventory ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.purchase_items ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.daily_settlements ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.system_settings ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.waste_records ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.driver_ratings ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.partner_settlements ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.products ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.branches ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE IF EXISTS public.categories ENABLE ROW LEVEL SECURITY';
END $$;

-- ─── 4. Drop existing policies before recreating ────────────
DO $$ 
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN (
    SELECT policyname, tablename FROM pg_policies 
    WHERE schemaname = 'public' AND tablename IN (
      'banners','story_groups','story_items','discount_codes',
      'delivery_zones','branch_inventory','purchase_items',
      'daily_settlements','system_settings','waste_records',
      'notifications','driver_ratings','partner_settlements',
      'products','branches','categories'
    )
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

-- ─── 5. RLS Policies: Allow full access for authenticated users (admin/super_admin) ───

-- For admin-managed tables: any authenticated user (admin) can do everything
-- This works with the login flow in App.tsx

CREATE POLICY "Admin full access on banners"
  ON public.banners FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on story_groups"
  ON public.story_groups FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on story_items"
  ON public.story_items FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on discount_codes"
  ON public.discount_codes FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on delivery_zones"
  ON public.delivery_zones FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on branch_inventory"
  ON public.branch_inventory FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on purchase_items"
  ON public.purchase_items FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on daily_settlements"
  ON public.daily_settlements FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on system_settings"
  ON public.system_settings FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on waste_records"
  ON public.waste_records FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on notifications"
  ON public.notifications FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on driver_ratings"
  ON public.driver_ratings FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on partner_settlements"
  ON public.partner_settlements FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on products"
  ON public.products FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on branches"
  ON public.branches FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin full access on categories"
  ON public.categories FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');

-- ─── 6. Allow public SELECT on read-only tables (for customer app) ───
CREATE POLICY "Public read banners"
  ON public.banners FOR SELECT USING (true);

CREATE POLICY "Public read story_groups"
  ON public.story_groups FOR SELECT USING (true);

CREATE POLICY "Public read story_items"
  ON public.story_items FOR SELECT USING (true);

CREATE POLICY "Public read discount_codes"
  ON public.discount_codes FOR SELECT USING (true);

CREATE POLICY "Public read delivery_zones"
  ON public.delivery_zones FOR SELECT USING (true);

CREATE POLICY "Public read branch_inventory"
  ON public.branch_inventory FOR SELECT USING (true);

CREATE POLICY "Public read products"
  ON public.products FOR SELECT USING (true);

CREATE POLICY "Public read branches"
  ON public.branches FOR SELECT USING (true);

CREATE POLICY "Public read categories"
  ON public.categories FOR SELECT USING (true);

-- ─── 7. Create storage bucket for images if not exists ──────
-- Note: This requires the storage extension.
-- Run in Supabase Dashboard: Storage → Create bucket "images" (public)
-- Or via SQL:
INSERT INTO storage.buckets (id, name, public) 
SELECT 'images', 'images', true
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'images');
