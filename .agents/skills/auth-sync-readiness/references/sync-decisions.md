# Sync Decisions

## Decide before implementation

- Will session IDs be client-generated, server-generated, or both?
- Will solve IDs be globally unique from creation time?
- Which timestamps are authoritative for ordering and conflict resolution?
- What is the merge rule when a signed-in user already has local sessions?
- Can anonymous local use continue after auth ships?

## Recommended biases for this repo

- Keep anonymous local use working.
- Add stable IDs locally before remote sync is built.
- Keep stats derived from solve data.
- Sync sessions and solves first; defer secondary features until the base is trustworthy.
- Make migration explicit rather than silently overwriting local data.

## Data shape reminders

- sessions, solves, penalties, cube type, and lane semantics must stay consistent
- scramble-history alignment matters when reviewing past solves
- stats should match mobile and web from the same underlying solve set
