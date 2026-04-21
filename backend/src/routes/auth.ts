import { randomUUID } from 'node:crypto';

import type { FastifyInstance } from 'fastify';

import { buildSuccessRedirectUrl, getAllowedRedirectUriPrefixes, isAllowedRedirectUri } from '../lib/auth_redirects.js';
import { extractBearerToken, isAuthTokenConfigured, signAuthToken, verifyAuthToken } from '../lib/auth_token.js';
import { prisma } from '../lib/prisma.js';

const wcaAuthorizeBaseUrl = 'https://www.worldcubeassociation.org/oauth/authorize';
const wcaTokenUrl = 'https://www.worldcubeassociation.org/oauth/token';
const wcaMeUrl = 'https://www.worldcubeassociation.org/api/v0/me';
const oauthStateTtlMs = 10 * 60 * 1000;

type WcaTokenResponse = {
  access_token?: string;
  refresh_token?: string;
  expires_in?: number;
};

type WcaMeResponse = {
  me?: {
    id: number;
    wca_id?: string | null;
    email?: string | null;
    name?: string | null;
    country_iso2?: string | null;
    avatar?: {
      url?: string | null;
    } | null;
  };
};

type StartQuery = {
  platform?: 'web' | 'mobile';
  redirectUri?: string;
};

function getWcaOAuthConfig() {
  return {
    clientId: process.env.WCA_OAUTH_CLIENT_ID,
    clientSecret: process.env.WCA_OAUTH_CLIENT_SECRET,
    redirectUri: process.env.WCA_OAUTH_REDIRECT_URI,
  };
}

function isWcaConfigured() {
  const config = getWcaOAuthConfig();
  return Boolean(
      config.clientId &&
      config.clientSecret &&
      config.redirectUri &&
      isAuthTokenConfigured(),
  );
}

function buildWcaAuthorizeUrl(state: string) {
  const config = getWcaOAuthConfig();
  const url = new URL(wcaAuthorizeBaseUrl);
  url.searchParams.set('client_id', config.clientId ?? '');
  url.searchParams.set('redirect_uri', config.redirectUri ?? '');
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('scope', 'public');
  url.searchParams.set('state', state);
  return url.toString();
}

async function exchangeCodeForToken(code: string) {
  const config = getWcaOAuthConfig();
  const tokenBody = new URLSearchParams({
    grant_type: 'authorization_code',
    client_id: config.clientId ?? '',
    client_secret: config.clientSecret ?? '',
    code,
    redirect_uri: config.redirectUri ?? '',
  });

  const tokenResponse = await fetch(wcaTokenUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: tokenBody.toString(),
  });

  if (!tokenResponse.ok) {
    return null;
  }

  return (await tokenResponse.json()) as WcaTokenResponse;
}

async function fetchWcaProfile(accessToken: string) {
  const meResponse = await fetch(wcaMeUrl, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!meResponse.ok) {
    return null;
  }

  const meJson = (await meResponse.json()) as WcaMeResponse;
  return meJson.me ?? null;
}

export async function authRoutes(app: FastifyInstance): Promise<void> {
  const prismaClient = prisma as any;

  app.get('/auth/providers', async () => {
    return {
      providers: [
        {
          id: 'wca',
          name: 'World Cube Association',
          configured: isWcaConfigured(),
          startUrl: isWcaConfigured() ? '/api/v1/auth/wca/start' : null,
          allowedRedirectUriPrefixes: getAllowedRedirectUriPrefixes(),
        },
      ],
    };
  });

  app.get<{ Querystring: StartQuery }>('/auth/wca/start', async (request, reply) => {
    if (!isWcaConfigured()) {
      return reply.code(503).send({
        message: 'WCA OAuth or AUTH_JWT_SECRET is not configured',
      });
    }

    const platform = request.query.platform === 'mobile' ? 'mobile' : 'web';
    const redirectUri = request.query.redirectUri?.trim() || null;

    if (redirectUri && !isAllowedRedirectUri(redirectUri)) {
      return reply.code(400).send({
        message: 'Redirect URI is not allowed',
        allowedRedirectUriPrefixes: getAllowedRedirectUriPrefixes(),
      });
    }

    const now = new Date();
    const stateId = randomUUID();

    await prismaClient.oAuthState.create({
      data: {
        id: stateId,
        provider: 'wca',
        platform,
        redirectUri,
        createdAt: now,
        expiresAt: new Date(now.getTime() + oauthStateTtlMs),
      },
    });

    return reply.redirect(buildWcaAuthorizeUrl(stateId));
  });

  app.get<{ Querystring: { code?: string; error?: string; state?: string } }>(
      '/auth/wca/callback',
      async (request, reply) => {
        if (!isWcaConfigured()) {
          return reply.code(503).send({
            message: 'WCA OAuth or AUTH_JWT_SECRET is not configured',
          });
        }

        if (request.query.error) {
          return reply.code(400).send({
            message: 'WCA authorization failed',
            error: request.query.error,
          });
        }

        if (!request.query.code) {
          return reply.code(400).send({
            message: 'Missing WCA authorization code',
          });
        }

        if (!request.query.state) {
          return reply.code(400).send({
            message: 'Missing OAuth state',
          });
        }

        const oauthState = await prismaClient.oAuthState.findUnique({
          where: {
            id: request.query.state,
          },
        });

        if (!oauthState) {
          return reply.code(400).send({
            message: 'Unknown OAuth state',
          });
        }

        if (oauthState.consumedAt) {
          return reply.code(400).send({
            message: 'OAuth state was already used',
          });
        }

        if (oauthState.expiresAt.getTime() < Date.now()) {
          return reply.code(400).send({
            message: 'OAuth state expired',
          });
        }

        const tokenJson = await exchangeCodeForToken(request.query.code);

        if (!tokenJson?.access_token) {
          return reply.code(502).send({
            message: 'Failed to exchange WCA authorization code',
          });
        }

        const profile = await fetchWcaProfile(tokenJson.access_token);

        if (!profile) {
          return reply.code(502).send({
            message: 'Failed to fetch WCA profile',
          });
        }

        const providerAccountId = String(profile.id);
        const now = new Date();
        const expiresAt =
            tokenJson.expires_in !== undefined
                ? new Date(Date.now() + tokenJson.expires_in * 1000)
                : null;

        const existingExternalAccount = await prismaClient.externalAccount.findUnique({
          where: {
            provider_providerAccountId: {
              provider: 'wca',
              providerAccountId,
            },
          },
          include: {
            user: true,
          },
        });

        const user =
            existingExternalAccount?.user ??
            (await prismaClient.user.create({
              data: {
                id: randomUUID(),
                email: profile.email ?? null,
                name: profile.name ?? null,
                createdAt: now,
                updatedAt: now,
              },
            }));

        await prismaClient.user.update({
          where: {
            id: user.id,
          },
          data: {
            email: profile.email ?? user.email,
            name: profile.name ?? user.name,
            updatedAt: now,
          },
        });

        await prismaClient.externalAccount.upsert({
          where: {
            provider_providerAccountId: {
              provider: 'wca',
              providerAccountId,
            },
          },
          update: {
            email: profile.email ?? null,
            name: profile.name ?? null,
            wcaId: profile.wca_id ?? null,
            countryIso2: profile.country_iso2 ?? null,
            avatarUrl: profile.avatar?.url ?? null,
            accessToken: tokenJson.access_token,
            refreshToken: tokenJson.refresh_token ?? null,
            expiresAt,
            updatedAt: now,
          },
          create: {
            id: randomUUID(),
            userId: user.id,
            provider: 'wca',
            providerAccountId,
            email: profile.email ?? null,
            name: profile.name ?? null,
            wcaId: profile.wca_id ?? null,
            countryIso2: profile.country_iso2 ?? null,
            avatarUrl: profile.avatar?.url ?? null,
            accessToken: tokenJson.access_token,
            refreshToken: tokenJson.refresh_token ?? null,
            expiresAt,
            createdAt: now,
            updatedAt: now,
          },
        });

        await prismaClient.oAuthState.update({
          where: {
            id: oauthState.id,
          },
          data: {
            consumedAt: now,
          },
        });

        const accessToken = signAuthToken({
          sub: user.id,
          email: profile.email ?? null,
          name: profile.name ?? null,
          providers: ['wca'],
        });

        if (oauthState.redirectUri) {
          return reply.redirect(buildSuccessRedirectUrl(oauthState.redirectUri, accessToken));
        }

        return {
          message: 'WCA account linked successfully',
          accessToken,
          tokenType: 'Bearer',
          user: {
            id: user.id,
            email: profile.email ?? null,
            name: profile.name ?? null,
          },
          externalAccount: {
            provider: 'wca',
            providerAccountId,
            wcaId: profile.wca_id ?? null,
            countryIso2: profile.country_iso2 ?? null,
            platform: oauthState.platform,
          },
        };
      },
  );

  app.get('/auth/me', async (request, reply) => {
    if (!isAuthTokenConfigured()) {
      return reply.code(503).send({
        message: 'AUTH_JWT_SECRET is not configured',
      });
    }

    const token = extractBearerToken(request.headers.authorization);
    if (!token) {
      return reply.code(401).send({
        message: 'Missing bearer token',
      });
    }

    const payload = verifyAuthToken(token);
    if (!payload) {
      return reply.code(401).send({
        message: 'Invalid or expired token',
      });
    }

    const user = await prismaClient.user.findUnique({
      where: {
        id: payload.sub,
      },
      include: {
        externalAccounts: true,
      },
    });

    if (!user) {
      return reply.code(404).send({
        message: 'User not found',
      });
    }

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        providers: user.externalAccounts.map((account: any) => ({
          provider: account.provider,
          wcaId: account.wcaId,
          email: account.email,
          name: account.name,
          countryIso2: account.countryIso2,
          avatarUrl: account.avatarUrl,
        })),
      },
    };
  });
}
