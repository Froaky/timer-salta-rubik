import '../../domain/entities/solve.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/repositories/solve_repository.dart';
import '../datasources/solve_local_datasource.dart';
import '../models/solve_model.dart';

class SolveRepositoryImpl implements SolveRepository {
  final SolveLocalDataSource localDataSource;

  SolveRepositoryImpl(this.localDataSource);

  @override
  Future<void> addSolve(Solve solve) async {
    print('DEBUG: SolveRepositoryImpl.addSolve called');
    final solveModel = SolveModel.fromEntity(solve);
    print('DEBUG: Created SolveModel: ${solveModel.toMap()}');
    await localDataSource.addSolve(solveModel);
    print('DEBUG: localDataSource.addSolve completed');
  }

  @override
  Future<List<Solve>> getSolves({
    String? sessionId,
    int? limit,
    int? offset,
  }) async {
    final solveModels = await localDataSource.getSolves(
      sessionId: sessionId,
      limit: limit,
      offset: offset,
    );
    return solveModels.cast<Solve>();
  }

  @override
  Future<List<Solve>> getSolvesBySession(String sessionId) async {
    final solveModels = await localDataSource.getSolvesBySession(sessionId);
    return solveModels.cast<Solve>();
  }

  @override
  Future<Statistics> getStatistics(String sessionId) async {
    return await localDataSource.getStatistics(sessionId);
  }

  @override
  Future<void> updateSolve(Solve solve) async {
    final solveModel = SolveModel.fromEntity(solve);
    await localDataSource.updateSolve(solveModel);
  }

  @override
  Future<void> deleteSolve(String id) async {
    await localDataSource.deleteSolve(id);
  }
}