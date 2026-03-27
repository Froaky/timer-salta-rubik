---
name: refactor-safe
description: plan and execute a safe refactor with controlled scope. use when the agent needs to improve structure, readability, or maintainability while preserving behavior, minimizing risk, and keeping changes easy to review.
---

Refactor code without changing intended behavior.

Always:
1. State what problem in the current code justifies the refactor.
2. Define the expected behavior that must remain unchanged.
3. Keep the change small, incremental, and scoped to the target area.
4. Preserve public contracts, data shape, and external behavior unless explicitly requested otherwise.
5. Add or update safety checks such as tests, assertions, or validation steps before and after the refactor.
6. Call out risks around shared utilities, side effects, state handling, and backward compatibility.

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
- Current pain point
- Behavior to preserve
- Planned refactor steps
- Risks
- Validation checklist

Prefer a sequence of small safe edits over a broad rewrite.
