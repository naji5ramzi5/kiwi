-- ============================================================
-- إنشاء حساب Admin في Supabase
-- شغّل هذا الأمر في Supabase SQL Editor
-- ============================================================

DO $$
DECLARE
  admin_id UUID;
  existing_id UUID;
BEGIN
  -- Check if admin already exists
  SELECT id INTO existing_id FROM auth.users WHERE email = 'admin@kiwi.iq';

  IF existing_id IS NULL THEN
    -- Create user in auth.users
    INSERT INTO auth.users (
      instance_id, id, aud, role,
      email, encrypted_password,
      email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, email_change,
      email_change_token_new, recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated', 'authenticated',
      'admin@kiwi.iq',
      crypt('Kiwi@2024', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"مدير النظام","role":"super_admin"}',
      now(), now(),
      '', '', '', ''
    )
    RETURNING id INTO admin_id;

    -- Create profile
    INSERT INTO public.profiles (id, full_name, phone, role)
    VALUES (admin_id, 'مدير النظام', '07700000000', 'super_admin')
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Admin user created successfully: admin@kiwi.iq';
  ELSE
    -- Update existing admin
    UPDATE auth.users SET
      encrypted_password = crypt('Kiwi@2024', gen_salt('bf')),
      email_confirmed_at = now(),
      raw_user_meta_data = '{"full_name":"مدير النظام","role":"super_admin"}'
    WHERE id = existing_id;

    INSERT INTO public.profiles (id, full_name, phone, role)
    VALUES (existing_id, 'مدير النظام', '07700000000', 'super_admin')
    ON CONFLICT (id) DO UPDATE SET
      full_name = 'مدير النظام', phone = '07700000000', role = 'super_admin';

    RAISE NOTICE 'Admin user updated: admin@kiwi.iq';
  END IF;
END $$;
