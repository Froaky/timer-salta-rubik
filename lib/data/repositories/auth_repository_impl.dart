import '../../core/auth/auth_callback_parser.dart';
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
    final params = extractAuthCallbackParams(callbackUri);
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
}
