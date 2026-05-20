-- ==========================================
-- FCM Tokens Table - Firebase Cloud Messaging
-- أضف هذا في Supabase SQL Editor
-- ==========================================

CREATE TABLE IF NOT EXISTS public.fcm_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token TEXT NOT NULL UNIQUE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  platform VARCHAR(20) DEFAULT 'web', -- web, android, ios
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Super admin يرى كل الـ tokens
CREATE POLICY "super_admin_fcm" ON public.fcm_tokens
  FOR ALL USING (public.get_my_role() = 'super_admin');

-- كل مستخدم يدير token جهازه
CREATE POLICY "user_own_token" ON public.fcm_tokens
  FOR ALL USING (user_id = auth.uid() OR user_id IS NULL);

-- Index للبحث السريع
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user ON public.fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_platform ON public.fcm_tokens(platform);
