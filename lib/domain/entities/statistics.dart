import 'package:equatable/equatable.dart';
import 'solve.dart';

class Statistics extends Equatable {
  final int? personalBest; // Best single time in ms
  final int? meanOf3; // Current mo3
  final int? averageOf5; // Current ao5
  final int? averageOf12; // Current ao12
  final int? averageOf25; // Current ao25
  final int? averageOf100; // Current ao100
  final int? averageOf200; // Current ao200
  final int? averageOf500; // Current ao500
  final int? averageOf1000; // Current ao1000
  final int? bestMeanOf3; // Best mo3 ever
  final int? bestAverageOf5; // Best ao5 ever
  final int? bestAverageOf12; // Best ao12 ever
  final int? bestAverageOf25; // Best ao25 ever
  final int? bestAverageOf100; // Best ao100 ever
  final int? bestAverageOf200; // Best ao200 ever
  final int? bestAverageOf500; // Best ao500 ever
  final int? bestAverageOf1000; // Best ao1000 ever
  final int totalSolves;
  final List<Solve> recentSolves;

  const Statistics({
    this.personalBest,
    this.meanOf3,
    this.averageOf5,
    this.averageOf12,
    this.averageOf25,
    this.averageOf100,
    this.averageOf200,
    this.averageOf500,
    this.averageOf1000,
    this.bestMeanOf3,
    this.bestAverageOf5,
    this.bestAverageOf12,
    this.bestAverageOf25,
    this.bestAverageOf100,
    this.bestAverageOf200,
    this.bestAverageOf500,
    this.bestAverageOf1000,
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
    final currentAo25 = _calculateAverage(sortedSolves.take(25).toList());
    final currentAo100 = _calculateAverage(sortedSolves.take(100).toList());
    final currentAo200 = _calculateAverage(sortedSolves.take(200).toList());
    final currentAo500 = _calculateAverage(sortedSolves.take(500).toList());
    final currentAo1000 = _calculateAverage(sortedSolves.take(1000).toList());

    // Calculate best averages from all possible windows
    int? bestMo3;
    int? bestAo5;
    int? bestAo12;
    int? bestAo25;
    int? bestAo100;
    int? bestAo200;
    int? bestAo500;
    int? bestAo1000;

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

    // Best ao25
    for (int i = 0; i <= sortedSolves.length - 25; i++) {
      final windowAo25 = _calculateAverage(sortedSolves.skip(i).take(25).toList());
      if (windowAo25 != null) {
        bestAo25 = bestAo25 == null ? windowAo25 : (windowAo25 < bestAo25 ? windowAo25 : bestAo25);
      }
    }

    // Best ao100
    for (int i = 0; i <= sortedSolves.length - 100; i++) {
      final windowAo100 = _calculateAverage(sortedSolves.skip(i).take(100).toList());
      if (windowAo100 != null) {
        bestAo100 = bestAo100 == null ? windowAo100 : (windowAo100 < bestAo100 ? windowAo100 : bestAo100);
      }
    }

    // Best ao200
    for (int i = 0; i <= sortedSolves.length - 200; i++) {
      final windowAo200 = _calculateAverage(sortedSolves.skip(i).take(200).toList());
      if (windowAo200 != null) {
        bestAo200 = bestAo200 == null ? windowAo200 : (windowAo200 < bestAo200 ? windowAo200 : bestAo200);
      }
    }

    // Best ao500
    for (int i = 0; i <= sortedSolves.length - 500; i++) {
      final windowAo500 = _calculateAverage(sortedSolves.skip(i).take(500).toList());
      if (windowAo500 != null) {
        bestAo500 = bestAo500 == null ? windowAo500 : (windowAo500 < bestAo500 ? windowAo500 : bestAo500);
      }
    }

    // Best ao1000
    for (int i = 0; i <= sortedSolves.length - 1000; i++) {
      final windowAo1000 = _calculateAverage(sortedSolves.skip(i).take(1000).toList());
      if (windowAo1000 != null) {
        bestAo1000 = bestAo1000 == null ? windowAo1000 : (windowAo1000 < bestAo1000 ? windowAo1000 : bestAo1000);
      }
    }

    return Statistics(
      personalBest: pb,
      meanOf3: currentMo3,
      averageOf5: currentAo5,
      averageOf12: currentAo12,
      averageOf25: currentAo25,
      averageOf100: currentAo100,
      averageOf200: currentAo200,
      averageOf500: currentAo500,
      averageOf1000: currentAo1000,
      bestMeanOf3: bestMo3,
      bestAverageOf5: bestAo5,
      bestAverageOf12: bestAo12,
      bestAverageOf25: bestAo25,
      bestAverageOf100: bestAo100,
      bestAverageOf200: bestAo200,
      bestAverageOf500: bestAo500,
      bestAverageOf1000: bestAo1000,
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
        averageOf25,
        averageOf100,
        averageOf200,
        averageOf500,
        averageOf1000,
        bestMeanOf3,
        bestAverageOf5,
        bestAverageOf12,
        bestAverageOf25,
        bestAverageOf100,
        bestAverageOf200,
        bestAverageOf500,
        bestAverageOf1000,
        totalSolves,
        recentSolves,
      ];
}