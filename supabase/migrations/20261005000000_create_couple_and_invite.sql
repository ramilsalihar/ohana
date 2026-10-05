-- Pairing, part 1 (PRD F1): create a couple space and generate an invite code.
--
-- Clients cannot write to couples, couple_members or invites directly; these
-- functions are the only way in. Both derive the user from the session.
--
-- Errors are raised with a stable machine-readable message so the app can map
-- them: not_authenticated, already_in_couple, invalid_timezone, not_in_couple,
-- couple_full.

-- Six characters from an alphabet without look-alikes (no 0/O, 1/I/L).
-- Randomness comes from gen_random_uuid(), which uses the server's strong
-- random source; only its fully random leading bytes are used.
create function private.generate_invite_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  bytes bytea := uuid_send(gen_random_uuid());
  code text := '';
begin
  for i in 0..5 loop
    code := code || substr(alphabet, 1 + get_byte(bytes, i) % length(alphabet), 1);
  end loop;
  return code;
end;
$$;

-- Creates a couple with the caller as its first member and returns its id.
create function public.create_couple(couple_timezone text default 'UTC')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  new_couple_id uuid;
begin
  if caller is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  if not exists (select 1 from pg_catalog.pg_timezone_names where name = couple_timezone) then
    raise exception 'invalid_timezone' using errcode = '22023';
  end if;

  if exists (select 1 from public.couple_members where user_id = caller) then
    raise exception 'already_in_couple' using errcode = '23505';
  end if;

  insert into public.couples (timezone)
  values (couple_timezone)
  returning id into new_couple_id;

  begin
    insert into public.couple_members (couple_id, user_id)
    values (new_couple_id, caller);
  exception when unique_violation then
    -- Lost a race with another create/join by the same user.
    raise exception 'already_in_couple' using errcode = '23505';
  end;

  return new_couple_id;
end;
$$;

-- Returns the invite for the caller's couple: the still-valid one if there is
-- one, otherwise a new code that expires in 7 days. A code becomes used (and
-- so single-use) when the partner joins with it.
create function public.create_invite()
returns table (code text, expires_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  caller_couple_id uuid;
  new_code text;
begin
  if caller is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select m.couple_id into caller_couple_id
  from public.couple_members m
  where m.user_id = caller;

  if caller_couple_id is null then
    raise exception 'not_in_couple' using errcode = '42501';
  end if;

  -- Serialize per couple so two calls cannot both create an invite.
  perform 1 from public.couples c where c.id = caller_couple_id for update;

  if (select count(*) from public.couple_members m where m.couple_id = caller_couple_id) >= 2 then
    raise exception 'couple_full' using errcode = '23514';
  end if;

  return query
    select i.code, i.expires_at
    from public.invites i
    where i.couple_id = caller_couple_id
      and i.used_at is null
      and i.expires_at > now()
    order by i.expires_at desc
    limit 1;
  if found then
    return;
  end if;

  for attempt in 1..5 loop
    new_code := private.generate_invite_code();
    begin
      return query
        insert into public.invites as i (code, couple_id, created_by)
        values (new_code, caller_couple_id, caller)
        returning i.code, i.expires_at;
      return;
    exception when unique_violation then
      -- Code already exists; try another.
    end;
  end loop;

  raise exception 'could not generate a unique invite code';
end;
$$;

revoke all on function private.generate_invite_code() from public;
revoke all on function public.create_couple(text) from public, anon;
revoke all on function public.create_invite() from public, anon;
grant execute on function public.create_couple(text) to authenticated;
grant execute on function public.create_invite() to authenticated;
