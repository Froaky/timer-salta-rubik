import '../../domain/entities/solve.dart';

class SolveModel extends Solve {
  const SolveModel({
    required super.id,
    required super.sessionId,
    required super.timeMs,
    required super.penalty,
    required super.scramble,
    required super.cubeType,
    required super.lane,
    required super.createdAt,
  });

  factory SolveModel.fromEntity(Solve solve) {
    return SolveModel(
      id: solve.id,
      sessionId: solve.sessionId,
      timeMs: solve.timeMs,
      penalty: solve.penalty,
      scramble: solve.scramble,
      cubeType: solve.cubeType,
      lane: solve.lane,
      createdAt: solve.createdAt,
    );
  }

  factory SolveModel.fromMap(Map<String, dynamic> map) {
    return SolveModel(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      timeMs: map['time_ms'] as int,
      penalty: _penaltyFromString(map['penalty'] as String?),
      scramble: map['scramble'] as String,
      cubeType: map['cube_type'] as String? ?? '3x3',
      lane: map['lane'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'time_ms': timeMs,
      'penalty': _penaltyToString(penalty),
      'scramble': scramble,
      'cube_type': cubeType,
      'lane': lane,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static Penalty _penaltyFromString(String? penalty) {
    switch (penalty) {
      case '+2':
        return Penalty.plus2;
      case 'DNF':
        return Penalty.dnf;
      case 'none':
      default:
        return Penalty.none;
    }
  }

  static String _penaltyToString(Penalty penalty) {
    switch (penalty) {
      case Penalty.plus2:
        return '+2';
      case Penalty.dnf:
        return 'DNF';
      case Penalty.none:
        return 'none';
    }
  }
}