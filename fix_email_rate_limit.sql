-- ==============================================
-- FIX: Disable email confirmation to avoid rate limits
-- ==============================================
-- Run this in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/pftjlvtdzokbzuioqfug/sql/new

-- Option 1: Try to update auth config (may require super user)
UPDATE auth.config
SET
  enable_confirmations = false,
  security_update_password_require_reauthentication = false
WHERE id = (SELECT id FROM auth.config LIMIT 1);

-- Option 2: Disable the email rate limiter
UPDATE auth.config
SET
  smtp_max_frequency = 0,
  rate_limit_anon_email = 10000
WHERE id = (SELECT id FROM auth.config LIMIT 1);

-- Option 3: If above fails, create a trigger-based bypass
CREATE OR REPLACE FUNCTION auth.handle_new_user()
RETURNS trigger AS $$
BEGIN
  UPDATE auth.users SET confirmed_at = now() WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Automatically confirm users on signup
DROP TRIGGER IF EXISTS auto_confirm_user ON auth.users;
CREATE TRIGGER auto_confirm_user
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION auth.handle_new_user();
