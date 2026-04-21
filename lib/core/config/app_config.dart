class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'SALTA_API_BASE_URL',
    defaultValue: 'https://timer-api-production.up.railway.app',
  );

  static const String webAuthCallbackPath = '/auth/callback';
  static const String mobileAuthCallbackUri = 'saltarubik://auth/callback';
}
