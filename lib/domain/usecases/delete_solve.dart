import '../../core/usecases/usecase.dart';
import '../repositories/solve_repository.dart';

class DeleteSolve implements UseCase<void, String> {
  final SolveRepository repository;

  DeleteSolve(this.repository);

  @override
  Future<void> call(String id) async {
    return await repository.deleteSolve(id);
  }
}