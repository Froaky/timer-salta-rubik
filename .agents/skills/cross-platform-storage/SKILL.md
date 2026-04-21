---
name: cross-platform-storage
description: design and implement platform-safe local persistence for this repository across Android and web. use when the work involves replacing direct sqflite assumptions, creating storage abstractions, keeping session/solve/stat behavior identical across platforms, or preparing the app for browser-compatible persistence.
---

Separate app behavior from storage technology.

Always:
1. Read `CONTEXT.md` and inspect the current solve/session persistence flow before proposing changes.
2. Preserve repository and domain contracts while swapping or abstracting storage details.
3. Keep Android on its stable storage path unless there is a strong reason to migrate it.
4. Introduce the smallest abstraction that cleanly supports mobile and web.
5. Preserve solve semantics: penalties, lane values, session alignment, scramble alignment, and stats refresh after mutations.
6. Add tests at the repository or datasource contract level when persistence behavior changes.

Storage design rules:
- Put platform-specific persistence in `data/`.
- Keep use cases and entities unaware of the storage backend.
- Avoid leaking browser storage details into BLoCs or pages.
- Prefer explicit interfaces for operations that already exist in the app instead of generic CRUD abstractions with no domain shape.
- If eventual remote sync is planned, keep local IDs, timestamps, and mutation semantics stable enough to map later.

Safe decomposition:
1. Identify the current persistence contract actually used by the app.
2. Define the minimum interface needed for cross-platform support.
3. Keep existing Android implementation behind that interface.
4. Add a browser-safe implementation.
5. Wire platform selection in DI, not in feature widgets.
6. Prove parity with focused tests and manual validation notes.

Danger areas:
- Session changes desynchronizing solves, scrambles, or stats.
- Inconsistent sort/order semantics between storage engines.
- Timestamp or ID handling that later blocks sync.
- Silent data loss on browser refresh.

Use `references/storage-guardrails.md` for repo-specific invariants and schema concerns.

Output format:
- Goal
- Current persistence path
- Abstraction boundary
- Platform implementations
- Risks to preserve
- Tests to add
- Validation notes

Prefer one stable storage seam over a broad persistence rewrite.
