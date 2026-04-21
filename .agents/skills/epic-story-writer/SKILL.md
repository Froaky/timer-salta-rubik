---
name: epic-story-writer
description: create epics, user stories, acceptance criteria, and ordered backlog slices for product work in this repository. use when the user wants to turn a feature idea, bug report, tester feedback, launch checklist, or vague product request into structured epics or implementation-ready user stories.
---

Turn product asks into backlog items that are small, testable, and aligned with this app.

Always:
1. Read `CONTEXT.md` and `lib/TODO.TXT` before proposing new epics or stories.
2. Ground every story in current product reality: timer flows, sessions, scrambles, statistics, compete mode, and Play Store launch work.
3. Decide whether the request is best expressed as an epic, a user story, a fix story, or a launch/task item.
4. Prefer thin vertical slices over broad "build everything" stories.
5. Write user stories in the format `Como <persona>, quiero <capacidad>, para <valor>`.
6. Add observable acceptance criteria, not implementation guesses.
7. Call out guardrails when the work could affect timer precision, session alignment, scramble correctness, solve persistence, or compete restrictions.
8. State assumptions explicitly when the ask is vague instead of blocking on missing detail.

How to structure the backlog:
- Create an epic when the work spans multiple user outcomes or would need several independently shippable stories.
- Create a single story when one user-visible outcome can be delivered and validated on its own.
- Create a fix story when the input is a bug, regression, or tester complaint tied to broken current behavior.
- Create launch items when the work is operational or store-release oriented rather than a runtime user feature.

How to slice stories well:
- Keep one user outcome per story.
- Split by workflow step, user surface, or risk boundary.
- Separate admin/setup/release work from end-user product behavior.
- Do not hide major unknowns inside one oversized story.
- If a request touches multiple risky areas, suggest an implementation order.

Quality bar for good stories:
- Persona is real for this app: speedcuber, competidor, usuario casual, tester, maintainer, release owner.
- Value is explicit and user-facing.
- Acceptance criteria can be tested manually or with focused automated coverage.
- Dependencies and non-goals are named when they matter.
- Story wording stays product-facing; technical notes go below the story, not inside it.

For bug-driven stories:
- Describe the broken behavior and expected behavior separately.
- Preserve existing invariants from `CONTEXT.md`.
- Include at least one regression check.

For Play Store or release work:
- Prefer checklist-style stories/tasks with clear done criteria.
- Separate compliance, listing assets, signing, QA, and rollout into distinct items when they can move independently.

Read `references/story-patterns.md` when you need templates or examples for feature, fix, and launch stories.

Output format:
- Request framing
- Epic
- Stories
- Acceptance criteria
- Risks and guardrails
- Suggested delivery order
- Open assumptions

Prefer fewer strong stories over a long list of vague backlog filler.
