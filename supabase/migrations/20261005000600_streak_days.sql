-- Gentle streak (PRD F2): the data the app needs to count the couple's streak.
--
-- Returns the couple's current question date and the recent days on which
-- BOTH partners answered. It deliberately carries no per-person information,
-- so the app cannot show who missed a day. A day counts whenever both answers
-- exist, including ones written late from history (no penalty for lateness).
-- The freeze-day rule is applied in the app, where it is unit tested.

create function public.get_streak_days(window_days integer default 1000)
returns table (today date, completed_dates date[])
language sql
stable
security definer
set search_path = ''
as $$
  select
    private.question_date(c.timezone),
    coalesce(
      (
        select array_agg(day order by day)
        from (
          select a.daily_question_date as day
          from public.answers a
          where a.couple_id = c.id
            and a.daily_question_date
                >= private.question_date(c.timezone) - least(greatest(window_days, 1), 3650)
          group by a.daily_question_date
          having count(distinct a.user_id) >= 2
        ) both_answered
      ),
      '{}'::date[]
    )
  from public.couple_members m
  join public.couples c on c.id = m.couple_id
  where m.user_id = (select auth.uid());
$$;

revoke all on function public.get_streak_days(integer) from public, anon;
grant execute on function public.get_streak_days(integer) to authenticated;
