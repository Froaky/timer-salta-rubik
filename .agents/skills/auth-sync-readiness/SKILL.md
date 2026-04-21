---
name: auth-sync-readiness
description: shape and implement the foundations for account-backed data and future sync in this repository without breaking current local-first behavior. use when the work involves login prerequisites, remote identity for sessions/solves, migration from local-only data, sync rules, or web/mobile parity for user-owned history and statistics.
---

Prepare the app for account-aware data without coupling everything to auth too early.

Always:
1. Read `CONTEXT.md`, `lib/TODO.TXT`, and the current local solve/session flow before proposing account or sync changes.
2. Separate three concerns:
   - authentication,
   - remote data model,
   - sync behavior.
3. Preserve the local-first experience until remote sync is explicitly shipped.
4. Keep future web/mobile parity in scope: a signed-in user should later see the same sessions, solves, and stats on both platforms.
5. Prefer additive foundations such as stable IDs, ownership fields, and migration hooks over a big-bang replacement of local storage.
6. Surface conflict rules and offline assumptions instead of hiding them.

Foundational questions:
- What identifies a user-owned session across devices?
- What identifies a solve across local and remote systems?
- How will legacy local-only data be attached to an account?
- What happens when the same logical data changes in two places?
- Which stats are derived and should be recomputed versus stored remotely?

Safe rollout order:
1. Stabilize local data shape for future sync.
2. Introduce account ownership concepts without requiring sync everywhere.
3. Define migration/linking behavior for existing local users.
4. Define remote read model for sessions, solves, and stats.
5. Implement sync later with explicit conflict handling.

Guardrails:
- Do not make login a prerequisite for the existing mobile timer unless explicitly requested.
- Do not store derived stats remotely if they can be recomputed consistently from solves.
- Do not let remote sync alter timer precision or compete-mode guardrails.
- Do not design IDs or timestamps in a way that blocks merge/import later.

Use `references/sync-decisions.md` for the minimum architectural questions that should be answered before coding sync.

Output format:
- Goal
- Current local behavior
- Foundation to add now
- Deferred decisions
- Risks and invariants
- Migration notes
- Suggested next slice

Prefer making the future possible over partially shipping a fragile sync layer.
