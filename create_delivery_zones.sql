
-- ========================================================
-- FRESH ENTERPRISE SYSTEM - CREATE DELIVERY ZONES TABLE
-- قم بنسخ هذا الكود وتشغيله في محرّر SQL في لوحة Supabase
-- ========================================================

CREATE TABLE IF NOT EXISTS public.delivery_zones (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT DEFAULT '#10b981',
    delivery_fee INTEGER DEFAULT 0,
    min_order INTEGER DEFAULT 0,
    max_delivery_time INTEGER DEFAULT 45,
    is_active BOOLEAN DEFAULT true,
    geojson JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- إعداد قواعد الحماية (RLS)
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "الجميع يمكنهم قراءة مناطق التوصيل" ON public.delivery_zones
    FOR SELECT USING (true);

CREATE POLICY "المدراء يمكنهم التعديل على المناطق" ON public.delivery_zones
    FOR ALL USING (true) WITH CHECK (true);

-- إشعار Supabase بإعادة تحميل الهيكل
NOTIFY pgrst, 'reload schema';
