---
name: backlog-finisher
description: finish product backlog items in this repository by turning pending TODOs into small, testable implementation slices. use when the task comes from lib/TODO.TXT or when the goal is to close remaining app gaps without losing focus or quality.
---

Close backlog items in a controlled way.

Always:
1. Read the relevant item from `lib/TODO.TXT` and restate it as a concrete acceptance goal.
2. Identify the minimum vertical slice needed to ship the change.
3. Map the work to the affected layers and files.
4. Call out regressions that could affect timer flow, sessions, statistics, or compete mode.
5. Add or update tests that prove the backlog item is actually complete.
6. Update `lib/TODO.TXT` when the task is finished or when scope needs to be clarified.

Output format:
- Backlog item
- Acceptance goal
- Minimal slice
- Files to inspect
- Risks
- Done criteria

Prefer closing one backlog item cleanly over partially touching several.
