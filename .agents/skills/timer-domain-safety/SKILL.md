---
name: timer-domain-safety
description: protect app-specific timer and solving behavior while making changes. use when the task touches timer state transitions, solve recording, session switching, scramble generation, statistics, penalties, compete mode, or related UI restrictions.
---

Preserve the core behavior of the timer app while implementing changes.

Always:
1. Identify which user-visible timer behaviors must remain unchanged.
2. Check interactions between timer state, active session, scramble generation, solve saving, and statistics refresh.
3. Preserve penalty semantics: `none`, `plus2`, and `dnf`.
4. Preserve compete-mode guardrails and lane semantics.
5. Preserve session-aware loading behavior when sessions or cube types change.
6. Add focused regression coverage for the risky path you touched.

Behaviors to protect:
- Timer state flow between hold, inspection, run, stop, and reset.
- Scramble generation aligned to the current session cube type.
- Solve persistence aligned to the active session.
- Statistics refresh after add, update, and delete operations.
- Restrictions that block unsafe UI access during active compete-mode solves.

Output format:
- Goal
- Behavior to preserve
- Risky interactions
- Regression checks
- Tests to add
- Validation notes

Prefer explicit guardrails and small targeted changes over broad timer rewrites.
