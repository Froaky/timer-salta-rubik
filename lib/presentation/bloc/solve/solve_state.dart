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
  static const _unset = Object();

  final SolveStatus status;
  final String? sessionId;
  final List<Solve> solves;
  final Statistics? statistics;
  final Scramble? currentScramble;
  final String? errorMessage;
  final bool isGeneratingScramble;

  const SolveState({
    required this.status,
    this.sessionId,
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
    Object? sessionId = _unset,
    List<Solve>? solves,
    Object? statistics = _unset,
    Object? currentScramble = _unset,
    Object? errorMessage = _unset,
    bool? isGeneratingScramble,
  }) {
    return SolveState(
      status: status ?? this.status,
      sessionId:
          identical(sessionId, _unset) ? this.sessionId : sessionId as String?,
      solves: solves ?? this.solves,
      statistics: identical(statistics, _unset)
          ? this.statistics
          : statistics as Statistics?,
      currentScramble: identical(currentScramble, _unset)
          ? this.currentScramble
          : currentScramble as Scramble?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      isGeneratingScramble: isGeneratingScramble ?? this.isGeneratingScramble,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sessionId,
        solves,
        statistics,
        currentScramble,
        errorMessage,
        isGeneratingScramble,
      ];
}
