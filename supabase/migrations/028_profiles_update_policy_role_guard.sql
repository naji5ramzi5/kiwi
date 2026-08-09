-- 028_profiles_update_policy_role_guard.sql
-- Refines 027: the immediate replacement policy dropped the role-immutability
-- guard that the original (recursive) WITH CHECK enforced.
--
-- The guard is restored WITHOUT recursion by reusing public.get_my_role(),
-- which is SECURITY DEFINER (its internal profiles lookup bypasses RLS),
-- so evaluating it inside the policy cannot recurse.
--
-- Verified live:
--   • profile upsert right after signup: OK (was 42P17 infinite recursion)
--   • profile rename/phone/fcm_token updates: OK
--   • self role escalation (PATCH role='admin'): denied by RLS (42501)

DROP POLICY IF EXISTS own_profile_update ON public.profiles;

CREATE POLICY own_profile_update ON public.profiles
  FOR UPDATE TO public
  USING (id = auth.uid())
  WITH CHECK ((id = auth.uid()) AND (role = public.get_my_role()));
