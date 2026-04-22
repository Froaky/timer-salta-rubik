const defaultAllowedRedirectUris = [
  'http://localhost:3000',
  'http://localhost:8080',
  'http://localhost:8081',
  'http://localhost:5173',
  'saltarubik://auth/callback',
];

export function getAllowedRedirectUriPrefixes() {
  const configured =
      process.env.AUTH_ALLOWED_REDIRECT_URIS
          ?.split(',')
          .map((value) => value.trim())
          .filter(Boolean) ?? [];

  return configured.length > 0 ? configured : defaultAllowedRedirectUris;
}

export function isAllowedRedirectUri(redirectUri?: string | null) {
  if (!redirectUri) {
    return false;
  }

  return getAllowedRedirectUriPrefixes().some((prefix) => redirectUri.startsWith(prefix));
}

export function buildSuccessRedirectUrl(redirectUri: string, accessToken: string) {
  const url = new URL(redirectUri);
  url.searchParams.set('access_token', accessToken);
  url.searchParams.set('token_type', 'Bearer');
  url.searchParams.set('provider', 'wca');
  url.hash = '';
  return url.toString();
}
