-- ═══════════════════════════════════════════════════════════
-- FRESH APP — FIX RLS & SEED DATA SCRIPT
-- Copy & Paste this into Supabase SQL Editor and Run
-- ═══════════════════════════════════════════════════════════

-- 1. Fix RLS Policies for Branch Operations
-- Allowing branches to upsert branch_inventory and purchases

-- Create daily_settlements table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.daily_settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  total_sales NUMERIC DEFAULT 0,
  total_purchases NUMERIC DEFAULT 0,
  total_damaged NUMERIC DEFAULT 0,
  net_revenue NUMERIC DEFAULT 0,
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS (just in case)
ALTER TABLE public.branch_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_settlements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "branch_inventory_read" ON public.branch_inventory;
DROP POLICY IF EXISTS "branch_inventory_insert_update" ON public.branch_inventory;
DROP POLICY IF EXISTS "purchases_insert" ON public.purchases;
DROP POLICY IF EXISTS "purchase_items_insert" ON public.purchase_items;
DROP POLICY IF EXISTS "daily_settlements_insert" ON public.daily_settlements;

-- Allow reading branch_inventory
CREATE POLICY "branch_inventory_read"
  ON public.branch_inventory FOR SELECT
  USING (true);

-- Allow anonymous or branch users to upsert branch_inventory (For testing purposes)
CREATE POLICY "branch_inventory_insert_update"
  ON public.branch_inventory FOR ALL
  USING (true) WITH CHECK (true);

-- Allow anonymous or branch users to insert purchases
CREATE POLICY "purchases_insert"
  ON public.purchases FOR ALL
  USING (true) WITH CHECK (true);

-- Allow anonymous or branch users to insert purchase items
CREATE POLICY "purchase_items_insert"
  ON public.purchase_items FOR ALL
  USING (true) WITH CHECK (true);

CREATE POLICY "daily_settlements_insert"
  ON public.daily_settlements FOR ALL
  USING (true) WITH CHECK (true);

-- 2. Seed Data Injection (Arabic Test Products)

-- Seed Categories
INSERT INTO public.categories (name, image_url, icon) VALUES
  ('خضروات', 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=200&q=80', 'carrot'),
  ('فواكه', 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=200&q=80', 'apple-l')
ON CONFLICT DO NOTHING;

-- Seed Products
INSERT INTO public.products (name, category, unit, price, default_price, cost, is_active, image_url) VALUES
  ('طماطم طازجة', 'خضروات', 'كيلو', 1500, 1500, 1000, true, 'https://images.unsplash.com/photo-1546470427-e26264be0b0d?auto=format&fit=crop&w=400&q=80'),
  ('خيار عراقي', 'خضروات', 'كيلو', 1000, 1000, 750, true, 'https://images.unsplash.com/photo-1589621316382-008455b857cd?auto=format&fit=crop&w=400&q=80'),
  ('تفاح أحمر', 'فواكه', 'كيلو', 2500, 2500, 2000, true, 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?auto=format&fit=crop&w=400&q=80'),
  ('موز أصفر', 'فواكه', 'كيلو', 1800, 1800, 1500, true, 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=400&q=80')
ON CONFLICT DO NOTHING;

-- 3. Link Products to Branch Inventory (Zero Quantity initially)
INSERT INTO public.branch_inventory (branch_id, product_id, actual_stock)
SELECT 
  b.id AS branch_id,
  p.id AS product_id,
  0 AS actual_stock
FROM 
  (SELECT id FROM public.branches WHERE status = 'نشط' LIMIT 1) b,
  public.products p
ON CONFLICT (branch_id, product_id) DO UPDATE 
  SET actual_stock = EXCLUDED.actual_stock;
