import 'package:equatable/equatable.dart';
import 'solve.dart';

class Statistics extends Equatable {
  final int? personalBest; // Best single time in ms
  final int? meanOf3; // Current mo3
  final int? averageOf5; // Current ao5
  final int? averageOf12; // Current ao12
  final int? bestMeanOf3; // Best mo3 ever
  final int? bestAverageOf5; // Best ao5 ever
  final int? bestAverageOf12; // Best ao12 ever
  final int totalSolves;
  final List<Solve> recentSolves;

  const Statistics({
    this.personalBest,
    this.meanOf3,
    this.averageOf5,
    this.averageOf12,
    this.bestMeanOf3,
    this.bestAverageOf5,
    this.bestAverageOf12,
    required this.totalSolves,
    required this.recentSolves,
  });

  /// Calculate statistics from a list of solves
  factory Statistics.fromSolves(List<Solve> solves) {
    if (solves.isEmpty) {
      return const Statistics(
        totalSolves: 0,
        recentSolves: [],
      );
    }

    // Sort by creation time (most recent first)
    final sortedSolves = List<Solve>.from(solves)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Calculate PB (best single)
    final validSolves = sortedSolves.where((s) => !s.isDnf).toList();
    final pb = validSolves.isEmpty
        ? null
        : validSolves.map((s) => s.effectiveTimeMs).reduce((a, b) => a < b ? a : b);

    // Calculate current averages
    final currentMo3 = _calculateMean(sortedSolves.take(3).toList());
    final currentAo5 = _calculateAverage(sortedSolves.take(5).toList());
    final currentAo12 = _calculateAverage(sortedSolves.take(12).toList());

    // Calculate best averages from all possible windows
    int? bestMo3;
    int? bestAo5;
    int? bestAo12;

    // Best mo3
    for (int i = 0; i <= sortedSolves.length - 3; i++) {
      final windowMo3 = _calculateMean(sortedSolves.skip(i).take(3).toList());
      if (windowMo3 != null) {
        bestMo3 = bestMo3 == null ? windowMo3 : (windowMo3 < bestMo3 ? windowMo3 : bestMo3);
      }
    }

    // Best ao5
    for (int i = 0; i <= sortedSolves.length - 5; i++) {
      final windowAo5 = _calculateAverage(sortedSolves.skip(i).take(5).toList());
      if (windowAo5 != null) {
        bestAo5 = bestAo5 == null ? windowAo5 : (windowAo5 < bestAo5 ? windowAo5 : bestAo5);
      }
    }

    // Best ao12
    for (int i = 0; i <= sortedSolves.length - 12; i++) {
      final windowAo12 = _calculateAverage(sortedSolves.skip(i).take(12).toList());
      if (windowAo12 != null) {
        bestAo12 = bestAo12 == null ? windowAo12 : (windowAo12 < bestAo12 ? windowAo12 : bestAo12);
      }
    }

    return Statistics(
      personalBest: pb,
      meanOf3: currentMo3,
      averageOf5: currentAo5,
      averageOf12: currentAo12,
      bestMeanOf3: bestMo3,
      bestAverageOf5: bestAo5,
      bestAverageOf12: bestAo12,
      totalSolves: solves.length,
      recentSolves: sortedSolves.take(12).toList(),
    );
  }

  /// Calculate mean of 3 (simple average, DNF if any DNF)
  static int? _calculateMean(List<Solve> solves) {
    if (solves.length < 3) return null;
    if (solves.any((s) => s.isDnf)) return null; // DNF if any DNF

    final sum = solves.map((s) => s.effectiveTimeMs).reduce((a, b) => a + b);
    return (sum / 3).round();
  }

  /// Calculate average (remove best and worst, then average)
  /// Returns null if more than 1 DNF or insufficient solves
  static int? _calculateAverage(List<Solve> solves) {
    if (solves.length < 5) return null;

    final dnfCount = solves.where((s) => s.isDnf).length;
    if (dnfCount > 1) return null; // More than 1 DNF = DNF average

    final validTimes = solves
        .where((s) => !s.isDnf)
        .map((s) => s.effectiveTimeMs)
        .toList();

    if (validTimes.length < solves.length - 1) return null;

    validTimes.sort();
    
    // Remove best and worst
    if (dnfCount == 1) {
      // One DNF: remove best time (worst is already DNF)
      validTimes.removeAt(0);
    } else {
      // No DNF: remove both best and worst
      validTimes.removeAt(0); // Remove best
      validTimes.removeAt(validTimes.length - 1); // Remove worst
    }

    if (validTimes.isEmpty) return null;

    final sum = validTimes.reduce((a, b) => a + b);
    return (sum / validTimes.length).round();
  }

  /// Format time in ms to readable string
  static String formatTime(int? timeMs) {
    if (timeMs == null) return '-';
    if (timeMs == -1) return 'DNF';

    final minutes = timeMs ~/ 60000;
    final seconds = (timeMs % 60000) / 1000;

    if (minutes > 0) {
      return '$minutes:${seconds.toStringAsFixed(2).padLeft(5, '0')}';
    } else {
      return seconds.toStringAsFixed(2);
    }
  }

  @override
  List<Object?> get props => [
        personalBest,
        meanOf3,
        averageOf5,
        averageOf12,
        bestMeanOf3,
        bestAverageOf5,
        bestAverageOf12,
        totalSolves,
        recentSolves,
      ];
}