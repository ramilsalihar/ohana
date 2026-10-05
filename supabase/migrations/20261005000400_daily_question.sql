-- Daily question assignment (PRD F2).
--
-- One question per couple per day. The "day" rolls over at 04:00 in the
-- couple's time zone, so a question answered at 01:00 still belongs to the
-- previous day. Questions are assigned lazily, the first time either partner
-- asks for today's question; no scheduler is needed for correctness.

-- The question date for a couple in time zone `tz` at instant `at`.
-- An unknown zone falls back to UTC rather than failing.
create function private.question_date(tz text, at timestamptz default now())
returns date
language sql
stable
set search_path = ''
as $$
  select (
    (at at time zone coalesce(
      (select name from pg_catalog.pg_timezone_names where name = tz),
      'UTC'
    )) - interval '4 hours'
  )::date;
$$;

-- Returns today's question for the caller's couple, assigning one if needed.
--
-- Selection: a random question the couple has not had yet. Once every
-- question has been used, the one they saw longest ago comes round again.
-- All relationship stages are eligible (the couple has no stage setting yet).
create function public.get_daily_question()
returns table (question_date date, question_id uuid, text text, category text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  caller_couple_id uuid;
  couple_timezone text;
  today date;
  chosen uuid;
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

  -- Lock the couple so both partners opening the app at once get the same
  -- question.
  select c.timezone into couple_timezone
  from public.couples c
  where c.id = caller_couple_id
  for update;

  today := private.question_date(couple_timezone);

  if not exists (
    select 1 from public.daily_questions d
    where d.couple_id = caller_couple_id and d.date = today
  ) then
    select q.id into chosen
    from public.questions q
    where not exists (
      select 1 from public.daily_questions d
      where d.couple_id = caller_couple_id and d.question_id = q.id
    )
    order by random()
    limit 1;

    if chosen is null then
      select d.question_id into chosen
      from public.daily_questions d
      where d.couple_id = caller_couple_id
      group by d.question_id
      order by max(d.date), random()
      limit 1;
    end if;

    if chosen is null then
      raise exception 'no_questions' using errcode = 'P0002';
    end if;

    insert into public.daily_questions (couple_id, date, question_id)
    values (caller_couple_id, today, chosen)
    on conflict (couple_id, date) do nothing;
  end if;

  return query
    select d.date, q.id, q.text, q.category
    from public.daily_questions d
    join public.questions q on q.id = d.question_id
    where d.couple_id = caller_couple_id and d.date = today;
end;
$$;

revoke all on function private.question_date(text, timestamptz) from public;
revoke all on function public.get_daily_question() from public, anon;
grant execute on function public.get_daily_question() to authenticated;
