# Build Plan

Ordered task list. Autopilot works top to bottom: the first unchecked `- [ ]` item is the next task.
Mark tasks done with `- [x]`. Tasks tagged **(HUMAN)** need the owner — skip work on them and report `BLOCKED:`.

Milestones follow [PRD §10](prd.md#10-release-plan).

## M0 — Foundations

- [x] Add core dependencies: `flutter_riverpod`, `go_router`, `supabase_flutter`; `flutter analyze` and `flutter test` pass
- [x] Feature-first folder structure: `lib/app/` (app, router, theme), `lib/core/` (config, utils), `lib/features/<feature>/{data,domain,presentation}/`; document it in README
- [x] Environment config: `.env.example` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`, load via `--dart-define-from-file`, typed `Env` class in `lib/core/config/`
- [x] Initialize Supabase in `main.dart`; app still boots (with a clear message) when env values are missing
- [x] Router: `go_router` with placeholder `/welcome` and `/home` routes, wired through Riverpod
- [x] Design tokens: color scheme (light + dark), typography scale, spacing constants in `lib/app/theme/`
- [x] Stricter lints in `analysis_options.yaml`; fix any findings
- [x] GitHub Actions CI: `flutter analyze` and `flutter test` on push and pull request
- [x] Database schema: `supabase/migrations/` SQL for the PRD §8 data model with Row Level Security policies (couple members only)
- [x] Mutual-reveal RPC: SQL function that returns the partner's answer only if the caller has answered; document in `docs/`
- [x] Create Supabase project and fill local `.env` **(HUMAN)**

## M1 — Pairing

- [x] Auth screens: Apple, Google, email magic link (UI + repository, behind an interface so it is testable)
- [ ] Create couple space + generate invite code (7-day expiry, single use)
- [ ] Join couple via code / deep link
- [ ] Profile setup: display name, avatar, "together since" date
- [ ] Home screen shell with together counter (F6)
