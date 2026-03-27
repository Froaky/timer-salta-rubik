import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/entities/solve.dart';

import '../../support/test_helpers.dart';

void main() {
  group('Solve', () {
    test('applies plus two penalty to effective time and display', () {
      final solve = buildSolve(timeMs: 12345, penalty: Penalty.plus2);

      expect(solve.effectiveTimeMs, 14345);
      expect(solve.formattedTime, '14.35');
      expect(solve.formattedTimeWithPenalty, '14.35+');
    });

    test('represents dnf as invalid effective time', () {
      final solve = buildSolve(timeMs: 12345, penalty: Penalty.dnf);

      expect(solve.isDnf, isTrue);
      expect(solve.effectiveTimeMs, -1);
      expect(solve.formattedTime, 'DNF');
      expect(solve.formattedTimeWithPenalty, 'DNF');
    });

    test('formats minute based solves correctly', () {
      final solve = buildSolve(timeMs: 65432);

      expect(solve.formattedTime, '1:05.43');
      expect(solve.formattedTimeWithPenalty, '1:05.43');
    });

    test('copyWith updates only provided fields', () {
      final original = buildSolve();
      final updated = original.copyWith(
        timeMs: 15000,
        penalty: Penalty.plus2,
      );

      expect(updated.id, original.id);
      expect(updated.sessionId, original.sessionId);
      expect(updated.timeMs, 15000);
      expect(updated.penalty, Penalty.plus2);
      expect(updated.scramble, original.scramble);
    });
  });
}
