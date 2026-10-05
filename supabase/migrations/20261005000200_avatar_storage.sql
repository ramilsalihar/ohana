-- Profile avatars (PRD F1).
--
-- Private bucket: a photo is readable only by its owner and their partner.
-- Objects live at `<user id>/<file name>`, and a user can only write inside
-- their own folder. `profiles.avatar_url` stores that object path; the app
-- turns it into a short-lived signed URL when it needs to show the image.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  false,
  2097152, -- 2 MB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- True when `folder` is the user id of the caller's partner. Takes text so a
-- malformed object name can never raise a cast error inside a policy.
create function private.is_partner_folder(folder text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.couple_members me
    join public.couple_members them on them.couple_id = me.couple_id
    where me.user_id = (select auth.uid())
      and them.user_id <> me.user_id
      and them.user_id::text = folder
  );
$$;

revoke all on function private.is_partner_folder(text) from public;
grant execute on function private.is_partner_folder(text) to authenticated;

create policy avatars_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or private.is_partner_folder((storage.foldername(name))[1])
    )
  );

create policy avatars_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy avatars_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy avatars_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
