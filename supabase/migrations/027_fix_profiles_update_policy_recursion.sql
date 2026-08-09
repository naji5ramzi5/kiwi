-- 027_fix_profiles_update_policy_recursion.sql
-- The old own_profile_update policy embedded a subquery on profiles
-- (SELECT p.role FROM profiles p WHERE p.id = auth.uid()) inside its
-- WITH CHECK. Postgres re-enters RLS evaluation for that subquery while
-- already inside the profiles policy check, producing:
--   ERROR: infinite recursion detected in policy for relation "profiles"
-- This silently killed:
--   - the profile upsert right after signup (catch swallowed the error),
--     so new accounts never got a profiles row,
--   - profile edits from the customer app.
-- The missing profiles row then caused FOREIGN KEY violations
-- (orders_customer_id_fkey, favorites_customer_id_fkey) on the customer app,
-- surfacing as checkout failure ("إعادة المحاولة") and broken favorites.
--
-- Fix: drop the recursive subquery; owners may update only their own row.

DROP POLICY IF EXISTS own_profile_update ON public.profiles;

CREATE POLICY own_profile_update ON public.profiles
  FOR UPDATE TO public
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());
