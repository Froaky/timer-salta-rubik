# Salta Rubik Backend

Backend API foundation for Salta Rubik using:

- Fastify
- Prisma ORM
- PostgreSQL

This service is intended to run separately from the Flutter web frontend. It exists to prepare:

- account-backed data,
- remote sessions and solves,
- optional WCA account linking,
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

### Optional WCA OAuth setup

If you want to allow users to link/sign in with their WCA account, configure:

- `AUTH_JWT_SECRET`
- `AUTH_TOKEN_TTL_SECONDS`
- `AUTH_ALLOWED_REDIRECT_URIS`
- `WCA_OAUTH_CLIENT_ID`
- `WCA_OAUTH_CLIENT_SECRET`
- `WCA_OAUTH_REDIRECT_URI`

The callback route expected by this backend is:

```text
/api/v1/auth/wca/callback
```

Example Railway values:

```text
AUTH_JWT_SECRET=<long random secret>
AUTH_TOKEN_TTL_SECONDS=2592000
AUTH_ALLOWED_REDIRECT_URIS=https://timer-salta-rubik-production.up.railway.app/auth/callback,saltarubik://auth/callback
WCA_OAUTH_REDIRECT_URI=https://timer-api-production.up.railway.app/api/v1/auth/wca/callback
```

## Current endpoints

- `GET /health`
- `GET /api/v1/auth/providers`
- `GET /api/v1/auth/wca/start?platform=web|mobile&redirectUri=...`
- `GET /api/v1/auth/wca/callback`
- `GET /api/v1/auth/me`
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
  - `WCA_OAUTH_CLIENT_ID` optional
  - `WCA_OAUTH_CLIENT_SECRET` optional
  - `WCA_OAUTH_REDIRECT_URI` optional

Recommended Railway shape:

- service 1: Flutter web frontend
- service 2: backend API
- service 3: PostgreSQL

## Notes

- The mobile app remains local-first.
- This backend does not make login mandatory.
- WCA should be treated as an optional external identity provider, not as the only way to use Salta Rubik.
- The backend now issues its own bearer token after WCA OAuth so the client does not need to keep WCA secrets.
- `oauth_states` exist to validate `state` and support safe web/mobile redirects after login.
- `deleted_at` is soft-delete oriented so future sync does not lose tombstones.
- Stats are intentionally deferred as derived data from solves, not stored as source of truth.
