import '../../core/usecases/usecase.dart';
import '../entities/solve.dart';
import '../repositories/solve_repository.dart';

class UpdateSolve implements UseCase<void, Solve> {
  final SolveRepository repository;

  UpdateSolve(this.repository);

  @override
  Future<void> call(Solve solve) async {
    return await repository.updateSolve(solve);
  }
}