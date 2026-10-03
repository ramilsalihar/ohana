# Ohana

Flutter (iOS + Android) app for couples. Backend: Supabase. Product docs live in `docs/` — read `docs/prd.md` before building a feature.

## Commands

- `flutter pub get`
- `flutter analyze` — must report no issues
- `flutter test` — must pass

## Conventions

- Feature-first structure under `lib/features/<feature>/{data,domain,presentation}`
- State: Riverpod. Navigation: go_router.
- Never commit secrets. Supabase keys live in `.env` (gitignored); `.env.example` documents the names.
- Privacy rules from the PRD are requirements, not suggestions: mutual reveal is enforced server side, no partner surveillance features, no scorekeeping UI.

## Autopilot workflow

`docs/plan.md` is the ordered task list. When working through it (a Stop hook keeps you going while `.claude/autopilot.on` exists):

1. Take the **first unchecked** task only. One task per step — do not batch several.
2. Implement it with the smallest change that fully satisfies it. Add or update tests where logic exists.
3. Run `flutter analyze` and `flutter test`. Fix failures before moving on.
4. Tick the task (`- [x]`) in `docs/plan.md`.
5. Commit with a Conventional Commits message (code + plan tick in one commit), then `git push`.
6. End the step with a one-line summary of what was done.

Stop and write `BLOCKED: <reason>` (this ends autopilot) when:

- the task is tagged **(HUMAN)**, or needs credentials, accounts, payments, or a product decision not covered by the PRD;
- the same check fails after 3 honest fix attempts;
- the task would require deleting data, rewriting git history, or force-pushing.
