-- ═══════════════════════════════════════════════════════════
-- FRESH SYSTEM — DATABASE COMPLETENESS & COMPATIBILITY PATCH
-- ═══════════════════════════════════════════════════════════
-- Copy and paste this script into Supabase SQL Editor and run it.
-- It will safely create all missing tables, missing columns,
-- and establish correct RLS policies and seed values.
-- ═══════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────
-- 1. ADD MISSING COLUMNS TO EXISTING TABLES (SAFELY)
-- ───────────────────────────────────────────────────────────

-- Profiles Table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Branches Table
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS access_code TEXT;
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS delivery_zones JSONB DEFAULT '[]'::jsonb;

-- Orders Table
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS proof_image TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_fee NUMERIC DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'كاش';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS order_type TEXT DEFAULT 'app';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS customer_name_manual TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_address TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS driver_id UUID;

-- Categories Table
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS name_en TEXT;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;


-- ───────────────────────────────────────────────────────────
-- 2. CREATE MISSING TABLES
-- ───────────────────────────────────────────────────────────

-- A. Audit Logs Table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id),
  action_type VARCHAR(50) NOT NULL, -- stock_edit, price_override, void_order
  description TEXT,
  severity VARCHAR(20) DEFAULT 'info', -- info, warning, critical
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- B. Shift Closings Table
CREATE TABLE IF NOT EXISTS public.shift_closings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  manager_id UUID REFERENCES public.profiles(id),
  expected_cash DECIMAL(12, 2) NOT NULL,
  actual_cash DECIMAL(12, 2) NOT NULL,
  difference DECIMAL(12, 2) GENERATED ALWAYS AS (actual_cash - expected_cash) STORED,
  notes TEXT,
  status VARCHAR(20) DEFAULT 'closed',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- C. Admin Notifications Table
CREATE TABLE IF NOT EXISTS public.admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'admin_note', -- admin_note, stock_alert, policy_update
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- D. System Settings Table
CREATE TABLE IF NOT EXISTS public.system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(100) UNIQUE NOT NULL,
  value_decimal NUMERIC NOT NULL DEFAULT 0.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- E. Partner Settlements Table
CREATE TABLE IF NOT EXISTS public.partner_settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  total_revenue NUMERIC NOT NULL DEFAULT 0,
  dev_profit NUMERIC NOT NULL DEFAULT 0,
  maintenance_fund NUMERIC NOT NULL DEFAULT 0,
  branch_profit NUMERIC NOT NULL DEFAULT 0,
  is_settled BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- F. Discount Codes Table
CREATE TABLE IF NOT EXISTS public.discount_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) UNIQUE NOT NULL,
  discount_amount NUMERIC NOT NULL,
  type VARCHAR(20) DEFAULT 'percent', -- 'percent', 'fixed'
  max_uses INTEGER DEFAULT 100,
  used_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  min_order_amount NUMERIC,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- G. Notifications Table (For edge function and app notifications)
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'general',
  data JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- H. User FCM Tokens Table (To ensure compatibility with code references)
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    token TEXT NOT NULL UNIQUE,
    device_type TEXT NOT NULL CHECK (device_type IN ('web', 'android', 'ios')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- ───────────────────────────────────────────────────────────
-- 3. ROW LEVEL SECURITY (RLS) POLICIES & HELPER FUNCTIONS
-- ───────────────────────────────────────────────────────────

-- Enable RLS on new tables
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_closings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discount_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Helper Functions (Safely check roles and branch settings)
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.get_my_branch_id()
RETURNS UUID AS $$
  SELECT branch_id FROM public.profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Drop old policies to prevent collision
DROP POLICY IF EXISTS "system_settings_read" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_write" ON public.system_settings;
DROP POLICY IF EXISTS "partner_settlements_all" ON public.partner_settlements;
DROP POLICY IF EXISTS "discount_codes_read" ON public.discount_codes;
DROP POLICY IF EXISTS "discount_codes_write" ON public.discount_codes;
DROP POLICY IF EXISTS "notifications_own" ON public.notifications;
DROP POLICY IF EXISTS "user_fcm_tokens_manage" ON public.user_fcm_tokens;

-- Create Policies
-- System Settings
CREATE POLICY "system_settings_read" ON public.system_settings FOR SELECT USING (true);
CREATE POLICY "system_settings_write" ON public.system_settings FOR ALL USING (public.get_my_role() = 'super_admin');

-- Partner Settlements
CREATE POLICY "partner_settlements_all" ON public.partner_settlements FOR ALL USING (public.get_my_role() = 'super_admin');

-- Discount Codes
CREATE POLICY "discount_codes_read" ON public.discount_codes FOR SELECT USING (is_active = true);
CREATE POLICY "discount_codes_write" ON public.discount_codes FOR ALL USING (public.get_my_role() = 'super_admin');

-- Notifications
CREATE POLICY "notifications_own" ON public.notifications FOR ALL USING (user_id = auth.uid());

-- User FCM Tokens
CREATE POLICY "user_fcm_tokens_manage" ON public.user_fcm_tokens FOR ALL USING (user_id = auth.uid());


-- ───────────────────────────────────────────────────────────
-- 4. SEED REQUIRED DATA
-- ───────────────────────────────────────────────────────────

-- Add Default System Settings (Partnership Ratios)
INSERT INTO public.system_settings (key, value_decimal)
VALUES 
  ('dev_partner_ratio', 0.35),
  ('system_maintenance_ratio', 0.10)
ON CONFLICT (key) DO UPDATE 
SET value_decimal = EXCLUDED.value_decimal;
