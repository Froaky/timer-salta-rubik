import '../../core/config/app_config.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Uri buildWcaLoginUri({required bool isWeb}) {
    final platform = isWeb ? 'web' : 'mobile';
    final redirectUri = isWeb
        ? '${Uri.base.origin}${AppConfig.webAuthCallbackPath}'
        : AppConfig.mobileAuthCallbackUri;

    return Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/wca/start').replace(
      queryParameters: {
        'platform': platform,
        'redirectUri': redirectUri,
      },
    );
  }

  @override
  Future<void> clearSession() {
    return localDataSource.clearSession();
  }

  @override
  Future<AuthSession?> completeWcaCallback(Uri callbackUri) async {
    final params = _extractCallbackParams(callbackUri);
    final accessToken = params['access_token'];
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final session = await remoteDataSource.getCurrentUser(accessToken);
    await localDataSource.saveSession(session);
    return session;
  }

  @override
  Future<AuthSession?> getStoredSession() {
    return localDataSource.getStoredSession();
  }

  Map<String, String> _extractCallbackParams(Uri callbackUri) {
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
}
