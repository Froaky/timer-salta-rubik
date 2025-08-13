import 'package:equatable/equatable.dart';

import '../../../domain/entities/solve.dart';

abstract class SolveEvent extends Equatable {
  const SolveEvent();

  @override
  List<Object?> get props => [];
}

class LoadSolves extends SolveEvent {
  final String sessionId;
  final int? limit;
  final int? offset;

  const LoadSolves({
    required this.sessionId,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [sessionId, limit, offset];
}

class AddSolveEvent extends SolveEvent {
  final Solve solve;

  const AddSolveEvent(this.solve);

  @override
  List<Object> get props => [solve];
}

class UpdateSolveEvent extends SolveEvent {
  final Solve solve;

  const UpdateSolveEvent(this.solve);

  @override
  List<Object> get props => [solve];
}

class DeleteSolveEvent extends SolveEvent {
  final String solveId;

  const DeleteSolveEvent(this.solveId);

  @override
  List<Object> get props => [solveId];
}

class GenerateNewScramble extends SolveEvent {
  final String cubeType;

  const GenerateNewScramble(this.cubeType);

  @override
  List<Object> get props => [cubeType];
}

class LoadStatistics extends SolveEvent {
  final String sessionId;

  const LoadStatistics(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}