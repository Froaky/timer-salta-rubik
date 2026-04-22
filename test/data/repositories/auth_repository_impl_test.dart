import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/data/datasources/auth_local_datasource.dart';
import 'package:salta_rubik/data/datasources/auth_remote_datasource.dart';
import 'package:salta_rubik/data/models/auth_session_model.dart';
import 'package:salta_rubik/data/repositories/auth_repository_impl.dart';

class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  AuthSessionModel? storedSession;
  AuthSessionModel? lastSavedSession;

  @override
  Future<void> clearSession() async {
    storedSession = null;
  }

  @override
  Future<AuthSessionModel?> getStoredSession() async {
    return storedSession;
  }

  @override
  Future<void> saveSession(AuthSessionModel session) async {
    storedSession = session;
    lastSavedSession = session;
  }
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  final AuthSessionModel session;
  String? lastAccessToken;

  _FakeAuthRemoteDataSource(this.session);

  @override
  Future<AuthSessionModel> getCurrentUser(String accessToken) async {
    lastAccessToken = accessToken;
    return session;
  }
}

void main() {
  const session = AuthSessionModel(
    accessToken: 'server-token',
    userId: 'user-1',
    email: 'mateo@example.com',
    name: 'Mateo Coca',
    providers: [
      AuthProviderProfileModel(
        provider: 'wca',
        wcaId: '2024TEST01',
        countryIso2: 'AR',
        avatarUrl: 'https://example.com/avatar.png',
      ),
    ],
  );

  test('completes callback from fragment access token and stores session',
      () async {
    final localDataSource = _FakeAuthLocalDataSource();
    final remoteDataSource = _FakeAuthRemoteDataSource(session);
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );

    final result = await repository.completeWcaCallback(
      Uri.parse(
          'https://timer-salta-rubik-production.up.railway.app/auth/callback#access_token=abc123&token_type=Bearer'),
    );

    expect(remoteDataSource.lastAccessToken, 'abc123');
    expect(localDataSource.lastSavedSession, session);
    expect(result, session);
  });

  test('completes callback when token comes inside hash route query', () async {
    final localDataSource = _FakeAuthLocalDataSource();
    final remoteDataSource = _FakeAuthRemoteDataSource(session);
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );

    final result = await repository.completeWcaCallback(
      Uri.parse(
          'https://timer-salta-rubik-production.up.railway.app/#/auth/callback?access_token=abc123&token_type=Bearer'),
    );

    expect(remoteDataSource.lastAccessToken, 'abc123');
    expect(localDataSource.lastSavedSession, session);
    expect(result, session);
  });

  test('returns null when callback does not contain access token', () async {
    final localDataSource = _FakeAuthLocalDataSource();
    final remoteDataSource = _FakeAuthRemoteDataSource(session);
    final repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );

    final result = await repository.completeWcaCallback(
      Uri.parse(
          'https://timer-salta-rubik-production.up.railway.app/auth/callback'),
    );

    expect(result, isNull);
    expect(remoteDataSource.lastAccessToken, isNull);
    expect(localDataSource.lastSavedSession, isNull);
  });
}
