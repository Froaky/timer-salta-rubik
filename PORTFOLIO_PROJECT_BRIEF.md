# Salta Rubik — Portfolio Project Brief

## Purpose

This document is meant to be passed to another agent or writing assistant so it can generate portfolio copy, case-study text, project summaries, landing-page blurbs, CV bullets, or interview explanations without inventing scope that the project does not actually have.

Use this file as the source of truth for how to present the project.

## Project Name

**Salta Rubik**

## One-line Summary

Salta Rubik is a speedcubing timer built with Flutter that combines WCA-style scrambles, session-based solve history, statistics, competition mode, web deployment, and an account-ready backend architecture.

## Recommended Positioning

This project should be presented as:

- a **product-oriented Flutter app**
- a **cross-platform engineering project**
- a **local-first app extended toward web + backend + auth**
- a **real UX/state-management problem**, not just a CRUD demo

It is stronger when described as a system that had to solve **timing precision**, **state correctness**, **cross-platform persistence**, **routing/auth edge cases**, and **deployability**, rather than as “just a timer app”.

## Short Description Options

### Very short

Salta Rubik is a Flutter speedcubing timer with WCA scrambles, sessions, statistics, competition mode, web support, and a backend foundation for account-backed sync.

### Portfolio card

Built a production-style Flutter speedcubing timer with session management, WCA-style scramble generation, statistics, competition mode, web deployment on Railway, and optional WCA-based authentication through a custom backend.

### Recruiter-friendly

A cross-platform Flutter project focused on precision interaction, structured architecture, and real deployment concerns: solve timing, session/history management, web compatibility, Railway hosting, and OAuth-based account readiness.

## Medium Description

Salta Rubik is a speedcubing timer app designed around real solving workflows rather than generic stopwatch behavior. It supports session-based solve history, WCA-style scrambles, statistics, competition mode, scramble preview, and web deployment, while preserving the current mobile experience.

The project uses a layered Flutter architecture with `flutter_bloc` and `get_it`, browser-safe local persistence for web, and a separate Fastify + Prisma + PostgreSQL backend prepared for account-backed sessions, solves, and future synchronization. It also integrates optional WCA OAuth through the backend, which required solving tricky routing and callback issues in Flutter Web.

## Long Description

Salta Rubik is a Flutter-based timer for speedcubing with a focus on correctness, responsiveness, and future extensibility. Instead of being a toy stopwatch app, it models real solve workflows: sessions, cube-type-specific scramble generation, solve penalties, statistics refresh, scramble preview, and versus/competition-style interactions.

On the frontend, the app is structured with explicit `core / data / domain / presentation` boundaries, `flutter_bloc` for UI state, and `get_it` for dependency injection. Persistence remains local-first, using SQLite on mobile and browser storage on web, so the app remains usable without an account.

On the platform side, the project was extended to Flutter Web and deployed through Railway without breaking the mobile UX. This required separating storage by platform, adding a web runtime path, and making client-side navigation work correctly in production.

On the backend side, the repository now includes a separate API foundation built with Fastify, Prisma, and PostgreSQL. That backend exposes session/solve resources, health checks, and optional WCA-based authentication. WCA OAuth is intentionally handled by the backend instead of directly by Flutter clients, so the app can use a first-party Salta Rubik token and remain ready for future sync across web and mobile.

One of the hardest parts of the project was not “adding auth” mechanically, but making the login flow actually work in deployed Flutter Web. The project had to solve callback routing, query-string parsing, browser navigation timing, CORS between frontend and backend Railway services, and state restoration after OAuth redirects.

The result is a project that demonstrates product thinking, UI/state rigor, deployment experience, auth integration, and practical architecture decisions under evolving requirements.

## What the Product Does

### Current user-facing capabilities

- solve timing workflow with hold / release behavior
- session management
- WCA-style scrambles for supported events
- solve history
- statistics and rolling averages
- competition / versus flow
- scramble preview
- Flutter Web deployment
- optional WCA login flow on web

### Current technical capabilities

- local-first persistence
- cross-platform storage strategy
- deployed frontend on Railway
- deployed backend on Railway
- PostgreSQL + Prisma foundation
- optional WCA OAuth handled server-side

## Core Features

- **Precise timer interaction**
  - supports hold-to-arm and release-to-start semantics
  - preserves exact stop timing semantics
  - avoids visual timing drift and stale-state gesture bugs

- **Sessions and history**
  - solves belong to sessions
  - session switching keeps history, statistics, and scramble generation aligned
  - solve list and statistics refresh after mutations

- **Scramble generation**
  - WCA-style scramble support
  - scramble preview rendering
  - bug fixes for event-specific notation edge cases

- **Competition mode**
  - separate flow from normal timing
  - active-round restrictions
  - scramble visibility rules
  - exact final time freezing before UI refresh

- **Web support**
  - Flutter Web build and deploy path
  - browser persistence
  - desktop/web interaction improvements
  - keyboard support for timer behavior in web/desktop mode

- **Auth + backend foundation**
  - Fastify + Prisma + PostgreSQL backend
  - REST endpoints for sessions and solves
  - WCA OAuth handled by backend
  - first-party app token returned to Flutter client

## Tech Stack

### Frontend

- Flutter
- Dart
- `flutter_bloc`
- `get_it`
- `sqflite`
- `shared_preferences`
- `http`
- `flutter_svg`
- `url_launcher`
- `cuber`

### Backend

- Node.js
- TypeScript
- Fastify
- Prisma ORM
- PostgreSQL

### Hosting / Deployment

- Railway
- Docker
- Caddy (for static web serving)

## Architecture

### Flutter app

The app follows a layered structure:

- `lib/core`
- `lib/data`
- `lib/domain`
- `lib/presentation`

This separation is important because the app is not a single-screen demo. It has:

- domain rules around solves and penalties
- feature flows that affect multiple layers
- multiple blocs with meaningful state transitions
- platform-specific persistence concerns

### Backend

The backend is intentionally separated from the Flutter app runtime:

- frontend service: Flutter Web
- API service: Fastify backend
- database service: PostgreSQL

That separation keeps the app local-first while still preparing for account-backed sync later.

## Key Engineering Challenges Solved

These are some of the strongest portfolio talking points.

### 1. Timing correctness under UI and rebuild pressure

This was not just “show a timer on screen”. The project had to preserve exact timing semantics while dealing with:

- gesture timing
- widget rebuild timing
- frame rendering drift
- stop-latching and display synchronization

Several bugs were fixed around:

- stale captured state in gesture handlers
- delayed start after hold/armed transitions
- extra centiseconds appearing on stop
- UI transitions interfering with gesture completion

### 2. Cross-platform persistence without breaking mobile

Web support was added without replacing the existing local-first mobile model.

That required:

- separating database access by platform
- keeping the repository/use-case layers stable
- using browser persistence on web
- preserving existing Android behavior

### 3. Real web deployment, not just “it builds locally”

The project was wired for Railway using:

- Flutter Web production build
- a root Dockerfile
- Caddy static hosting with SPA fallback

This made the project deployable as a real web app instead of staying as a local-only Flutter build.

### 4. OAuth in Flutter Web with a separate backend

The WCA login flow turned into a real engineering problem, not a checkbox feature.

The project had to solve:

- backend-managed OAuth
- secure redirect handling
- CORS between deployed frontend and backend
- callback URL parsing in Flutter Web
- query-string callback routing
- auth state restoration after redirect
- avoiding route fallbacks to `/` after callback

This is one of the strongest technical narratives in the repo.

## Why This Project Is Strong for a Portfolio

This project is useful in a portfolio because it demonstrates:

- mobile and web thinking in the same codebase
- layered architecture in Flutter
- practical state-management under real UX constraints
- non-trivial domain logic
- local-first product design
- backend/API readiness
- Railway deployment experience
- OAuth integration with a third-party identity provider
- debugging of real production-like issues

It is much stronger than a generic CRUD app because the interesting work is in:

- correctness
- behavior
- orchestration
- deployment
- auth
- edge-case handling

## Honest Current Status

This is the correct way to describe the project today.

### Accurate claims

- The app supports solve timing, sessions, statistics, scrambles, competition mode, and web deployment.
- The project has a separate backend foundation with Fastify, Prisma, and PostgreSQL.
- WCA login works as an optional provider direction for account-backed flows.
- The product is local-first and usable without forcing cloud sync.

### Things that should NOT be overstated

- Do **not** claim that full multi-device sync is complete.
- Do **not** claim that Play Store release is already done unless that happens later.
- Do **not** claim that mobile WCA login is fully closed if deep-link work is still pending.
- Do **not** claim that remote statistics are the source of truth; solves remain the correct source.

## Suggested Resume / Portfolio Bullet Points

### Version 1

- Built a Flutter speedcubing timer with session management, WCA-style scrambles, statistics, competition mode, and web deployment.
- Extended the app to Flutter Web without breaking the mobile local-first architecture by separating storage behavior per platform.
- Designed a backend foundation with Fastify, Prisma, and PostgreSQL to support account-backed sessions, solves, and future synchronization.
- Integrated backend-managed WCA OAuth for web and resolved real callback, routing, CORS, and session-restoration issues in production-style deployment.

### Version 2

- Developed a cross-platform Flutter app with structured architecture (`core/data/domain/presentation`), `flutter_bloc` state management, and deployable web support.
- Solved timing-accuracy and interaction bugs around hold-to-start / stop-latching behavior, reducing visual drift and stale-state issues in a real-time UI flow.
- Implemented Railway-ready frontend and backend services, including browser-compatible persistence and a Fastify + Prisma + PostgreSQL API base.

## Suggested Tags

- Flutter
- Dart
- Flutter Web
- Railway
- Fastify
- Prisma
- PostgreSQL
- OAuth
- WCA API
- BLoC
- Local-first
- Cross-platform
- State management
- Product engineering

## Suggested Screenshot / Demo Structure

If you show this project in a portfolio, the best order is:

1. Timer screen
2. Session and scramble area
3. Solve history / statistics
4. Competition mode
5. Web version running in browser
6. Auth/profile screen with WCA account

This tells a much better story than showing only the login page.

## Suggested “What I Learned” Angle

If the portfolio includes reflections, strong takeaways are:

- real-time UX is harder than it looks
- exact behavior matters more than just having a feature
- cross-platform support usually exposes hidden architectural assumptions
- auth in web apps is often a routing problem as much as a backend problem
- keeping a product local-first while making it account-ready leads to better long-term flexibility

## Agent Guardrails

If another agent uses this file to write portfolio content:

- keep the tone product-oriented and engineering-focused
- do not invent usage numbers, user metrics, or production scale
- do not claim finished sync if it is still roadmap work
- do not describe WCA as the only auth path; it is an optional provider direction
- emphasize debugging, correctness, deployment, and architecture over flashy buzzwords

## Recommended Final Framing

The best overall framing is:

> Salta Rubik is a real product-style Flutter project that grew from a timer app into a cross-platform system with domain-specific interaction logic, deployable web support, backend/API readiness, and a non-trivial OAuth integration.

