# Salta Rubik Backend

Backend API foundation for Salta Rubik using:

- Fastify
- Prisma ORM
- PostgreSQL

This service is intended to run separately from the Flutter web frontend. It exists to prepare:

- account-backed data,
- remote sessions and solves,
- future sync between web and mobile,
- and API ownership instead of exposing the database directly.

## Local setup

1. Copy `.env.example` to `.env`.
2. Point `DATABASE_URL` to a PostgreSQL database.
3. Install dependencies:

```powershell
npm install
```

4. Generate Prisma client and apply migrations:

```powershell
npm run prisma:generate
npm run prisma:migrate:deploy
```

5. Start the API:

```powershell
npm run dev
```

Default local port: `8081`

## Current endpoints

- `GET /health`
- `GET /api/v1/sessions`
- `POST /api/v1/sessions`
- `PATCH /api/v1/sessions/:id`
- `DELETE /api/v1/sessions/:id`
- `GET /api/v1/sessions/:id/solves`
- `GET /api/v1/solves`
- `POST /api/v1/solves`
- `PATCH /api/v1/solves/:id`
- `DELETE /api/v1/solves/:id`

## Railway deployment

Deploy this service as a second Railway service, separate from the Flutter web frontend.

- Source repo: this repository
- Dockerfile path: `backend/Dockerfile`
- Build context: repo root
- Required variables:
  - `DATABASE_URL`
  - `PORT` provided by Railway

Recommended Railway shape:

- service 1: Flutter web frontend
- service 2: backend API
- service 3: PostgreSQL

## Notes

- The mobile app remains local-first.
- This backend does not make login mandatory.
- `deleted_at` is soft-delete oriented so future sync does not lose tombstones.
- Stats are intentionally deferred as derived data from solves, not stored as source of truth.
