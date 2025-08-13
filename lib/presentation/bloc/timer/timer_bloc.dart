import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

import 'timer_event.dart';
import 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  Timer? _holdTimer;
  Timer? _runTimer;
  DateTime? _holdStartTime;
  DateTime? _runStartTime;

  // Timer thresholds in milliseconds
  static const int redThreshold = 0;
  static const int yellowThreshold = 200;
  static const int greenThreshold = 500;

  TimerBloc() : super(TimerState.initial()) {
    on<TimerStartHold>(_onStartHold);
    on<TimerStopHold>(_onStopHold);
    on<TimerTick>(_onTick);
    on<TimerStart>(_onStart);
    on<TimerStop>(_onStop);
    on<TimerReset>(_onReset);
  }

  void _onStartHold(TimerStartHold event, Emitter<TimerState> emit) {
    if (state.status != TimerStatus.idle && state.status != TimerStatus.stopped) return;

    _holdStartTime = DateTime.now();
    emit(state.copyWith(
      status: TimerStatus.holdPending,
      color: TimerColor.red,
      holdDurationMs: 0,
    ));

    _startHoldTimer();
  }

  void _onStopHold(TimerStopHold event, Emitter<TimerState> emit) {
    _holdTimer?.cancel();
    _holdTimer = null;

    if (state.status == TimerStatus.armed) {
      // Released in armed state - start timer
      add(const TimerStart());
    } else {
      // Released before armed - reset to idle
      add(const TimerReset());
    }
  }

  void _onTick(TimerTick event, Emitter<TimerState> emit) {
    if (state.status == TimerStatus.holdPending || state.status == TimerStatus.armed) {
      _updateHoldState(emit);
    } else if (state.status == TimerStatus.running) {
      _updateRunningState(emit);
    }
  }

  void _onStart(TimerStart event, Emitter<TimerState> emit) {
    if (state.status != TimerStatus.armed) return;

    _runStartTime = DateTime.now();
    emit(state.copyWith(
      status: TimerStatus.running,
      color: TimerColor.white,
      elapsedMs: 0,
      startTime: _runStartTime,
    ));

    _startRunTimer();
    _triggerHapticFeedback();
  }

  void _onStop(TimerStop event, Emitter<TimerState> emit) {
    if (state.status != TimerStatus.running) return;

    _runTimer?.cancel();
    _runTimer = null;

    final finalTime = DateTime.now().difference(_runStartTime!).inMilliseconds;
    
    emit(state.copyWith(
      status: TimerStatus.stopped,
      elapsedMs: finalTime,
    ));

    _triggerHapticFeedback();
  }

  void _onReset(TimerReset event, Emitter<TimerState> emit) {
    _holdTimer?.cancel();
    _runTimer?.cancel();
    _holdTimer = null;
    _runTimer = null;
    _holdStartTime = null;
    _runStartTime = null;

    emit(TimerState.initial());
  }

  void _startHoldTimer() {
    _holdTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      add(const TimerTick());
    });
  }

  void _startRunTimer() {
    _runTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      add(const TimerTick());
    });
  }

  void _updateHoldState(Emitter<TimerState> emit) {
    if (_holdStartTime == null) return;

    final holdDuration = DateTime.now().difference(_holdStartTime!).inMilliseconds;
    TimerColor newColor = TimerColor.red; // Start with red since redThreshold is 0
    TimerStatus newStatus = TimerStatus.holdPending;

    if (holdDuration >= greenThreshold) {
      newColor = TimerColor.green;
      newStatus = TimerStatus.armed;
      if (state.status != TimerStatus.armed) {
        _triggerHapticFeedback(); // Haptic when reaching green
      }
    } else if (holdDuration >= yellowThreshold) {
      newColor = TimerColor.yellow;
      if (state.color != TimerColor.yellow) {
        _triggerHapticFeedback(); // Haptic when reaching yellow
      }
    } else if (holdDuration >= redThreshold) {
      newColor = TimerColor.red;
      if (state.color != TimerColor.red) {
        _triggerHapticFeedback(); // Haptic when reaching red
      }
    }

    emit(state.copyWith(
      status: newStatus,
      color: newColor,
      holdDurationMs: holdDuration,
    ));
  }

  void _updateRunningState(Emitter<TimerState> emit) {
    if (_runStartTime == null) return;

    final elapsed = DateTime.now().difference(_runStartTime!).inMilliseconds;
    emit(state.copyWith(elapsedMs: elapsed));
  }

  Future<void> _triggerHapticFeedback() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      // Ignore vibration errors
    }
  }

  @override
  Future<void> close() {
    _holdTimer?.cancel();
    _runTimer?.cancel();
    return super.close();
  }
}