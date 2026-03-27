---
name: flutter-bloc-feature
description: implement or modify a feature in this Flutter repository using the current layered architecture, flutter_bloc state management, get_it dependency wiring, and the existing testing patterns. use when the task touches lib/core, lib/data, lib/domain, lib/presentation, or feature flow across these layers.
---

Implement Flutter features in the style already used by this repository.

Always:
1. Identify which layers are affected: `presentation`, `domain`, `data`, `core`.
2. Reuse existing BLoC, entity, use case, repository, and datasource patterns before introducing new abstractions.
3. Keep business rules in use cases or domain entities, not inside pages or widgets.
4. Keep pages focused on screen composition and interaction flow; extract reusable or dense UI into widgets.
5. Update `lib/injection_container.dart` when adding or changing dependencies.
6. Add or update tests at the smallest useful level: entity, use case, bloc, widget, or page.

Project-specific checks:
- Prefer `flutter_bloc`, `Equatable`, and `copyWith` patterns already present in the repo.
- Respect null safety and current linting.
- Avoid bypassing repositories or datasources from the UI layer.
- When touching storage flows, inspect `lib/data/datasources/local_database.dart` and related repository implementations.
- When touching UI flows, inspect existing BLoCs and widget tests before changing behavior.

Output format:
- Goal
- Affected layers
- Files to inspect
- Planned changes
- Tests to add
- Validation commands

Prefer consistent vertical slices over broad cross-repo rewrites.
