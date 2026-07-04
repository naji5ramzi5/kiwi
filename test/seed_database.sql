-- ==============================================================
-- Fresh App Seeding Script - run this in Supabase SQL Editor!
-- ==============================================================

-- 1. Seed Banners
INSERT INTO public.banners (image_url, link_type, is_active, sort_order)
VALUES 
  ('https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&fit=crop&q=80', 'none', true, 1),
  ('https://images.unsplash.com/photo-1607349913338-fca6f7fc42d0?w=800&fit=crop&q=80', 'none', true, 2),
  ('https://images.unsplash.com/photo-1506084868230-bb9d95c24759?w=800&fit=crop&q=80', 'none', true, 3);

-- Add image_url to categories if it does not exist
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Seed Categories
INSERT INTO public.categories (name, icon, image_url)
VALUES 
  ('خضروات', 'carrot', 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=400&fit=crop&q=80'),
  ('فواكه', 'apple-l', 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400&fit=crop&q=80'),
  ('ورقيات', 'leaf', 'https://images.unsplash.com/photo-1622312693822-4917a14e9124?w=400&fit=crop&q=80'),
  ('تمور', 'sun', 'https://images.unsplash.com/photo-1596431989042-49764de3d037?w=400&fit=crop&q=80'),
  ('مكسرات', 'nut', 'https://images.unsplash.com/photo-1599598425947-330026296906?w=400&fit=crop&q=80')
ON CONFLICT (name) DO UPDATE SET 
  icon = EXCLUDED.icon,
  image_url = EXCLUDED.image_url;

-- 3. Seed Products (We won't use ON CONFLICT because name is not unique)
-- First, let's clear existing sample products to avoid duplicates
DELETE FROM public.products;

INSERT INTO public.products (name, category, unit, price, cost, is_active, image_url)
VALUES
  ('طماطم طازجة', 'خضروات', 'كيلو', 1250, 1500, true, 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=500&q=80'),
  ('بطاطا عراقية', 'خضروات', 'كيلو', 1000, 1200, true, 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500&q=80'),
  ('خيار ماء', 'خضروات', 'كيلو', 1500, 1800, true, 'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=500&q=80'),
  ('تفاح أحمر لبناني', 'فواكه', 'كيلو', 2500, 3000, true, 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&q=80'),
  ('موز صومالي', 'فواكه', 'كيلو', 2000, 2500, true, 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&q=80'),
  ('برتقال أبو صرة', 'فواكه', 'كيلو', 1750, 2000, true, 'https://images.unsplash.com/photo-1582979512210-99b6a53885f3?w=500&q=80'),
  ('نعناع طازج', 'ورقيات', 'باقة', 250, 400, true, 'https://images.unsplash.com/photo-1536882240095-0379873feb4e?w=500&q=80'),
  ('بقدونس أخضر', 'ورقيات', 'باقة', 250, 400, true, 'https://images.unsplash.com/photo-1515224526905-51c7d77c7bb8?w=500&q=80'),
  ('تمر خلاص الأحساء', 'تمور', 'علبة', 4500, 5000, true, 'https://images.unsplash.com/photo-1596431989042-49764de3d037?w=500&q=80'),
  ('لوز أمريكي مقشر', 'مكسرات', 'كيلو', 12000, 14000, true, 'https://images.unsplash.com/photo-1508061253366-f7da158b6db4?w=500&q=80');

-- 4. Fill branch_inventory for all active branches and all products
INSERT INTO public.branch_inventory (branch_id, product_id, actual_stock, buffer_limit, is_active)
SELECT 
  b.id as branch_id,
  p.id as product_id,
  100.0 as actual_stock,
  2 as buffer_limit,
  true as is_active
FROM public.branches b
CROSS JOIN public.products p
WHERE b.status = 'نشط'
ON CONFLICT (branch_id, product_id) DO UPDATE SET 
  actual_stock = 100.0,
  is_active = true;

-- Ensure RLS is disabled temporarily or policies exist for inventory if it's missing.
-- Done!
