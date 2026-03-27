---
name: test-writer
description: design and add tests for software changes. use when the agent needs to identify behaviors to verify, choose the right test level, add or update tests, and validate expected and edge-case behavior without overtesting implementation details.
---

Add or update tests for the requested change.

Always:
1. Identify the user-visible or contract-level behavior that must be verified.
2. Choose the smallest effective test level: unit, integration, API, widget, UI, or regression.
3. Reuse existing test patterns, fixtures, helpers, and naming conventions when available.
4. Cover success cases, failure cases, validation rules, and important edge cases.
5. Avoid brittle tests tied to incidental implementation details.
6. State how the tests should be executed and what they prove.

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
- Behavior to verify
- Test level
- Files to update
- Cases to cover
- Run commands

Prefer stable behavior-based tests over mock-heavy or overly coupled tests.
