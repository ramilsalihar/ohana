# Ohana

A mobile app for couples — dating or married — to stay close and fight relationship drift through small daily rituals.

> Relationships rarely end from one explosion. They end from slow, invisible drift. Ohana makes care visible, every day, in about two minutes.

## Status

MVP planning. Flutter project initialized (iOS + Android); features not built yet.

## Getting started

```bash
flutter pub get
cp .env.example .env   # then fill in SUPABASE_URL and SUPABASE_ANON_KEY
flutter run --dart-define-from-file=.env
```

`.env` is gitignored. Values are compiled in at build time and read through the typed `Env` class in `lib/core/config/env.dart`.

Run checks:

```bash
flutter analyze
flutter test
```

## Project structure

Feature-first. Shared code lives in `app/` and `core/`; everything else belongs to a feature.

```
lib/
  main.dart
  app/                 # app shell
    app.dart           # root widget
    router/            # go_router configuration
    theme/             # color scheme, typography, spacing
  core/                # cross-feature code, no feature imports
    config/            # environment and app configuration
    utils/             # small shared helpers
  features/
    <feature>/
      data/            # repositories, Supabase data sources, DTOs
      domain/          # entities and business rules (no Flutter/Supabase imports)
      presentation/    # screens, widgets, Riverpod providers
```

Rules: features do not import each other's `data/` or `presentation/`; `core/` never imports from `features/`.

## Stack (planned)

- **Client:** Flutter (iOS + Android), native widgets via WidgetKit / Glance
- **Backend:** Supabase (Postgres, Auth, Realtime, Storage, Row Level Security)
- **Push:** FCM + APNs

## Docs

- [PRD (MVP)](docs/prd.md)
- [Mutual reveal: how answers stay hidden](docs/mutual-reveal.md)
- [Product vision & MVP](docs/product-vision.md)
- [Research: what matters in relationships](docs/research.md)
