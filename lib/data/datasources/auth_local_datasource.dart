import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session_model.dart';

abstract class AuthLocalDataSource {
  Future<AuthSessionModel?> getStoredSession();
  Future<void> saveSession(AuthSessionModel session);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _sessionKey = 'salta_rubik.auth_session';
  AuthSessionModel? _memorySession;

  @override
  Future<void> clearSession() async {
    _memorySession = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }

  @override
  Future<AuthSessionModel?> getStoredSession() async {
    if (_memorySession != null) {
      return _memorySession;
    }

    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_sessionKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    // Una sesion persistida corrupta no debe romper AuthPage en cada
    // apertura: se descarta y se limpia para que el proximo login la
    // regenere.
    try {
      final session = AuthSessionModel.fromStorage(rawValue);
      _memorySession = session;
      return session;
    } catch (_) {
      await preferences.remove(_sessionKey);
      return null;
    }
  }

  @override
  Future<void> saveSession(AuthSessionModel session) async {
    _memorySession = session;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, session.toStorage());
  }
}
