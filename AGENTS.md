# Salta Rubik Codex Rules

## Project context

- This repository is a Flutter speedcubing timer app with session management, WCA scrambles, statistics, compete mode, and authentication work in progress.
- The codebase follows a layered structure under `lib/`: `core`, `data`, `domain`, and `presentation`.
- State management uses `flutter_bloc`.
- Dependency injection is wired manually in `lib/injection_container.dart` with `get_it`.
- Local persistence uses `sqflite`; Firebase packages exist in `pubspec.yaml` but local data flow is still central to the app.
- Tests live under `test/domain`, `test/presentation`, and `test/support`.
- Current product backlog is tracked in `lib/TODO.TXT`.
- `README.md` is still boilerplate; if setup, architecture, or product behavior changes, update it.

## Working rules

- Understand the target feature area before editing code.
- Preserve the current layer boundaries unless the task explicitly asks for architectural change.
- Keep domain entities and use cases free of Flutter and UI dependencies.
- Put persistence details in `data/`, app rules in `domain/`, and UI orchestration in `presentation/`.
- Keep pages focused on composition and flow; move reusable UI into widgets and stateful behavior into BLoCs or use cases when practical.
- Follow the existing naming style: nouns for entities, verb-oriented use cases, `*Bloc` / `*Event` / `*State` triplets, and `copyWith` for immutable state updates.
- Update `lib/injection_container.dart` whenever a new data source, repository, use case, or BLoC is introduced.
- Prefer extending existing patterns over introducing a new state-management or architecture style.
- Ask before adding a new production dependency unless it is clearly required and low risk.
- Do not edit generated platform plugin registrant files manually. They should only change as a consequence of dependency changes.

## Domain guardrails

- Preserve timer state semantics: `idle`, `holdPending`, `armed`, `inspection`, `running`, `stopped`.
- Preserve competition restrictions: active compete-mode solves should block access to views that the app already protects.
- Preserve session-specific behavior: changing session or cube type should keep solves, statistics, and scramble generation aligned to the active session.
- Preserve solve semantics: penalties are `none`, `plus2`, and `dnf`; `lane` uses `0` for single and `1-2` for compete lanes.
- Preserve statistics refresh after solve mutations such as add, update, or delete.
- Preserve null safety and existing Equatable-based value semantics.

## Validation

- Run `dart format lib test` after code changes when formatting is needed.
- Run `flutter analyze`.
- Run `flutter test`.
- Run `flutter pub get` when dependencies or assets change.
- If a completed task maps to an item in `lib/TODO.TXT`, update that backlog note.

## Suggested skills

- Use `repo-onboarding` when entering an unfamiliar package, feature area, or flow.
- Use `task-decomposer` for any non-trivial feature, bugfix, refactor, or migration.
- Use `implementation-planner` before editing code to decide scope, files, tests, and validation.
- Use `flutter-bloc-feature` when implementing or changing features in the current architecture.
- Use `timer-domain-safety` when touching timer, session, scramble, statistics, penalties, or compete mode.
- Use `backlog-finisher` when working from `lib/TODO.TXT` or trying to close product gaps.
- Use `test-writer` when behavior changes or regressions are possible.
- Use `refactor-safe` for structure improvements that must preserve behavior.
- Use `docs-sync` when commands, setup, workflows, or behavior change.
- Use `code-quality` when evaluating maintainability, abstractions, naming, and SOLID-style tradeoffs.
