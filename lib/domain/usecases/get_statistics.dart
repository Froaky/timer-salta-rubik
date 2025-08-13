import '../../core/usecases/usecase.dart';
import '../entities/statistics.dart';
import '../repositories/solve_repository.dart';

class GetStatistics implements UseCase<Statistics, String> {
  final SolveRepository repository;

  GetStatistics(this.repository);

  @override
  Future<Statistics> call(String sessionId) async {
    return await repository.getStatistics(sessionId);
  }
}