import '../../core/usecases/usecase.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';

class GetSessions implements UseCase<List<Session>, NoParams> {
  final SessionRepository repository;

  GetSessions(this.repository);

  @override
  Future<List<Session>> call(NoParams params) async {
    return await repository.getSessions();
  }
}