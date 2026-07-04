-- ═══════════════════════════════════════════════════════════
-- FRESH APP — Seed Data Script
-- Copy & Paste this into Supabase SQL Editor and Run
-- ═══════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────
-- 1. CREATE categories TABLE (if not exists)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_en TEXT,
  image_url TEXT,
  icon TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read categories
CREATE POLICY IF NOT EXISTS "categories_public_read"
  ON public.categories FOR SELECT
  USING (true);

-- Allow admin to manage
CREATE POLICY IF NOT EXISTS "categories_admin_manage"
  ON public.categories FOR ALL
  USING (auth.role() = 'service_role');

-- ─────────────────────────────────────────────
-- 2. SEED CATEGORIES (8 categories)
-- ─────────────────────────────────────────────
INSERT INTO public.categories (name, name_en, image_url, icon, sort_order) VALUES
  ('خضروات', 'Vegetables', 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=200&q=80', '🥦', 1),
  ('فواكه', 'Fruits', 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=200&q=80', '🍎', 2),
  ('تمور', 'Dates', 'https://images.unsplash.com/photo-1596431989042-49764de3d037?auto=format&fit=crop&w=200&q=80', '🫒', 3),
  ('مكسرات', 'Nuts', 'https://images.unsplash.com/photo-1599598425947-330026296906?auto=format&fit=crop&w=200&q=80', '🥜', 4),
  ('بقوليات', 'Legumes', 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=200&q=80', '🫘', 5),
  ('ألبان وأجبان', 'Dairy', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=200&q=80', '🧀', 6),
  ('عصائر وأشربة', 'Juices', 'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=200&q=80', '🧃', 7),
  ('بهارات', 'Spices', 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=200&q=80', '🌶️', 8)
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────
-- 3. SEED PRODUCTS (15 products)
-- ─────────────────────────────────────────────
-- First, get the first branch id to link products
-- Make sure you have at least one branch in your 'branches' table

-- Insert products (adjust branch_id if needed)
WITH first_branch AS (
  SELECT id FROM public.branches WHERE status = 'نشط' LIMIT 1
)
INSERT INTO public.products (
  name, name_en, description, price, unit, image_url,
  category, is_available, is_featured
) VALUES
  -- Vegetables
  ('طماطم طازجة', 'Fresh Tomatoes',
   'طماطم حمراء طازجة مختارة يدوياً، مثالية للسلطات والطبخ',
   1500, 'كغ',
   'https://images.unsplash.com/photo-1546470427-e26264be0b0d?auto=format&fit=crop&w=400&q=80',
   'خضروات', true, true),

  ('خيار عراقي', 'Iraqi Cucumber',
   'خيار طازج ومقرمش، يُجلب يومياً من المزارع المحلية',
   1000, 'كغ',
   'https://images.unsplash.com/photo-1589621316382-008455b857cd?auto=format&fit=crop&w=400&q=80',
   'خضروات', true, false),

  ('بطاطا بيضاء', 'White Potatoes',
   'بطاطا طازجة مناسبة للقلي والسلق والشواء',
   1200, 'كغ',
   'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=400&q=80',
   'خضروات', true, false),

  ('بصل أحمر', 'Red Onion',
   'بصل أحمر طازج، يُضيف نكهة رائعة لجميع الأطباق',
   800, 'كغ',
   'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?auto=format&fit=crop&w=400&q=80',
   'خضروات', true, false),

  ('فلفل ألوان', 'Colorful Peppers',
   'فلفل ملون (أحمر، أصفر، أخضر) مناسب للسلطة والمحاشي',
   2000, 'كغ',
   'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?auto=format&fit=crop&w=400&q=80',
   'خضروات', true, true),

  -- Fruits
  ('تفاح أحمر', 'Red Apple',
   'تفاح أحمر مستورد، طازج وحلو المذاق',
   2500, 'كغ',
   'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?auto=format&fit=crop&w=400&q=80',
   'فواكه', true, true),

  ('موز أصفر', 'Yellow Banana',
   'موز أصفر ناضج، غني بالبوتاسيوم والطاقة',
   1800, 'كغ',
   'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=400&q=80',
   'فواكه', true, false),

  ('برتقال حلو', 'Sweet Orange',
   'برتقال حلو طازج، يُستخرج منه أشهى العصائر',
   1500, 'كغ',
   'https://images.unsplash.com/photo-1547514701-42782101795e?auto=format&fit=crop&w=400&q=80',
   'فواكه', true, false),

  ('رمان عراقي', 'Iraqi Pomegranate',
   'رمان محلي طازج، من أشهر فواكه العراق الموسمية',
   3000, 'حبة',
   'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=400&q=80',
   'فواكه', true, true),

  -- Dates
  ('تمر مضافي', 'Medjool Dates',
   'تمر مضافي فاخر، من أجود أنواع التمور العراقية',
   8000, '500 غ',
   'https://images.unsplash.com/photo-1596431989042-49764de3d037?auto=format&fit=crop&w=400&q=80',
   'تمور', true, true),

  ('تمر الزاهدي', 'Zahidi Dates',
   'تمر زاهدي أصيل من البصرة، ذو طعم رائع',
   5000, 'كغ',
   'https://images.unsplash.com/photo-1573848765430-fe1dfba78c55?auto=format&fit=crop&w=400&q=80',
   'تمور', true, false),

  -- Nuts
  ('كاجو محمص', 'Roasted Cashews',
   'كاجو محمص بالملح الخفيف، مقرمش ولذيذ',
   12000, '500 غ',
   'https://images.unsplash.com/photo-1599598425947-330026296906?auto=format&fit=crop&w=400&q=80',
   'مكسرات', true, true),

  ('لوز نيء', 'Raw Almonds',
   'لوز نيء طبيعي، غني بالفيتامينات والبروتين',
   10000, '500 غ',
   'https://images.unsplash.com/photo-1508061253366-f7da158b6d46?auto=format&fit=crop&w=400&q=80',
   'مكسرات', true, false),

  -- Dairy
  ('جبن موزاريلا', 'Mozzarella Cheese',
   'جبن موزاريلا طازج، مثالي للبيتزا والسندويشات',
   6000, '250 غ',
   'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=400&q=80',
   'ألبان وأجبان', true, false),

  ('لبن عراقي طازج', 'Fresh Iraqi Yogurt',
   'لبن طازج يومي من مزارع محلية، خالٍ من المواد الحافظة',
   3500, 'كغ',
   'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=400&q=80',
   'ألبان وأجبان', true, true)
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────
-- 4. LINK PRODUCTS TO BRANCH INVENTORY
-- ─────────────────────────────────────────────
-- This creates branch_inventory records for all products in the first branch
INSERT INTO public.branch_inventory (branch_id, product_id, actual_stock)
SELECT 
  b.id AS branch_id,
  p.id AS product_id,
  FLOOR(RANDOM() * 50 + 20) AS actual_stock  -- Random stock 20-70
FROM 
  (SELECT id FROM public.branches WHERE status = 'نشط' LIMIT 1) b,
  public.products p
ON CONFLICT (branch_id, product_id) DO UPDATE 
  SET actual_stock = EXCLUDED.actual_stock;

-- ─────────────────────────────────────────────
-- 5. FIX AUTH — Disable email confirmation
--    (Run this in Supabase Dashboard → SQL Editor)
-- ─────────────────────────────────────────────
-- NOTE: You also need to go to:
--   Authentication → Settings → Disable "Enable email confirmations"
-- This is a UI setting in Supabase, not SQL.

-- Verify your data:
SELECT COUNT(*) as total_categories FROM public.categories;
SELECT COUNT(*) as total_products FROM public.products;
SELECT COUNT(*) as total_inventory FROM public.branch_inventory;
