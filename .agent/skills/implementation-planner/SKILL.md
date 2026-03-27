---
name: implementation-planner
description: create a safe implementation plan before editing code. use when the agent needs to decide what files to touch, what components or functions to add or change, how to avoid regressions, and how to validate the result.
---

Create an implementation plan before coding.

Always:
1. Identify the files likely involved.
2. Explain what changes belong in each file.
3. Separate business logic, data access, API, and UI concerns when relevant.
4. Consider validation, error handling, migrations, observability, and tests.
5. Minimize scope and avoid unrelated changes.
6. Define how the result will be validated before editing.

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
- Files to inspect
- Planned changes
- Edge cases
- Tests to add
- Validation checklist

Prefer simple, maintainable changes over clever solutions.
