ALTER TABLE "users"
ADD COLUMN "name" TEXT;

CREATE TYPE "AuthProvider" AS ENUM ('wca');

CREATE TABLE "external_accounts" (
  "id" TEXT NOT NULL,
  "user_id" TEXT NOT NULL,
  "provider" "AuthProvider" NOT NULL,
  "provider_account_id" TEXT NOT NULL,
  "wca_id" TEXT,
  "email" TEXT,
  "name" TEXT,
  "avatar_url" TEXT,
  "country_iso2" TEXT,
  "access_token" TEXT,
  "refresh_token" TEXT,
  "expires_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL,
  "updated_at" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "external_accounts_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "external_accounts_provider_provider_account_id_key"
ON "external_accounts"("provider", "provider_account_id");

CREATE INDEX "external_accounts_user_id_idx"
ON "external_accounts"("user_id");

CREATE INDEX "external_accounts_wca_id_idx"
ON "external_accounts"("wca_id");

ALTER TABLE "external_accounts"
ADD CONSTRAINT "external_accounts_user_id_fkey"
FOREIGN KEY ("user_id") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
