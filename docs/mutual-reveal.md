# Mutual reveal

How the daily question keeps each partner's answer hidden until both have answered ([PRD F2](prd.md#f2-daily-question-with-mutual-reveal-p0)). The rule is enforced in Postgres, not in the app.

## The rule

> A partner's answer is never returned by the API before the requesting user has answered the same question.

## How it is enforced

Two layers, both in `supabase/migrations/`:

1. **Table access (`answers` RLS).** A user can only `SELECT` their own rows in `answers`. There is no policy that lets a client read a partner's row directly, revealed or not.
2. **`get_partner_answer(question_date date)`.** The only way a partner's answer leaves the database. It returns the partner's row only when the caller already has an answer for that date.

Because the table never exposes partner rows, a bug or a modified client cannot bypass the reveal rule by querying `answers` directly.

## `get_partner_answer`

| | |
|---|---|
| Signature | `public.get_partner_answer(question_date date) returns setof answers` |
| Callable by | `authenticated` only (`anon` has no execute permission) |
| Runs as | `SECURITY DEFINER`, with an empty `search_path` |

**Returns**

- **One row** — the partner's answer (`id`, `couple_id`, `daily_question_date`, `user_id`, `body`, `created_at`, `updated_at`) when both partners have answered that date.
- **No rows** in every other case: the caller has not answered, the partner has not answered, the caller is not in a couple, or the caller has left the couple.

"No rows" deliberately does not say *why*. To show "Waiting for partner…", the client reads its own answer from `answers`; if it exists and the RPC returns nothing, the partner has not answered yet.

**Why there is no `couple_id` or `user_id` parameter:** the couple and the caller are derived from the session (`auth.uid()`), so the function cannot be aimed at someone else's couple.

### Calling it from Flutter

```dart
final rows = await supabase.rpc(
  'get_partner_answer',
  params: {'question_date': '2026-10-04'},
);
final partnerAnswer = rows.isEmpty ? null : rows.first;
```

## Related rules in the schema

- **Edit lock:** an answer can be updated (body only) until the partner answers; after that the update policy matches no rows.
- **Reactions:** `answer_reactions` can only be inserted or read for answers whose question both partners have answered.
- **Check-ins** follow the same table rule (author-only `SELECT`). Their reveal function ships with the weekly check-in feature.

## Verified behaviour

Checked by running the migrations on Postgres and calling the function as different users:

| Situation | Result |
|---|---|
| Caller has not answered, partner has | no rows |
| Caller has answered, partner has not | no rows |
| Both answered | partner's answer |
| Caller answered a different day only | no rows for the unanswered day |
| Member of another couple | never sees this couple's answers |
| Signed-out (`anon`) | permission denied |
| Caller no longer a member of the couple | no rows |

These checks were run locally against PGlite with a stubbed `auth` schema; they are not yet part of CI.
