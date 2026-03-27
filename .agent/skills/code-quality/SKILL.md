---
name: code-quality
description: apply software design and code quality principles when planning, implementing, or reviewing changes. use when the agent needs to reason about maintainability, cohesion, coupling, responsibilities, abstractions, and practical principles such as SOLID, KISS, DRY, and YAGNI.
---

Use practical engineering principles to improve code quality without overengineering.

Always:
1. Evaluate whether the current design has unclear responsibilities, excessive coupling, duplication, hidden side effects, or confusing names.
2. Apply SOLID where it improves maintainability, especially single responsibility, dependency direction, and stable interfaces.
3. Balance SOLID with KISS, DRY, and YAGNI. Do not add abstractions, layers, or indirection without a concrete benefit.
4. Prefer small focused functions, explicit data flow, and descriptive names over clever patterns.
5. Preserve the project's established style unless there is a clear technical reason to change it.
6. Explain tradeoffs briefly and recommend the simplest design that solves the actual problem.

Good defaults:
- readability over cleverness
- consistency over personal preference
- small focused functions
- descriptive names
- single responsibility where practical
- low coupling and high cohesion
- avoid duplication, but not by forcing the wrong abstraction
- validate external inputs
- handle errors explicitly
- avoid hidden side effects
- do not change unrelated code
- add or update tests when behavior changes
- document only what is useful and non-obvious

Output format:
- Goal
- Current quality concerns
- Principles that matter here
- Recommended design direction
- Risks of overengineering
- Validation notes

Prefer simple maintainable code over theoretical purity.
