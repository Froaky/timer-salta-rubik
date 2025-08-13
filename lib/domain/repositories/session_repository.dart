import '../entities/session.dart';

abstract class SessionRepository {
  Future<void> createSession(Session session);
  Future<List<Session>> getSessions();
  Future<Session?> getSession(String id);
  Future<void> updateSession(Session session);
  Future<void> deleteSession(String id);
}