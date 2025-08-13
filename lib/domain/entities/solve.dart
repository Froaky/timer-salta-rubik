import 'package:equatable/equatable.dart';

enum Penalty { none, plus2, dnf }

class Solve extends Equatable {
  final String id;
  final String sessionId;
  final int timeMs;
  final Penalty penalty;
  final String scramble;
  final String cubeType;
  final int lane; // 0 for single, 1-2 for compete mode
  final DateTime createdAt;

  const Solve({
    required this.id,
    required this.sessionId,
    required this.timeMs,
    required this.penalty,
    required this.scramble,
    required this.cubeType,
    required this.lane,
    required this.createdAt,
  });

  /// Get effective time considering penalty
  int get effectiveTimeMs {
    switch (penalty) {
      case Penalty.plus2:
        return timeMs + 2000;
      case Penalty.dnf:
        return -1; // DNF represented as -1
      case Penalty.none:
        return timeMs;
    }
  }

  /// Check if solve is DNF
  bool get isDnf => penalty == Penalty.dnf;

  /// Get formatted time string
  String get formattedTime {
    if (isDnf) return 'DNF';
    
    final effectiveTime = effectiveTimeMs;
    final minutes = effectiveTime ~/ 60000;
    final seconds = (effectiveTime % 60000) / 1000;
    
    if (minutes > 0) {
      return '$minutes:${seconds.toStringAsFixed(2).padLeft(5, '0')}';
    } else {
      return seconds.toStringAsFixed(2);
    }
  }

  /// Get formatted time with penalty indicator
  String get formattedTimeWithPenalty {
    if (penalty == Penalty.dnf) return 'DNF';
    if (penalty == Penalty.plus2) return '$formattedTime+';
    return formattedTime;
  }

  Solve copyWith({
    String? id,
    String? sessionId,
    int? timeMs,
    Penalty? penalty,
    String? scramble,
    String? cubeType,
    int? lane,
    DateTime? createdAt,
  }) {
    return Solve(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timeMs: timeMs ?? this.timeMs,
      penalty: penalty ?? this.penalty,
      scramble: scramble ?? this.scramble,
      cubeType: cubeType ?? this.cubeType,
      lane: lane ?? this.lane,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        timeMs,
        penalty,
        scramble,
        cubeType,
        lane,
        createdAt,
      ];
}