-- 026: drivers live-location upsert — driver may INSERT their own row
-- (the app upserts `drivers` every ~10s while online; without an INSERT
--  policy PostgREST blocked it and the ops map never received locations)
create policy "driver_own_insert"
  on public.drivers
  for insert
  to public
  with check (id = auth.uid());

-- Backfill profiles.email from auth user metadata for older accounts
-- that were created before the app wrote email into profiles.
update public.profiles p
   set email      = u.raw_user_meta_data->>'email',
       updated_at = now()
  from auth.users u
 where u.id = p.id
   and p.role = 'driver'
   and (p.email is null or p.email = '')
   and u.raw_user_meta_data is not null;