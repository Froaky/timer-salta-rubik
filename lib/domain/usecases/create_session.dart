import '../../core/usecases/usecase.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

class CreateSession implements UseCase<void, Session> {
  final SessionRepository repository;

  CreateSession(this.repository);

  @override
  Future<void> call(Session session) async {
    return await repository.createSession(session);
  }
}