-- Pairing, part 2 (PRD F1): join a couple space with an invite code.
--
-- Error names raised (in addition to those in create_couple/create_invite):
--   invalid_invite    no such code
--   invite_used       the code was already used (codes are single-use)
--   invite_expired    the code is older than 7 days
--   own_invite        the caller is already a member of that couple
--   has_empty_space   the caller created their own space and is alone in it;
--                     call again with leave_empty_space => true to replace it
--   already_in_couple the caller is paired with someone else
--   couple_full       the couple already has two members

create function public.join_couple(
  invite_code text,
  leave_empty_space boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  normalized_code text := upper(regexp_replace(coalesce(invite_code, ''), '[^A-Za-z0-9]', '', 'g'));
  invite public.invites%rowtype;
  current_couple_id uuid;
begin
  if caller is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  -- Lock the invite so it cannot be redeemed twice concurrently.
  select * into invite
  from public.invites i
  where i.code = normalized_code
  for update;

  if not found then
    raise exception 'invalid_invite' using errcode = '22023';
  end if;
  if invite.used_at is not null then
    raise exception 'invite_used' using errcode = '22023';
  end if;
  if invite.expires_at <= now() then
    raise exception 'invite_expired' using errcode = '22023';
  end if;

  select m.couple_id into current_couple_id
  from public.couple_members m
  where m.user_id = caller;

  if current_couple_id = invite.couple_id then
    raise exception 'own_invite' using errcode = '22023';
  end if;

  -- Lock the target couple before counting its members.
  perform 1 from public.couples c where c.id = invite.couple_id for update;
  if (select count(*) from public.couple_members m where m.couple_id = invite.couple_id) >= 2 then
    raise exception 'couple_full' using errcode = '23514';
  end if;

  if current_couple_id is not null then
    perform 1 from public.couples c where c.id = current_couple_id for update;
    if (select count(*) from public.couple_members m where m.couple_id = current_couple_id) > 1 then
      raise exception 'already_in_couple' using errcode = '23505';
    end if;
    if not leave_empty_space then
      raise exception 'has_empty_space' using errcode = '23505';
    end if;
    -- Both partners created a space: drop the caller's solo one (PRD F1 edge
    -- case). Cascades to its membership, invites and any solo content.
    delete from public.couples c where c.id = current_couple_id;
  end if;

  begin
    insert into public.couple_members (couple_id, user_id)
    values (invite.couple_id, caller);
  exception
    when unique_violation then
      raise exception 'already_in_couple' using errcode = '23505';
    when check_violation then
      raise exception 'couple_full' using errcode = '23514';
  end;

  update public.invites i set used_at = now() where i.code = invite.code;

  return invite.couple_id;
end;
$$;

revoke all on function public.join_couple(text, boolean) from public, anon;
grant execute on function public.join_couple(text, boolean) to authenticated;
