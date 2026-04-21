# Storage Guardrails

## Current invariants to preserve

- Solve data stays aligned to the active `sessionId`.
- Session changes refresh the visible solves, scramble, and stats together.
- Penalties remain `none`, `plus2`, and `dnf`.
- `lane` remains `0` for single and `1-2` for compete mode.
- Stats refresh after add, update, and delete.

## Storage questions to answer early

- Which entities need stable IDs across local and future remote storage?
- Which timestamps exist today and which will later need conflict handling?
- Is current ordering derived from insertion time, stored fields, or query ordering?
- Which values are nullable today and would cause trouble when serialized for web or sync?

## Good seam candidates

- datasource interfaces used by repositories
- repository constructor wiring in `lib/injection_container.dart`
- serialization code closest to the storage engine

## Bad seam candidates

- widget-level `kIsWeb` branching
- domain entities carrying browser-only or SQL-specific metadata
- mixing local-storage migration logic into presentation BLoCs
