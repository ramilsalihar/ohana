-- Mutual reveal (PRD F2): the partner's answer to a daily question is returned
-- only after the caller has answered that same question.
--
-- The `answers` table itself only lets a user SELECT their own rows, so this
-- function is the single path by which a partner's answer leaves the database.
-- It takes no couple or user argument: both are derived from the caller's
-- session, so it cannot be pointed at another couple.

create function public.get_partner_answer(question_date date)
returns setof public.answers
language sql
stable
security definer
set search_path = ''
as $$
  select partner.*
  from public.answers mine
  join public.answers partner
    on partner.couple_id = mine.couple_id
   and partner.daily_question_date = mine.daily_question_date
   and partner.user_id <> mine.user_id
  -- Still a member: access ends as soon as the couple is unpaired.
  join public.couple_members membership
    on membership.couple_id = mine.couple_id
   and membership.user_id = mine.user_id
  where mine.user_id = (select auth.uid())
    and mine.daily_question_date = question_date;
$$;

comment on function public.get_partner_answer(date) is
  'Returns the partner''s answer for the given daily question date, or no rows '
  'if the caller has not answered it yet.';

revoke all on function public.get_partner_answer(date) from public, anon;
grant execute on function public.get_partner_answer(date) to authenticated;
