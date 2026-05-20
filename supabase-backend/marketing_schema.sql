-- ==========================================
-- FRESH ENTERPRISE - MARKETING SCHEMA
-- ==========================================

-- 1. البنرات (Banners)
CREATE TABLE IF NOT EXISTS public.banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url TEXT NOT NULL,
  link_type VARCHAR(50) DEFAULT 'none', -- none, external, product
  link_value TEXT, -- رابط خارجي أو ID المنتج
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. مجموعات القصص (Story Groups - الحد الأقصى 7 عادة)
CREATE TABLE IF NOT EXISTS public.story_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(100) NOT NULL,
  thumbnail_url TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. عناصر القصص (Story Items)
CREATE TABLE IF NOT EXISTS public.story_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES public.story_groups(id) ON DELETE CASCADE,
  media_type VARCHAR(50) NOT NULL, -- image, video, text
  media_url TEXT, -- رابط الصورة أو الفيديو (الحد الأقصى 60 ثانية)
  text_content TEXT, -- إذا كان النوع text
  bg_color VARCHAR(20), -- لون الخلفية للنص
  duration INTEGER DEFAULT 5, -- مدة العرض بالثواني
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. سجل الإشعارات المرسلة (Push Notifications History)
CREATE TABLE IF NOT EXISTS public.push_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  target_audience VARCHAR(50) DEFAULT 'all', -- all, customers, drivers
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_notifications ENABLE ROW LEVEL SECURITY;

-- السماح للجميع بقراءة البنرات والقصص النشطة
CREATE POLICY "anyone_read_banners" ON public.banners FOR SELECT USING (is_active = true);
CREATE POLICY "anyone_read_story_groups" ON public.story_groups FOR SELECT USING (is_active = true);
CREATE POLICY "anyone_read_story_items" ON public.story_items FOR SELECT USING (true);

-- Super Admin يدير كل شيء
CREATE POLICY "admin_manage_banners" ON public.banners FOR ALL USING (public.get_my_role() = 'super_admin');
CREATE POLICY "admin_manage_story_groups" ON public.story_groups FOR ALL USING (public.get_my_role() = 'super_admin');
CREATE POLICY "admin_manage_story_items" ON public.story_items FOR ALL USING (public.get_my_role() = 'super_admin');
CREATE POLICY "admin_manage_push" ON public.push_notifications FOR ALL USING (public.get_my_role() = 'super_admin');
