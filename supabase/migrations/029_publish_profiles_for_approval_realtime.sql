-- 029_publish_profiles_for_approval_realtime.sql
-- The driver app's ApprovalWaitingScreen listens for realtime UPDATEs on
-- public.profiles (is_approved flip) via a postgres_changes subscription.
-- profiles was missing from the supabase_realtime publication, so approved
-- drivers never advanced past the waiting screen without restarting the app.
-- RLS still filters each subscriber's payloads (own_profile_select), so
-- publishing profiles only exposes each user's own row + staff rows.

ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
