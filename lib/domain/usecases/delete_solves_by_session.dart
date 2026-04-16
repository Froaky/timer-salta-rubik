import '../../core/usecases/usecase.dart';
import '../repositories/solve_repository.dart';

class DeleteSolvesBySession implements UseCase<void, String> {
  final SolveRepository repository;

  DeleteSolvesBySession(this.repository);

  @override
  Future<void> call(String sessionId) async {
    return repository.deleteSolvesBySession(sessionId);
  }
}
