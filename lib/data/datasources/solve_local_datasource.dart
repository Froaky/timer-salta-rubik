import '../models/solve_model.dart';
import '../../domain/entities/solve.dart';
import '../../domain/entities/statistics.dart';
import 'local_database.dart';

abstract class SolveLocalDataSource {
  Future<void> addSolve(SolveModel solve);
  Future<List<SolveModel>> getSolves({
    String? sessionId,
    int? limit,
    int? offset,
  });
  Future<List<SolveModel>> getSolvesBySession(String sessionId);
  Future<Statistics> getStatistics(String sessionId);
  Future<void> updateSolve(SolveModel solve);
  Future<void> deleteSolve(String id);
}

class SolveLocalDataSourceImpl implements SolveLocalDataSource {
  final LocalDatabase localDatabase;

  SolveLocalDataSourceImpl(this.localDatabase);

  @override
  Future<void> addSolve(SolveModel solve) async {
    print('DEBUG: SolveLocalDataSourceImpl.addSolve called');
    final solveMap = solve.toMap();
    print('DEBUG: Solve map to insert: $solveMap');
    await localDatabase.insertSolve(solveMap);
    print('DEBUG: localDatabase.insertSolve completed');
  }

  @override
  Future<List<SolveModel>> getSolves({
    String? sessionId,
    int? limit,
    int? offset,
  }) async {
    final maps = await localDatabase.getSolves(
      sessionId: sessionId,
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => SolveModel.fromMap(map)).toList();
  }

  @override
  Future<List<SolveModel>> getSolvesBySession(String sessionId) async {
    final maps = await localDatabase.getSolvesBySession(sessionId);
    return maps.map((map) => SolveModel.fromMap(map)).toList();
  }

  @override
  Future<Statistics> getStatistics(String sessionId) async {
    final solves = await getSolvesBySession(sessionId);
    return Statistics.fromSolves(solves.cast<Solve>());
  }

  @override
  Future<void> updateSolve(SolveModel solve) async {
    await localDatabase.updateSolve(solve.toMap());
  }

  @override
  Future<void> deleteSolve(String id) async {
    await localDatabase.deleteSolve(id);
  }
}