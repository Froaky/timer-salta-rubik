Map<String, String> extractAuthCallbackParams(Uri callbackUri) {
  if (callbackUri.queryParameters.isNotEmpty) {
    return callbackUri.queryParameters;
  }

  final fragment = callbackUri.fragment.trim();
  if (fragment.isEmpty) {
    return const {};
  }

  if (fragment.contains('=') && !fragment.startsWith('/')) {
    return Uri.splitQueryString(fragment);
  }

  final normalized = fragment.startsWith('/') ? fragment : '/$fragment';
  final fragmentUri = Uri.parse(normalized);
  if (fragmentUri.queryParameters.isNotEmpty) {
    return fragmentUri.queryParameters;
  }

  return const {};
}

Map<String, String> extractAuthCallbackFragmentParams(Uri callbackUri) {
  final fragment = callbackUri.fragment.trim();
  if (fragment.isEmpty) {
    return const {};
  }

  if (fragment.contains('=') && !fragment.startsWith('/')) {
    return Uri.splitQueryString(fragment);
  }

  final normalized = fragment.startsWith('/') ? fragment : '/$fragment';
  final fragmentUri = Uri.parse(normalized);
  if (fragmentUri.queryParameters.isNotEmpty) {
    return fragmentUri.queryParameters;
  }

  return const {};
}

String sanitizeAuthCallbackUri(Uri callbackUri) {
  final queryParameters = Map<String, String>.from(callbackUri.queryParameters);
  if (queryParameters.containsKey('access_token')) {
    queryParameters['access_token'] = '<redacted>';
  }

  final redactedFragment = callbackUri.fragment.replaceAllMapped(
    RegExp(r'access_token=([^&#]+)'),
    (_) => 'access_token=<redacted>',
  );

  return callbackUri
      .replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        fragment: redactedFragment,
      )
      .toString();
}
