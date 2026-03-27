---
name: repo-onboarding
description: understand a software repository before making changes. use when the agent needs to inspect project structure, identify the stack and tooling, find commands, detect architecture conventions, and summarize how to work safely in the codebase.
---

Inspect the repository before writing or changing code.

Always:
1. Identify the language, framework, runtime, package manager, and test framework.
2. Locate the main source folders, entrypoints, config files, scripts, test folders, and relevant docs.
3. Find the commands for install, dev, build, lint, test, typecheck, and format when available.
4. Summarize the architecture style, module boundaries, naming conventions, and patterns that should be preserved.
5. Point out risky areas before making changes, including generated files, migrations, environment-dependent code, and external integrations.
6. End with the safest recommended next step.

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
- Stack
- Project structure
- Main commands
- Conventions
- Risks
- Recommended next step

Do not start implementing changes until the repository is understood.
