import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/entities/solve.dart';
import 'package:salta_rubik/domain/entities/statistics.dart';

import '../../support/test_helpers.dart';

void main() {
  group('Statistics.fromSolves', () {
    test('returns empty statistics when there are no solves', () {
      final stats = Statistics.fromSolves(const []);

      expect(stats.totalSolves, 0);
      expect(stats.personalBest, isNull);
      expect(stats.meanOf3, isNull);
      expect(stats.averageOf5, isNull);
      expect(stats.recentSolves, isEmpty);
    });

    test('computes pb, current averages, and recent solves order', () {
      final solves = [
        buildSolve(id: '1', timeMs: 11000, createdAt: DateTime(2024, 1, 1)),
        buildSolve(id: '2', timeMs: 10000, createdAt: DateTime(2024, 1, 2)),
        buildSolve(id: '3', timeMs: 9000, createdAt: DateTime(2024, 1, 3)),
        buildSolve(id: '4', timeMs: 12000, createdAt: DateTime(2024, 1, 4)),
        buildSolve(id: '5', timeMs: 13000, createdAt: DateTime(2024, 1, 5)),
      ];

      final stats = Statistics.fromSolves(solves);

      expect(stats.personalBest, 9000);
      expect(stats.meanOf3, 11333);
      expect(stats.averageOf5, 11000);
      expect(stats.averageOf12, isNull);
      expect(stats.averageOf25, isNull);
      expect(stats.averageOf100, isNull);
      expect(stats.bestMeanOf3, 10000);
      expect(stats.bestAverageOf5, 11000);
      expect(stats.bestAverageOf12, isNull);
      expect(stats.totalSolves, 5);
      expect(stats.recentSolves.map((solve) => solve.id),
          ['5', '4', '3', '2', '1']);
    });

    test('handles a single dnf in average of five', () {
      final solves = [
        buildSolve(id: '1', timeMs: 10000, createdAt: DateTime(2024, 1, 1)),
        buildSolve(id: '2', timeMs: 11000, createdAt: DateTime(2024, 1, 2)),
        buildSolve(id: '3', timeMs: 12000, createdAt: DateTime(2024, 1, 3)),
        buildSolve(id: '4', timeMs: 13000, createdAt: DateTime(2024, 1, 4)),
        buildSolve(
          id: '5',
          timeMs: 14000,
          penalty: Penalty.dnf,
          createdAt: DateTime(2024, 1, 5),
        ),
      ];

      final stats = Statistics.fromSolves(solves);

      expect(stats.averageOf5, 12000);
    });

    test('returns null average when window contains two dnfs', () {
      final solves = [
        buildSolve(id: '1', timeMs: 10000, createdAt: DateTime(2024, 1, 1)),
        buildSolve(
          id: '2',
          timeMs: 11000,
          penalty: Penalty.dnf,
          createdAt: DateTime(2024, 1, 2),
        ),
        buildSolve(id: '3', timeMs: 12000, createdAt: DateTime(2024, 1, 3)),
        buildSolve(
          id: '4',
          timeMs: 13000,
          penalty: Penalty.dnf,
          createdAt: DateTime(2024, 1, 4),
        ),
        buildSolve(id: '5', timeMs: 14000, createdAt: DateTime(2024, 1, 5)),
      ];

      final stats = Statistics.fromSolves(solves);

      expect(stats.averageOf5, isNull);
    });
  });

  group('Statistics.formatTime', () {
    test('formats null and dnf values', () {
      expect(Statistics.formatTime(null), '-');
      expect(Statistics.formatTime(-1), 'DNF');
    });

    test('formats milliseconds into minutes when needed', () {
      expect(Statistics.formatTime(9050), '9.05');
      expect(Statistics.formatTime(65432), '1:05.43');
    });
  });
}
