import { createHmac, timingSafeEqual } from 'node:crypto';

type AuthTokenPayload = {
  sub: string;
  email?: string | null;
  name?: string | null;
  providers?: string[];
  iat: number;
  exp: number;
};

function base64UrlEncode(input: string | Buffer) {
  return Buffer.from(input)
      .toString('base64')
      .replaceAll('+', '-')
      .replaceAll('/', '_')
      .replaceAll('=', '');
}

function base64UrlDecode(input: string) {
  const normalized = input.replaceAll('-', '+').replaceAll('_', '/');
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=');
  return Buffer.from(padded, 'base64').toString('utf8');
}

function getJwtSecret() {
  return process.env.AUTH_JWT_SECRET;
}

export function isAuthTokenConfigured() {
  return Boolean(getJwtSecret());
}

export function getAuthTokenTtlSeconds() {
  return Number(process.env.AUTH_TOKEN_TTL_SECONDS ?? '2592000');
}

export function signAuthToken(
    payload: Omit<AuthTokenPayload, 'iat' | 'exp'>,
): string {
  const secret = getJwtSecret();

  if (!secret) {
    throw new Error('AUTH_JWT_SECRET is not configured');
  }

  const issuedAt = Math.floor(Date.now() / 1000);
  const expiresAt = issuedAt + getAuthTokenTtlSeconds();
  const header = {
    alg: 'HS256',
    typ: 'JWT',
  };
  const fullPayload: AuthTokenPayload = {
    ...payload,
    iat: issuedAt,
    exp: expiresAt,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(fullPayload));
  const unsignedToken = `${encodedHeader}.${encodedPayload}`;
  const signature = createHmac('sha256', secret).update(unsignedToken).digest();
  const encodedSignature = base64UrlEncode(signature);

  return `${unsignedToken}.${encodedSignature}`;
}

export function verifyAuthToken(token: string): AuthTokenPayload | null {
  const secret = getJwtSecret();

  if (!secret) {
    return null;
  }

  const parts = token.split('.');
  if (parts.length !== 3) {
    return null;
  }

  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  const unsignedToken = `${encodedHeader}.${encodedPayload}`;
  const expectedSignature = createHmac('sha256', secret).update(unsignedToken).digest();
  const actualSignature = Buffer.from(
      encodedSignature.replaceAll('-', '+').replaceAll('_', '/').padEnd(
          Math.ceil(encodedSignature.length / 4) * 4,
          '=',
      ),
      'base64',
  );

  if (
    expectedSignature.length !== actualSignature.length ||
    !timingSafeEqual(expectedSignature, actualSignature)
  ) {
    return null;
  }

  try {
    const payload = JSON.parse(base64UrlDecode(encodedPayload)) as AuthTokenPayload;

    if (payload.exp <= Math.floor(Date.now() / 1000)) {
      return null;
    }

    return payload;
  } catch {
    return null;
  }
}

export function extractBearerToken(authorizationHeader?: string) {
  if (!authorizationHeader?.startsWith('Bearer ')) {
    return null;
  }

  return authorizationHeader.slice('Bearer '.length).trim();
}
