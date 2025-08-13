import '../models/session_model.dart';
import 'local_database.dart';

abstract class SessionLocalDataSource {
  Future<void> createSession(SessionModel session);
  Future<List<SessionModel>> getSessions();
  Future<SessionModel?> getSession(String id);
  Future<void> updateSession(SessionModel session);
  Future<void> deleteSession(String id);
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  final LocalDatabase localDatabase;

  SessionLocalDataSourceImpl(this.localDatabase);

  @override
  Future<void> createSession(SessionModel session) async {
    await localDatabase.insertSession(session.toMap());
  }

  @override
  Future<List<SessionModel>> getSessions() async {
    final maps = await localDatabase.getSessions();
    return maps.map((map) => SessionModel.fromMap(map)).toList();
  }

  @override
  Future<SessionModel?> getSession(String id) async {
    final map = await localDatabase.getSession(id);
    return map != null ? SessionModel.fromMap(map) : null;
  }

  @override
  Future<void> updateSession(SessionModel session) async {
    await localDatabase.updateSession(session.toMap());
  }

  @override
  Future<void> deleteSession(String id) async {
    await localDatabase.deleteSession(id);
  }
}