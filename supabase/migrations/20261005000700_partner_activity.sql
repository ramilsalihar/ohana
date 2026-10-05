-- Partner activity (PRD F4): make the partner's effort visible.
--
-- Only positive actions are ever recorded (answered, reacted, and later:
-- sent a note, completed a check-in). There is nothing here about absence:
-- no last-seen, no read receipts, no "has not opened the app".
--
-- Rows are written by triggers, not by clients, so the feed cannot be faked
-- and cannot be turned into a general-purpose tracking log.

drop policy activity_insert on public.activity;

create function private.log_answer_activity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.activity (couple_id, actor_id, type, ref_id)
  values (new.couple_id, new.user_id, 'answered', new.id);
  return new;
end;
$$;

create trigger answers_log_activity
  after insert on public.answers
  for each row execute function private.log_answer_activity();

-- Logged once per reaction, when it is first left; later edits to the emoji
-- or comment do not add more entries.
create function private.log_reaction_activity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.activity (couple_id, actor_id, type, ref_id)
  select a.couple_id, new.user_id, 'reacted', a.id
  from public.answers a
  where a.id = new.answer_id;
  return new;
end;
$$;

create trigger answer_reactions_log_activity
  after insert on public.answer_reactions
  for each row execute function private.log_reaction_activity();

revoke all on function private.log_answer_activity() from public;
revoke all on function private.log_reaction_activity() from public;

-- The partner's positive actions from the last 48 hours, newest first.
-- Carries no answer content, and no timestamps beyond ordering: the app
-- shows what the partner did, not when they were last active.
create function public.get_partner_activity(max_rows integer default 20)
returns table (
  id uuid,
  type text,
  actor_name text,
  is_todays_question boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    act.id,
    act.type,
    p.display_name,
    coalesce(
      ans.daily_question_date = private.question_date(c.timezone),
      false
    )
  from public.couple_members me
  join public.couples c on c.id = me.couple_id
  join public.activity act
    on act.couple_id = me.couple_id
   and act.actor_id <> me.user_id
  -- Still a member: a former partner's actions are not shown.
  join public.couple_members actor
    on actor.couple_id = act.couple_id
   and actor.user_id = act.actor_id
  left join public.profiles p on p.id = act.actor_id
  left join public.answers ans
    on act.type = 'answered' and ans.id = act.ref_id
  where me.user_id = (select auth.uid())
    and act.created_at > now() - interval '48 hours'
  order by act.created_at desc, act.id
  limit least(greatest(max_rows, 1), 50);
$$;

revoke all on function public.get_partner_activity(integer) from public, anon;
grant execute on function public.get_partner_activity(integer) to authenticated;
