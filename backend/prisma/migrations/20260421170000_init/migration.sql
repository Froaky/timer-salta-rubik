CREATE TABLE "users" (
  "id" TEXT NOT NULL,
  "email" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

CREATE TABLE "sessions" (
  "id" TEXT NOT NULL,
  "owner_user_id" TEXT,
  "name" TEXT NOT NULL,
  "cube_type" TEXT NOT NULL,
  "created_at" TIMESTAMP(3) NOT NULL,
  "updated_at" TIMESTAMP(3) NOT NULL,
  "deleted_at" TIMESTAMP(3),
  CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "sessions_owner_user_id_created_at_idx" ON "sessions"("owner_user_id", "created_at" DESC);
CREATE INDEX "sessions_deleted_at_idx" ON "sessions"("deleted_at");

CREATE TYPE "Penalty" AS ENUM ('none', 'plus2', 'dnf');

CREATE TABLE "solves" (
  "id" TEXT NOT NULL,
  "session_id" TEXT NOT NULL,
  "owner_user_id" TEXT,
  "time_ms" INTEGER NOT NULL,
  "penalty" "Penalty" NOT NULL,
  "scramble" TEXT NOT NULL,
  "cube_type" TEXT NOT NULL,
  "lane" INTEGER NOT NULL DEFAULT 0,
  "created_at" TIMESTAMP(3) NOT NULL,
  "updated_at" TIMESTAMP(3) NOT NULL,
  "deleted_at" TIMESTAMP(3),
  CONSTRAINT "solves_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "solves_session_id_created_at_idx" ON "solves"("session_id", "created_at" DESC);
CREATE INDEX "solves_owner_user_id_created_at_idx" ON "solves"("owner_user_id", "created_at" DESC);
CREATE INDEX "solves_deleted_at_idx" ON "solves"("deleted_at");

ALTER TABLE "sessions"
ADD CONSTRAINT "sessions_owner_user_id_fkey"
FOREIGN KEY ("owner_user_id") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "solves"
ADD CONSTRAINT "solves_session_id_fkey"
FOREIGN KEY ("session_id") REFERENCES "sessions"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "solves"
ADD CONSTRAINT "solves_owner_user_id_fkey"
FOREIGN KEY ("owner_user_id") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
