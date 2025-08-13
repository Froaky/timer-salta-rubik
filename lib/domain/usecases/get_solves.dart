import 'package:equatable/equatable.dart';

import '../../core/usecases/usecase.dart';
import '../entities/solve.dart';
import '../repositories/solve_repository.dart';

class GetSolves implements UseCase<List<Solve>, GetSolvesParams> {
  final SolveRepository repository;

  GetSolves(this.repository);

  @override
  Future<List<Solve>> call(GetSolvesParams params) async {
    return await repository.getSolves(
      sessionId: params.sessionId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetSolvesParams extends Equatable {
  final String? sessionId;
  final int? limit;
  final int? offset;

  const GetSolvesParams({
    this.sessionId,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [sessionId, limit, offset];
}