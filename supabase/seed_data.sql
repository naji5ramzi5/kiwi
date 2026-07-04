-- ============================================================
-- Fresh Project - Seed Data
-- Run this in Supabase SQL Editor AFTER migrations are applied
-- ============================================================

-- ─── Categories ─────────────────────────────────────────────
INSERT INTO public.categories (id, name, image_url, is_active) VALUES
  ('cat-001', 'فواكه', 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=400&q=80', true),
  ('cat-002', 'خضروات', 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=400&q=80', true),
  ('cat-003', 'لحوم ودواجن', 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=400&q=80', true),
  ('cat-004', 'ألبان', 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=400&q=80', true),
  ('cat-005', 'مشروبات', 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=400&q=80', true),
  ('cat-006', 'سناك', 'https://images.unsplash.com/photo-1599598425947-330026296906?auto=format&fit=crop&w=400&q=80', true),
  ('cat-007', 'بقالة', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80', true),
  ('cat-008', 'زيوت وتوابل', 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80', true),
  ('cat-009', 'مخبوزات', 'https://images.unsplash.com/photo-1509365465985-25d11c17e812?auto=format&fit=crop&w=400&q=80', true),
  ('cat-010', 'منظفات', 'https://images.unsplash.com/photo-1585422779461-1d2b9f4e6b5a?auto=format&fit=crop&w=400&q=80', true)
ON CONFLICT (id) DO NOTHING;

-- ─── Branches ──────────────────────────────────────────────
INSERT INTO public.branches (id, name, address, latitude, longitude, status, phone, access_code) VALUES
  ('branch-001', 'فرع الكرادة', 'شارع أبو نواس، الكرادة، بغداد', 33.3152, 44.3661, 'نشط', '+9647701111111', 'FRESH-KRADA'),
  ('branch-002', 'فرع المنصور', 'المنصور، بغداد', 33.3219, 44.3617, 'نشط', '+9647702222222', 'FRESH-MANSUR'),
  ('branch-003', 'فرع الزيونة', 'الزيونة، بغداد', 33.3095, 44.3730, 'نشط', '+9647703333333', 'FRESH-ZAYUNA')
ON CONFLICT (id) DO NOTHING;

-- ─── Products ──────────────────────────────────────────────
INSERT INTO public.products (id, name, category, unit, default_price, image_url, is_active, barcode, allowed_branches) VALUES
  ('prod-001', 'تفاح أحمر', 'فواكه', 'كيلو', 2500, 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=400&q=80', true, '624000001',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-002', 'موز', 'فواكه', 'كيلو', 2000, 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b6e3?auto=format&fit=crop&w=400&q=80', true, '624000002',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-003', 'برتقال', 'فواكه', 'كيلو', 1500, 'https://images.unsplash.com/photo-1547514701-42782101795e?auto=format&fit=crop&w=400&q=80', true, '624000003',
    ARRAY['branch-001', 'branch-002']),
  ('prod-004', 'عنب أسود', 'فواكه', 'كيلو', 3000, 'https://images.unsplash.com/photo-1596363505726-c1936e3935ec?auto=format&fit=crop&w=400&q=80', true, '624000004',
    ARRAY['branch-001', 'branch-003']),
  ('prod-005', 'طماطم', 'خضروات', 'كيلو', 1000, 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=400&q=80', true, '624000005',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-006', 'خيار', 'خضروات', 'كيلو', 800, 'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?auto=format&fit=crop&w=400&q=80', true, '624000006',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-007', 'بصل', 'خضروات', 'كيلو', 1000, 'https://images.unsplash.com/photo-1508747703725-719777637510?auto=format&fit=crop&w=400&q=80', true, '624000007',
    ARRAY['branch-001', 'branch-002']),
  ('prod-008', 'بطاطا', 'خضروات', 'كيلو', 1200, 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=400&q=80', true, '624000008',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-009', 'دجاج طازج', 'لحوم ودواجن', 'كيلو', 6500, 'https://images.unsplash.com/photo-1587593810167-a84920ea0781?auto=format&fit=crop&w=400&q=80', true, '624000009',
    ARRAY['branch-001', 'branch-002']),
  ('prod-010', 'لحم عجل', 'لحوم ودواجن', 'كيلو', 18000, 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=400&q=80', true, '624000010',
    ARRAY['branch-001']),
  ('prod-011', 'حليب كامل الدسم', 'ألبان', 'لتر', 1500, 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=400&q=80', true, '624000011',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-012', 'زبادي', 'ألبان', 'علبة', 500, 'https://images.unsplash.com/photo-1571212515416-fef01fc43637?auto=format&fit=crop&w=400&q=80', true, '624000012',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-013', 'جبنة بيضاء', 'ألبان', 'كيلو', 8000, 'https://images.unsplash.com/photo-1634487359989-3e90c9562133?auto=format&fit=crop&w=400&q=80', true, '624000013',
    ARRAY['branch-001']),
  ('prod-014', 'مياه معدنية', 'مشروبات', 'كرتونة', 5000, 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=400&q=80', true, '624000014',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-015', 'بيبسي', 'مشروبات', 'علبة', 750, 'https://images.unsplash.com/photo-1629203851122-3726ec8e81c9?auto=format&fit=crop&w=400&q=80', true, '624000015',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-016', 'شيبس', 'سناك', 'كيس', 1000, 'https://images.unsplash.com/photo-1599598425947-330026296906?auto=format&fit=crop&w=400&q=80', true, '624000016',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-017', 'شوكولاتة', 'سناك', 'قطعة', 2000, 'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?auto=format&fit=crop&w=400&q=80', true, '624000017',
    ARRAY['branch-001', 'branch-002']),
  ('prod-018', 'زيت نباتي', 'زيوت وتوابل', 'لتر', 3500, 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80', true, '624000018',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-019', 'رز بسمتي', 'بقالة', 'كيلو', 3500, 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80', true, '624000019',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-020', 'سكر', 'بقالة', 'كيلو', 1500, 'https://images.unsplash.com/photo-1585314614250-d2133462e6a6?auto=format&fit=crop&w=400&q=80', true, '624000020',
    ARRAY['branch-001', 'branch-002']),
  ('prod-021', 'خبز عربي', 'مخبوزات', 'ربطة', 1000, 'https://images.unsplash.com/photo-1509365465985-25d11c17e812?auto=format&fit=crop&w=400&q=80', true, '624000021',
    ARRAY['branch-001', 'branch-002', 'branch-003']),
  ('prod-022', 'معطر جو', 'منظفات', 'علبة', 3000, 'https://images.unsplash.com/photo-1585422779461-1d2b9f4e6b5a?auto=format&fit=crop&w=400&q=80', true, '624000022',
    ARRAY['branch-001', 'branch-002']),
  ('prod-023', 'صابون سائل', 'منظفات', 'لتر', 2500, 'https://images.unsplash.com/photo-1585422779461-1d2b9f4e6b5a?auto=format&fit=crop&w=400&q=80', true, '624000023',
    ARRAY['branch-001', 'branch-002', 'branch-003'])
ON CONFLICT (id) DO NOTHING;

-- ─── Initial Inventory (Set to 100 for each product at allowed branches) ──
INSERT INTO public.inventory (id, branch_id, product_id, stock_quantity)
SELECT
  gen_random_uuid()::text,
  branch_id,
  product_id,
  100
FROM (
  SELECT unnest(p.allowed_branches) AS branch_id, p.id AS product_id
  FROM public.products p
) sub
ON CONFLICT (branch_id, product_id) DO UPDATE SET stock_quantity = EXCLUDED.stock_quantity;
