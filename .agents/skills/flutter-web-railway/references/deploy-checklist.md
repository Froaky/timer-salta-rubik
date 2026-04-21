# Flutter Web + Railway Checklist

## Minimum viability

- Flutter app builds for web.
- Browser opens the app without crashing on startup.
- Core screens render without mobile-only plugin failures.
- Local data storage works in browser.
- Railway can serve the generated build reliably.

## Inspection checklist

- `pubspec.yaml`
  - detect plugins that are mobile-only or require web alternatives
- `lib/main.dart`
  - inspect app boot path and early initialization
- `lib/injection_container.dart`
  - inspect data source wiring for platform assumptions
- `lib/data/datasources/*`
  - look for `sqflite`, file-system, or path-provider dependencies
- `web/`
  - inspect web bootstrap, manifest, icons, and hosting assumptions

## Safe rollout order

1. Make app boot in browser.
2. Replace or abstract incompatible persistence.
3. Confirm timer/session/stats behavior parity.
4. Add Railway deploy files or config.
5. Smoke test production build in browser.

## Validation prompts

- Does the app load on hard refresh?
- Can a new session be created and selected?
- Can a solve be added and reloaded after refresh?
- Do scramble generation and stats still work?
- Did Android behavior remain unchanged?
