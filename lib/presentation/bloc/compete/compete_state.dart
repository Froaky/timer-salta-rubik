import 'package:equatable/equatable.dart';

import '../../../domain/entities/solve.dart';
import '../../../domain/entities/scramble.dart';

enum CompeteStatus {
  initial,
  ready,
  inProgress,
  finished,
}

class LaneData extends Equatable {
  final List<Solve> solves;
  final int? currentTimeMs;
  final bool isFinished;

  const LaneData({
    required this.solves,
    this.currentTimeMs,
    this.isFinished = false,
  });

  LaneData copyWith({
    List<Solve>? solves,
    int? currentTimeMs,
    bool? isFinished,
  }) {
    return LaneData(
      solves: solves ?? this.solves,
      currentTimeMs: currentTimeMs ?? this.currentTimeMs,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  @override
  List<Object?> get props => [solves, currentTimeMs, isFinished];
}

class CompeteState extends Equatable {
  final CompeteStatus status;
  final Scramble? scrambleLane1;
  final Scramble? scrambleLane2;
  final LaneData lane1;
  final LaneData lane2;
  final String? winner; // 'lane1', 'lane2', or 'tie'
  final bool useSameScramble;
  final int lane1Score;
  final int lane2Score;
  // Competition round control states
  final bool lane1Running;
  final bool lane2Running;
  final int? lane1FinishedAtMs;
  final int? lane2FinishedAtMs;
  final bool roundScored;

  const CompeteState({
    required this.status,
    this.scrambleLane1,
    this.scrambleLane2,
    required this.lane1,
    required this.lane2,
    this.winner,
    this.useSameScramble = true,
    this.lane1Score = 0,
    this.lane2Score = 0,
    this.lane1Running = false,
    this.lane2Running = false,
    this.lane1FinishedAtMs,
    this.lane2FinishedAtMs,
    this.roundScored = false,
  });

  factory CompeteState.initial() {
    return const CompeteState(
      status: CompeteStatus.initial,
      lane1: LaneData(solves: []),
      lane2: LaneData(solves: []),
      lane1Score: 0,
      lane2Score: 0,
      lane1Running: false,
      lane2Running: false,
      lane1FinishedAtMs: null,
      lane2FinishedAtMs: null,
      roundScored: false,
    );
  }

  CompeteState copyWith({
    CompeteStatus? status,
    Scramble? scrambleLane1,
    Scramble? scrambleLane2,
    LaneData? lane1,
    LaneData? lane2,
    String? winner,
    bool? useSameScramble,
    int? lane1Score,
    int? lane2Score,
    bool? lane1Running,
    bool? lane2Running,
    int? lane1FinishedAtMs,
    int? lane2FinishedAtMs,
    bool? roundScored,
  }) {
    return CompeteState(
      status: status ?? this.status,
      scrambleLane1: scrambleLane1 ?? this.scrambleLane1,
      scrambleLane2: scrambleLane2 ?? this.scrambleLane2,
      lane1: lane1 ?? this.lane1,
      lane2: lane2 ?? this.lane2,
      winner: winner ?? this.winner,
      useSameScramble: useSameScramble ?? this.useSameScramble,
      lane1Score: lane1Score ?? this.lane1Score,
      lane2Score: lane2Score ?? this.lane2Score,
      lane1Running: lane1Running ?? this.lane1Running,
      lane2Running: lane2Running ?? this.lane2Running,
      lane1FinishedAtMs: lane1FinishedAtMs ?? this.lane1FinishedAtMs,
      lane2FinishedAtMs: lane2FinishedAtMs ?? this.lane2FinishedAtMs,
      roundScored: roundScored ?? this.roundScored,
    );
  }

  /// Check if both lanes have finished their current solve
  bool get bothLanesFinished => lane1.isFinished && lane2.isFinished;

  /// Get the winner based on current times
  String? get currentWinner {
    if (!bothLanesFinished) return null;
    
    final time1 = lane1.currentTimeMs;
    final time2 = lane2.currentTimeMs;
    
    if (time1 == null || time2 == null) return null;
    
    if (time1 < time2) return 'lane1';
    if (time2 < time1) return 'lane2';
    return 'tie';
  }

  @override
  List<Object?> get props => [
        status,
        scrambleLane1,
        scrambleLane2,
        lane1,
        lane2,
        winner,
        useSameScramble,
        lane1Score,
        lane2Score,
        lane1Running,
        lane2Running,
        lane1FinishedAtMs,
        lane2FinishedAtMs,
        roundScored,
      ];
}