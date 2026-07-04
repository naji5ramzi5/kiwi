-- ============================================================
-- Fresh Project - RLS Policies Update
-- Run this AFTER the seed data to ensure proper authentication
-- ============================================================

-- ─── Enable RLS on all tables ───────────────────────────────
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.driver_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.invoices ENABLE ROW LEVEL SECURITY;

-- ─── Profiles ──────────────────────────────────────────────
-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can create their own profile (during signup)
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Admins can manage all profiles
CREATE POLICY "Admins can manage all profiles"
  ON public.profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- ─── Driver Profiles ───────────────────────────────────────
DROP POLICY IF EXISTS "Drivers can view own driver profile" ON public.driver_profiles;
DROP POLICY IF EXISTS "Drivers can insert own driver profile" ON public.driver_profiles;
DROP POLICY IF EXISTS "Drivers can update own driver profile" ON public.driver_profiles;
DROP POLICY IF EXISTS "Admins can view all driver profiles" ON public.driver_profiles;

CREATE POLICY "Drivers can view own driver profile"
  ON public.driver_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Drivers can insert own driver profile"
  ON public.driver_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Drivers can update own driver profile"
  ON public.driver_profiles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all driver profiles"
  ON public.driver_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- ─── Inventory ─────────────────────────────────────────────
DROP POLICY IF EXISTS "Anyone can view inventory" ON public.inventory;
DROP POLICY IF EXISTS "Branch managers can update inventory" ON public.inventory;

CREATE POLICY "Anyone can view inventory"
  ON public.inventory FOR SELECT
  USING (true);

CREATE POLICY "Branch managers can update inventory"
  ON public.inventory FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'branch_manager')
    )
  );

-- ─── FCM Tokens ────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can manage own FCM tokens" ON public.user_fcm_tokens;

CREATE POLICY "Users can manage own FCM tokens"
  ON public.user_fcm_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── Disable email confirmation (allow immediate signup) ───
-- Run in Supabase Dashboard: Authentication → Settings → 
-- Disable "Confirm email" toggle under Email Auth provider
-- OR execute:
-- UPDATE auth.users SET email_confirmed_at = NOW() WHERE email_confirmed_at IS NULL;
