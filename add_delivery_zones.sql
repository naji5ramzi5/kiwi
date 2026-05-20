-- ========================================================
-- FRESH ENTERPRISE SYSTEM - ADD DELIVERY ZONES COLUMN
-- قم بنسخ هذا الكود وتشغيله في محرّر SQL في لوحة Supabase
-- ========================================================

ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS delivery_zones JSONB DEFAULT '[]'::jsonb;

-- إشعار Supabase بإعادة تحميل الهيكل (Reload Schema Cache)
NOTIFY pgrst, 'reload schema';
