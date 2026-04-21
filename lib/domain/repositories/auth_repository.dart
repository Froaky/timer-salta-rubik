import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession?> getStoredSession();
  Future<AuthSession?> completeWcaCallback(Uri callbackUri);
  Uri buildWcaLoginUri({required bool isWeb});
  Future<void> clearSession();
}
