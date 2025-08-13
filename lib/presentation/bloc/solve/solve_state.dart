import 'package:equatable/equatable.dart';

import '../../../domain/entities/solve.dart';
import '../../../domain/entities/statistics.dart';
import '../../../domain/entities/scramble.dart';

enum SolveStatus {
  initial,
  loading,
  loaded,
  error,
}

class SolveState extends Equatable {
  final SolveStatus status;
  final List<Solve> solves;
  final Statistics? statistics;
  final Scramble? currentScramble;
  final String? errorMessage;
  final bool isGeneratingScramble;

  const SolveState({
    required this.status,
    required this.solves,
    this.statistics,
    this.currentScramble,
    this.errorMessage,
    this.isGeneratingScramble = false,
  });

  factory SolveState.initial() {
    return const SolveState(
      status: SolveStatus.initial,
      solves: [],
    );
  }

  SolveState copyWith({
    SolveStatus? status,
    List<Solve>? solves,
    Statistics? statistics,
    Scramble? currentScramble,
    String? errorMessage,
    bool? isGeneratingScramble,
  }) {
    return SolveState(
      status: status ?? this.status,
      solves: solves ?? this.solves,
      statistics: statistics ?? this.statistics,
      currentScramble: currentScramble ?? this.currentScramble,
      errorMessage: errorMessage ?? this.errorMessage,
      isGeneratingScramble: isGeneratingScramble ?? this.isGeneratingScramble,
    );
  }

  @override
  List<Object?> get props => [
        status,
        solves,
        statistics,
        currentScramble,
        errorMessage,
        isGeneratingScramble,
      ];
}