import '../entities/solve.dart';
import '../entities/statistics.dart';

abstract class SolveRepository {
  Future<void> addSolve(Solve solve);
  Future<List<Solve>> getSolves({
    String? sessionId,
    int? limit,
    int? offset,
  });
  Future<List<Solve>> getSolvesBySession(String sessionId);
  Future<Statistics> getStatistics(String sessionId);
  Future<void> updateSolve(Solve solve);
  Future<void> deleteSolve(String id);
}