---
name: docs-sync
description: keep essential project documentation aligned with code changes. use when the agent changes behavior, commands, setup, configuration, APIs, or workflows and needs to update only the documentation that helps future developers and operators.
---

Update the minimum useful documentation after code changes.

Always:
1. Identify which docs are affected by the change: README, setup, deployment, API notes, runbooks, or inline docs.
2. Update only the sections made inaccurate or incomplete by the change.
3. Prefer short concrete instructions, commands, and constraints over long narrative text.
4. Note behavioral changes, new commands, new configuration, and migration or rollback considerations when relevant.
5. Keep docs consistent with actual code, file names, and command names.
6. Skip redundant documentation when the change is obvious from code and not useful to future readers.

Programming best practices:
- readability over cleverness
- consistency over personal preference
- small focused functions
- descriptive names
- single responsibility where practical
- avoid duplication
- validate external inputs
- handle errors explicitly
- avoid hidden side effects
- do not change unrelated code
- add or update tests when behavior changes
- document only what is useful and non-obvious

Output format:
- Goal
- Docs to inspect
- Required updates
- Commands or examples to refresh
- Risks if docs stay stale

Prefer concise maintenance-focused documentation over broad rewrites.
