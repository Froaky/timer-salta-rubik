import '../../core/usecases/usecase.dart';
import '../entities/solve.dart';
import '../repositories/solve_repository.dart';

class AddSolve implements UseCase<void, Solve> {
  final SolveRepository repository;

  AddSolve(this.repository);

  @override
  Future<void> call(Solve solve) async {
    return await repository.addSolve(solve);
  }
}