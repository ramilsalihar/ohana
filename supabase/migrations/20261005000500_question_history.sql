-- Daily question history (PRD F2): browse past questions; days the caller
-- has not answered stay answerable.

-- The couple's question for a given day, or no rows if none was assigned.
-- Unlike get_daily_question this never assigns anything.
create function public.get_question_on(question_date date)
returns table (question_date date, question_id uuid, text text, category text)
language sql
stable
security definer
set search_path = ''
as $$
  select d.date, q.id, q.text, q.category
  from public.couple_members m
  join public.daily_questions d on d.couple_id = m.couple_id
  join public.questions q on q.id = d.question_id
  where m.user_id = (select auth.uid())
    and d.date = get_question_on.question_date;
$$;

-- Past questions for the caller's couple, newest first, excluding today's.
--
-- `status` describes the caller's own position only:
--   unanswered  the caller has not answered that day
--   waiting     the caller answered; the partner has not
--   revealed    both answered
-- It never says the partner answered a day the caller has not, matching the
-- mutual-reveal rule.
create function public.get_question_history(max_rows integer default 90)
returns table (
  question_date date,
  question_id uuid,
  text text,
  category text,
  status text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    d.date,
    q.id,
    q.text,
    q.category,
    case
      when mine.id is null then 'unanswered'
      when exists (
        select 1 from public.answers theirs
        where theirs.couple_id = d.couple_id
          and theirs.daily_question_date = d.date
          and theirs.user_id <> m.user_id
      ) then 'revealed'
      else 'waiting'
    end
  from public.couple_members m
  join public.couples c on c.id = m.couple_id
  join public.daily_questions d on d.couple_id = m.couple_id
  join public.questions q on q.id = d.question_id
  left join public.answers mine
    on mine.couple_id = d.couple_id
   and mine.daily_question_date = d.date
   and mine.user_id = m.user_id
  where m.user_id = (select auth.uid())
    and d.date < private.question_date(c.timezone)
  order by d.date desc
  limit least(greatest(max_rows, 1), 365);
$$;

revoke all on function public.get_question_on(date) from public, anon;
revoke all on function public.get_question_history(integer) from public, anon;
grant execute on function public.get_question_on(date) to authenticated;
grant execute on function public.get_question_history(integer) to authenticated;
