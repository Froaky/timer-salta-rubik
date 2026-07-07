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

  let target: URL;
  try {
    target = new URL(redirectUri);
  } catch {
    return false;
  }

  // El token de sesion viaja en este redirect: un startsWith crudo permite
  // robo de token via "https://allowed-host.evil.io/..." porque el prefijo
  // no corta en el limite del host. Para http/https se exige igualdad
  // exacta de origin; para esquemas custom (saltarubik://) se exige que el
  // prefijo termine en un limite real de path.
  return getAllowedRedirectUriPrefixes().some((prefix) => {
    if (prefix.startsWith('http://') || prefix.startsWith('https://')) {
      try {
        return new URL(prefix).origin === target.origin;
      } catch {
        return false;
      }
    }

    if (!redirectUri.startsWith(prefix)) {
      return false;
    }
    const rest = redirectUri.slice(prefix.length);
    return rest === '' || rest.startsWith('/') || rest.startsWith('?') || rest.startsWith('#');
  });
}

export function buildSuccessRedirectUrl(redirectUri: string, accessToken: string) {
  const url = new URL(redirectUri);
  url.searchParams.set('access_token', accessToken);
  url.searchParams.set('token_type', 'Bearer');
  url.searchParams.set('provider', 'wca');
  url.hash = '';
  return url.toString();
}
