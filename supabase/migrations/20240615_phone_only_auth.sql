-- Make email nullable (optional) in profiles table
-- Phone is now the primary identifier

ALTER TABLE public.profiles
  ALTER COLUMN email DROP NOT NULL,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD CONSTRAINT profiles_phone_unique UNIQUE (phone);

-- Add phone column to auth.users metadata trigger
-- Ensure the handle_new_user trigger captures phone
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'phone', NEW.phone),
    COALESCE(NEW.raw_user_meta_data ->> 'role', 'customer')
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
    role = EXCLUDED.role;
  RETURN NEW;
END;
$$;
