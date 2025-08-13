import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_datasource.dart';
import '../models/session_model.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SessionLocalDataSource localDataSource;

  SessionRepositoryImpl(this.localDataSource);

  @override
  Future<void> createSession(Session session) async {
    final sessionModel = SessionModel.fromEntity(session);
    await localDataSource.createSession(sessionModel);
  }

  @override
  Future<List<Session>> getSessions() async {
    final sessionModels = await localDataSource.getSessions();
    return sessionModels.cast<Session>();
  }

  @override
  Future<Session?> getSession(String id) async {
    final sessionModel = await localDataSource.getSession(id);
    return sessionModel;
  }

  @override
  Future<void> updateSession(Session session) async {
    final sessionModel = SessionModel.fromEntity(session);
    await localDataSource.updateSession(sessionModel);
  }

  @override
  Future<void> deleteSession(String id) async {
    await localDataSource.deleteSession(id);
  }
}