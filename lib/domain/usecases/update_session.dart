import '../../core/usecases/usecase.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

class UpdateSession implements UseCase<void, Session> {
  final SessionRepository repository;

  UpdateSession(this.repository);

  @override
  Future<void> call(Session session) async {
    return await repository.updateSession(session);
  }
}