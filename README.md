# Salta Rubik

Salta Rubik is a Flutter speedcubing timer with sessions, WCA-style scrambles, statistics, scramble preview, and compete mode.

The app remains mobile-first, but the repo now also supports Flutter Web so the same product can be deployed to Railway without changing the current Android UI flow.

This repository now also contains a separate backend foundation under [backend/](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/backend) for future account-backed sessions, solves, and sync. The mobile app still remains local-first.

## Stack

- Flutter
- `flutter_bloc`
- `get_it`
- local-first persistence
  - Android/mobile: `sqflite`
  - Web: browser `localStorage`

## Project structure

- `lib/core`: shared constants and helpers
- `lib/data`: persistence and repository implementations
- `lib/domain`: entities, repositories, and use cases
- `lib/presentation`: pages, widgets, theme, and blocs

## Local validation

```powershell
dart pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
```

Notes:
- On this Windows environment, `dart pub get` works without requiring Developer Mode.
- `flutter analyze` still reports a set of older repo warnings unrelated to the web bootstrap work.

## Railway deployment

Railway can deploy this repo directly from GitHub using the root [Dockerfile](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/Dockerfile).

What the container does:
- builds the app with `flutter build web --release`
- serves `build/web` through Caddy
- falls back to `index.html` for client-side navigation
- listens on Railway's `PORT` via [deploy/Caddyfile](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/deploy/Caddyfile)

High-level Railway steps:
1. Create a new Railway project and connect this GitHub repo.
2. Let Railway detect the root `Dockerfile`.
3. Deploy the service.
4. In Railway Networking, generate a public domain.

Railway references used for this setup:
- Dockerfiles: https://docs.railway.com/deploy/dockerfiles
- Static hosting guide: https://docs.railway.com/guides/static-hosting
- Public networking / `PORT`: https://docs.railway.com/public-networking

## Backend API foundation

There is now a separate backend service in [backend/](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/backend) built with:

- Fastify
- Prisma ORM
- PostgreSQL

It is meant to be deployed as its own Railway service with:

- service 1: Flutter web frontend
- service 2: backend API
- service 3: PostgreSQL

Backend deploy notes:

- use `backend/Dockerfile` as the service Dockerfile path
- provide `DATABASE_URL` from Railway PostgreSQL
- keep the Flutter client local-first until auth/sync is explicitly integrated

The backend is also prepared for optional WCA OAuth linking later. This should be used as an extra identity provider, not as the only login path for Salta Rubik.

Current auth direction:

- WCA OAuth is handled by the backend, not directly by Flutter clients
- the backend issues its own bearer token after successful WCA login
- the same backend flow is designed to work for both web redirects and future mobile deep links

## Current web scope

This first web slice is intentionally narrow:
- the app boots and builds for web
- browser persistence keeps sessions and solves after refresh
- Android keeps its current UI and storage path

Not included yet:
- login
- remote sync
- shared cloud-backed sessions between devices

Those next steps are already tracked in `lib/TODO.TXT` under the web epics.
