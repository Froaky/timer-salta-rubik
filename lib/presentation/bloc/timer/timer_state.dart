import 'package:equatable/equatable.dart';

enum TimerStatus {
  idle,
  holdPending,
  armed,
  running,
  stopped,
}

enum TimerColor {
  white,
  red,
  yellow,
  green,
}

class TimerState extends Equatable {
  final TimerStatus status;
  final TimerColor color;
  final int elapsedMs;
  final int holdDurationMs;
  final DateTime? startTime;

  const TimerState({
    required this.status,
    required this.color,
    required this.elapsedMs,
    required this.holdDurationMs,
    this.startTime,
  });

  factory TimerState.initial() {
    return const TimerState(
      status: TimerStatus.idle,
      color: TimerColor.white,
      elapsedMs: 0,
      holdDurationMs: 0,
    );
  }

  TimerState copyWith({
    TimerStatus? status,
    TimerColor? color,
    int? elapsedMs,
    int? holdDurationMs,
    DateTime? startTime,
  }) {
    return TimerState(
      status: status ?? this.status,
      color: color ?? this.color,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      holdDurationMs: holdDurationMs ?? this.holdDurationMs,
      startTime: startTime ?? this.startTime,
    );
  }

  /// Get formatted time string
  String get formattedTime {
    if (status == TimerStatus.idle) {
      return '0.00';
    }

    final timeToShow = status == TimerStatus.running ? elapsedMs : elapsedMs;
    final seconds = timeToShow / 1000;
    
    if (seconds >= 60) {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toStringAsFixed(2).padLeft(5, '0')}';
    } else {
      return seconds.toStringAsFixed(2);
    }
  }

  /// Check if timer can start (is armed)
  bool get canStart => status == TimerStatus.armed;

  /// Check if timer is running
  bool get isRunning => status == TimerStatus.running;

  /// Check if timer is stopped with a time
  bool get isStopped => status == TimerStatus.stopped;

  @override
  List<Object?> get props => [
        status,
        color,
        elapsedMs,
        holdDurationMs,
        startTime,
      ];
}