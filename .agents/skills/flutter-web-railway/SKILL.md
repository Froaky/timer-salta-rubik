---
name: flutter-web-railway
description: plan and implement Flutter Web support and Railway deployment for this repository without breaking the existing Android app. use when the work involves browser compatibility, web entry/runtime constraints, release build/deploy flow, environment configuration, or safe platform gating for the current mobile-first app.
---

Enable web as a first-class runtime while preserving the current mobile product.

Always:
1. Read `CONTEXT.md`, `lib/TODO.TXT`, `pubspec.yaml`, `lib/main.dart`, and any current platform-specific persistence wiring before changing code.
2. Preserve Android behavior and UI unless the task explicitly asks for a cross-platform redesign.
3. Treat web enablement, deployment, and browser persistence as separate concerns even if they are implemented in sequence.
4. Check whether any package or API used in mobile is incompatible with Flutter Web before proposing structural changes.
5. Prefer platform adapters and capability checks over `kIsWeb` scattered through feature code.
6. Keep timer semantics, session alignment, scramble generation, penalties, and compete restrictions identical across platforms.
7. Leave a deploy path that is reproducible: build command, start behavior, env assumptions, and validation steps.

Workflow:
1. Confirm the minimum web outcome:
   - app boots in browser,
   - core timer flows render,
   - local persistence works on web,
   - Railway can serve the built app.
2. Inventory platform blockers:
   - storage,
   - plugins,
   - file/path assumptions,
   - routing/refresh behavior,
   - environment variables,
   - service worker or asset loading issues.
3. Decide the safest thin slice:
   - runtime compatibility first,
   - deployment second,
   - polish later.
4. Add focused tests or validation notes for the exact risky change.
5. Document the build/deploy contract once the path is stable.

Platform guardrails:
- Do not force mobile UI compromises just to make web work.
- Do not change timer gesture semantics to fit desktop/web unless explicitly requested.
- Do not bind domain logic to Railway-specific concepts.
- Do not make web deploy depend on future auth/sync work.

Railway guardrails:
- Prefer static hosting of the Flutter Web build unless a real backend need exists.
- Keep configuration explicit: build command, output directory, and any headers/rewrites needed.
- Call out what must exist in Railway versus what stays in the repo.

Use `references/deploy-checklist.md` for the practical checklist and validation order.

Output format:
- Goal
- Current blockers
- Proposed thin slice
- Files to inspect or change
- Platform risks
- Deploy notes
- Validation plan

Prefer getting one stable web deploy path working over prematurely solving every future backend concern.
