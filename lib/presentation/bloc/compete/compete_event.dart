import 'package:equatable/equatable.dart';

import '../../../domain/entities/solve.dart';

abstract class CompeteEvent extends Equatable {
  const CompeteEvent();

  @override
  List<Object?> get props => [];
}

class StartCompeteRound extends CompeteEvent {
  final String cubeType;
  final bool useSameScramble;

  const StartCompeteRound({
    required this.cubeType,
    this.useSameScramble = true,
  });

  @override
  List<Object> get props => [cubeType, useSameScramble];
}

class AddCompeteSolve extends CompeteEvent {
  final Solve solve;
  final int lane; // 1 or 2

  const AddCompeteSolve({
    required this.solve,
    required this.lane,
  });

  @override
  List<Object> get props => [solve, lane];
}

class ResetCompete extends CompeteEvent {
  const ResetCompete();
}

class UpdateLaneTimer extends CompeteEvent {
  final int lane;
  final int elapsedMs;

  const UpdateLaneTimer({
    required this.lane,
    required this.elapsedMs,
  });

  @override
  List<Object> get props => [lane, elapsedMs];
}

class GenerateCompeteScrambles extends CompeteEvent {
  const GenerateCompeteScrambles();
}

class AwardPoint extends CompeteEvent {
  final int lane;

  const AwardPoint({
    required this.lane,
  });

  @override
  List<Object> get props => [lane];
}