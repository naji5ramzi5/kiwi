-- ============================================================
-- fix_all_rls.sql — إصلاح شامل لصلاحيات RLS
-- شغّل هذا الملف في Supabase SQL Editor مرة واحدة
-- ============================================================

-- ─── 1. إضافة الأعمدة الناقصة ──────────────────────────────
ALTER TABLE IF EXISTS public.categories ADD COLUMN IF NOT EXISTS icon TEXT DEFAULT 'tag';
ALTER TABLE IF EXISTS public.categories ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

-- ─── 2. إصلاح دوال المساعدة ────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT COALESCE(
    (SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()),
    'customer'
  );
$$;

CREATE OR REPLACE FUNCTION public.get_my_branch_id()
RETURNS UUID
LANGUAGE SQL STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT COALESCE(
    (SELECT (raw_user_meta_data->>'branch_id')::UUID FROM auth.users WHERE id = auth.uid()),
    NULL
  );
$$;

-- ─── 3. حذف كل سياسات RLS في public ────────────────────────
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN (
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

-- ─── 4. تفعيل RLS على جميع الجداول ──────────────────────────
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN (
    SELECT tablename FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT IN ('schema_migrations', 'spatial_ref_sys')
  ) LOOP
    EXECUTE format('ALTER TABLE IF EXISTS public.%I ENABLE ROW LEVEL SECURITY', tbl);
  END LOOP;
END $$;

-- ─── 5. سياسات RLS جديدة ────────────────────────────────────
-- لمستخدمي لوحة التحكم: المصادق يفعل كل شيء
-- لمستخدمي التطبيق: قراءة عامة للمنتجات والفروع والتصنيفات

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN (
    SELECT tablename FROM pg_tables 
    WHERE schemaname = 'public'
    AND tablename NOT IN ('schema_migrations', 'spatial_ref_sys')
  ) LOOP
    EXECUTE format(
      'CREATE POLICY "admin_all_%s" ON public.%I FOR ALL USING (auth.role() = ''authenticated'') WITH CHECK (auth.role() = ''authenticated'')',
      tbl, tbl
    );
  END LOOP;
END $$;

-- ─── 6. سياسات القراءة العامة لبعض الجداول ──────────────────
-- للجداول التي يحتاجها تطبيق الزبون
CREATE POLICY "public_read_products" ON public.products FOR SELECT USING (true);
CREATE POLICY "public_read_branches" ON public.branches FOR SELECT USING (true);
CREATE POLICY "public_read_categories" ON public.categories FOR SELECT USING (true);
CREATE POLICY "public_read_banners" ON public.banners FOR SELECT USING (true);
CREATE POLICY "public_read_delivery_zones" ON public.delivery_zones FOR SELECT USING (true);
CREATE POLICY "public_read_story_groups" ON public.story_groups FOR SELECT USING (true);
CREATE POLICY "public_read_story_items" ON public.story_items FOR SELECT USING (true);

-- ─── 7. إنشاء admin_notifications إذا ما موجودة ────────────
CREATE TABLE IF NOT EXISTS public.admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  body TEXT,
  type TEXT DEFAULT 'info',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─── 8. في حال كان في جدول users قديم، نضيف عليه سياسات ────
DO $$ BEGIN
  EXECUTE 'ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY';
  EXECUTE 'DROP POLICY IF EXISTS "admin_all_users" ON public.users';
  EXECUTE 'CREATE POLICY "admin_all_users" ON public.users FOR ALL USING (auth.role() = ''authenticated'') WITH CHECK (auth.role() = ''authenticated'')';
EXCEPTION WHEN undefined_table THEN END;
$$;
