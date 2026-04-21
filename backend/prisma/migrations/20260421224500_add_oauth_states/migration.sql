CREATE TYPE "OAuthPlatform" AS ENUM ('web', 'mobile');

CREATE TABLE "oauth_states" (
  "id" TEXT NOT NULL,
  "provider" "AuthProvider" NOT NULL,
  "platform" "OAuthPlatform" NOT NULL,
  "redirect_uri" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL,
  "expires_at" TIMESTAMP(3) NOT NULL,
  "consumed_at" TIMESTAMP(3),
  CONSTRAINT "oauth_states_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "oauth_states_expires_at_idx"
ON "oauth_states"("expires_at");

CREATE INDEX "oauth_states_consumed_at_idx"
ON "oauth_states"("consumed_at");
