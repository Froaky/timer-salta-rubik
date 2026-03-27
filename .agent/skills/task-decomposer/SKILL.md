---
name: task-decomposer
description: break a software development request into clear implementation steps. use when the agent receives a feature, bugfix, refactor, migration, or technical task that should be split into ordered subtasks with dependencies and risks.
---

Break the task into actionable steps before implementation.

Always:
1. Restate the goal in one sentence.
2. Split the work into small ordered subtasks.
3. Identify dependencies between subtasks and note what can happen in parallel.
4. Mention edge cases, failure modes, and scope risks.
5. Keep the plan focused on the requested change and avoid unrelated cleanup.
6. End with a recommended implementation order.

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
- Assumptions
- Subtasks
- Dependencies
- Risks
- Suggested order
