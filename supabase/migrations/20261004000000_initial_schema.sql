-- Ohana MVP schema (PRD §8) with Row Level Security.
--
-- Access model
--   * Every couple-scoped table is readable only by the members of that couple.
--   * Unrevealed content (answers, check-ins) is readable only by its author.
--     Partner content is exposed through reveal RPCs, never by table SELECT.
--   * Tables with no INSERT/UPDATE/DELETE policy for a role are write-protected
--     for that role. Couple creation, invite creation and joining go through
--     SECURITY DEFINER functions (added with the pairing feature); question
--     rotation and cleanup run as the service role.

-- Helpers used by policies live outside the API-exposed `public` schema.
create schema if not exists private;
grant usage on schema private to authenticated;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text check (char_length(display_name) between 1 and 50),
  avatar_url   text,
  timezone     text not null default 'UTC',
  created_at   timestamptz not null default now()
);

create table public.couples (
  id             uuid primary key default gen_random_uuid(),
  together_since date,
  timezone       text not null default 'UTC',
  -- Local time of the "new daily question" notification. The question itself
  -- rotates at 04:00 in `timezone`.
  question_time  time not null default '09:00',
  created_at     timestamptz not null default now()
);

create table public.couple_members (
  couple_id uuid not null references public.couples (id) on delete cascade,
  user_id   uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (couple_id, user_id),
  -- A user belongs to at most one couple.
  unique (user_id)
);

create table public.invites (
  code       text primary key check (code ~ '^[A-Z0-9]{6}$'),
  couple_id  uuid not null references public.couples (id) on delete cascade,
  created_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '7 days',
  used_at    timestamptz
);
create index invites_couple_id_idx on public.invites (couple_id);

create table public.questions (
  id       uuid primary key default gen_random_uuid(),
  text     text not null,
  category text not null
    check (category in ('fun', 'deep', 'future', 'memories', 'intimacy-light')),
  stage    text not null default 'any'
    check (stage in ('dating', 'long-term', 'any'))
);

create table public.daily_questions (
  couple_id   uuid not null references public.couples (id) on delete cascade,
  date        date not null,
  question_id uuid not null references public.questions (id),
  primary key (couple_id, date)
);

create table public.answers (
  id                  uuid primary key default gen_random_uuid(),
  couple_id           uuid not null,
  daily_question_date date not null,
  user_id             uuid not null references auth.users (id) on delete cascade,
  body                text not null check (char_length(body) between 1 and 500),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  foreign key (couple_id, daily_question_date)
    references public.daily_questions (couple_id, date) on delete cascade,
  unique (couple_id, daily_question_date, user_id)
);
create index answers_user_id_idx on public.answers (user_id);

create table public.answer_reactions (
  answer_id  uuid not null references public.answers (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  emoji      text check (char_length(emoji) between 1 and 16),
  comment    text check (char_length(comment) between 1 and 280),
  created_at timestamptz not null default now(),
  primary key (answer_id, user_id),
  check (emoji is not null or comment is not null)
);

create table public.appreciations (
  id         uuid primary key default gen_random_uuid(),
  couple_id  uuid not null references public.couples (id) on delete cascade,
  from_user  uuid not null references auth.users (id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 280),
  favorited  boolean not null default false,
  created_at timestamptz not null default now()
);
create index appreciations_couple_created_idx
  on public.appreciations (couple_id, created_at desc);

create table public.checkins (
  id            uuid primary key default gen_random_uuid(),
  couple_id     uuid not null references public.couples (id) on delete cascade,
  user_id       uuid not null references auth.users (id) on delete cascade,
  week_start    date not null,
  connection    smallint not null check (connection between 1 and 5),
  communication smallint not null check (communication between 1 and 5),
  fun           smallint not null check (fun between 1 and 5),
  support       smallint not null check (support between 1 and 5),
  note          text check (char_length(note) <= 500),
  created_at    timestamptz not null default now(),
  unique (couple_id, user_id, week_start)
);

create table public.important_dates (
  id            uuid primary key default gen_random_uuid(),
  couple_id     uuid not null references public.couples (id) on delete cascade,
  title         text not null check (char_length(title) between 1 and 80),
  date          date not null,
  kind          text not null default 'custom'
    check (kind in ('birthday', 'anniversary', 'first_date', 'custom')),
  recurs_yearly boolean not null default true,
  created_at    timestamptz not null default now()
);
create index important_dates_couple_id_idx on public.important_dates (couple_id);

-- Positive actions only (PRD F4). Rows are hidden after 48 hours by RLS and
-- removed by a scheduled cleanup.
create table public.activity (
  id         uuid primary key default gen_random_uuid(),
  couple_id  uuid not null references public.couples (id) on delete cascade,
  actor_id   uuid not null references auth.users (id) on delete cascade,
  type       text not null
    check (type in ('answered', 'reacted', 'sent_note', 'completed_checkin')),
  ref_id     uuid,
  created_at timestamptz not null default now()
);
create index activity_couple_created_idx
  on public.activity (couple_id, created_at desc);

create table public.push_tokens (
  user_id    uuid not null references auth.users (id) on delete cascade,
  token      text not null,
  platform   text not null check (platform in ('ios', 'android')),
  created_at timestamptz not null default now(),
  primary key (user_id, token)
);

-- ---------------------------------------------------------------------------
-- Integrity triggers
-- ---------------------------------------------------------------------------

-- A couple has at most 2 members. The couple row is locked so that two
-- concurrent joins cannot both pass the count check.
create function private.enforce_couple_size()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  perform 1 from public.couples where id = new.couple_id for update;
  if (select count(*) from public.couple_members where couple_id = new.couple_id) >= 2 then
    raise exception 'couple % already has two members', new.couple_id
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger couple_members_max_two
  before insert on public.couple_members
  for each row execute function private.enforce_couple_size();

create function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger answers_touch_updated_at
  before update on public.answers
  for each row execute function private.touch_updated_at();

-- ---------------------------------------------------------------------------
-- Policy helpers
--
-- SECURITY DEFINER so they can read membership/answers without recursing into
-- the RLS policies that call them. Each one only answers a yes/no question
-- about the calling user.
-- ---------------------------------------------------------------------------

create function private.is_couple_member(target_couple_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.couple_members
    where couple_id = target_couple_id
      and user_id = (select auth.uid())
  );
$$;

create function private.is_partner(target_user_id uuid)
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
      and them.user_id = target_user_id
      and them.user_id <> me.user_id
  );
$$;

-- True once both partners have answered the couple's question for that day.
create function private.is_revealed(target_couple_id uuid, target_date date)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_couple_member(target_couple_id)
    and (
      select count(*)
      from public.answers
      where couple_id = target_couple_id
        and daily_question_date = target_date
    ) >= 2;
$$;

-- True when the answer belongs to the caller's couple and has been revealed.
create function private.is_revealed_answer(target_answer_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select private.is_revealed(couple_id, daily_question_date)
      from public.answers
      where id = target_answer_id
    ),
    false
  );
$$;

revoke all on all functions in schema private from public;
grant execute on function
  private.is_couple_member(uuid),
  private.is_partner(uuid),
  private.is_revealed(uuid, date),
  private.is_revealed_answer(uuid)
to authenticated;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.profiles         enable row level security;
alter table public.couples          enable row level security;
alter table public.couple_members   enable row level security;
alter table public.invites          enable row level security;
alter table public.questions        enable row level security;
alter table public.daily_questions  enable row level security;
alter table public.answers          enable row level security;
alter table public.answer_reactions enable row level security;
alter table public.appreciations    enable row level security;
alter table public.checkins         enable row level security;
alter table public.important_dates  enable row level security;
alter table public.activity         enable row level security;
alter table public.push_tokens      enable row level security;

-- Nothing is available to signed-out clients.
revoke all on all tables in schema public from anon;

-- profiles: your own and your partner's; you can only write your own.
create policy profiles_select on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or private.is_partner(id));

create policy profiles_insert on public.profiles
  for insert to authenticated
  with check (id = (select auth.uid()));

create policy profiles_update on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- couples: members read and edit settings. Created via RPC.
create policy couples_select on public.couples
  for select to authenticated
  using (private.is_couple_member(id));

create policy couples_update on public.couples
  for update to authenticated
  using (private.is_couple_member(id))
  with check (private.is_couple_member(id));

revoke update on public.couples from authenticated;
grant update (together_since, timezone, question_time)
  on public.couples to authenticated;

-- couple_members: members see who is in their couple. Joined via RPC.
create policy couple_members_select on public.couple_members
  for select to authenticated
  using (private.is_couple_member(couple_id));

-- invites: members see their couple's invites. Created and redeemed via RPC.
create policy invites_select on public.invites
  for select to authenticated
  using (private.is_couple_member(couple_id));

-- questions: the bank is readable by any signed-in user, written by service role.
create policy questions_select on public.questions
  for select to authenticated
  using (true);

-- daily_questions: members read; rotation is done by the service role.
create policy daily_questions_select on public.daily_questions
  for select to authenticated
  using (private.is_couple_member(couple_id));

-- answers: you can only ever SELECT your own rows. The partner's answer is
-- returned by the mutual-reveal RPC after you have answered.
create policy answers_select_own on public.answers
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy answers_insert_own on public.answers
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and private.is_couple_member(couple_id)
  );

-- Editable until the partner answers; locked once revealed.
create policy answers_update_own on public.answers
  for update to authenticated
  using (
    user_id = (select auth.uid())
    and not private.is_revealed(couple_id, daily_question_date)
  )
  with check (user_id = (select auth.uid()));

revoke update on public.answers from authenticated;
grant update (body) on public.answers to authenticated;

-- answer_reactions: only on revealed answers in your couple.
create policy answer_reactions_select on public.answer_reactions
  for select to authenticated
  using (private.is_revealed_answer(answer_id));

create policy answer_reactions_insert on public.answer_reactions
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and private.is_revealed_answer(answer_id)
  );

create policy answer_reactions_update on public.answer_reactions
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and private.is_revealed_answer(answer_id)
  );

create policy answer_reactions_delete on public.answer_reactions
  for delete to authenticated
  using (user_id = (select auth.uid()));

revoke update on public.answer_reactions from authenticated;
grant update (emoji, comment) on public.answer_reactions to authenticated;

-- appreciations: visible to the couple. The sender can delete for 5 minutes;
-- only the recipient can favorite.
create policy appreciations_select on public.appreciations
  for select to authenticated
  using (private.is_couple_member(couple_id));

create policy appreciations_insert on public.appreciations
  for insert to authenticated
  with check (
    from_user = (select auth.uid())
    and private.is_couple_member(couple_id)
    and favorited = false
  );

create policy appreciations_favorite on public.appreciations
  for update to authenticated
  using (
    private.is_couple_member(couple_id)
    and from_user <> (select auth.uid())
  )
  with check (
    private.is_couple_member(couple_id)
    and from_user <> (select auth.uid())
  );

create policy appreciations_delete_recent on public.appreciations
  for delete to authenticated
  using (
    from_user = (select auth.uid())
    and created_at > now() - interval '5 minutes'
  );

revoke update on public.appreciations from authenticated;
grant update (favorited) on public.appreciations to authenticated;

-- checkins: you can only SELECT your own. Partner ratings are exposed by a
-- reveal RPC once both have submitted (added with the check-in feature).
create policy checkins_select_own on public.checkins
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy checkins_insert_own on public.checkins
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and private.is_couple_member(couple_id)
  );

-- important_dates: shared; either partner can add, edit or delete.
create policy important_dates_select on public.important_dates
  for select to authenticated
  using (private.is_couple_member(couple_id));

create policy important_dates_insert on public.important_dates
  for insert to authenticated
  with check (private.is_couple_member(couple_id));

create policy important_dates_update on public.important_dates
  for update to authenticated
  using (private.is_couple_member(couple_id))
  with check (private.is_couple_member(couple_id));

create policy important_dates_delete on public.important_dates
  for delete to authenticated
  using (private.is_couple_member(couple_id));

-- activity: members see the last 48 hours; you can only log your own actions.
create policy activity_select on public.activity
  for select to authenticated
  using (
    private.is_couple_member(couple_id)
    and created_at > now() - interval '48 hours'
  );

create policy activity_insert on public.activity
  for insert to authenticated
  with check (
    actor_id = (select auth.uid())
    and private.is_couple_member(couple_id)
  );

-- push_tokens: private to the owner.
create policy push_tokens_all on public.push_tokens
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
