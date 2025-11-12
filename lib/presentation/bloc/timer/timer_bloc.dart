import 'dart:async';
import '../../../core/constants/timer_thresholds.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

import 'timer_event.dart';
import 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  Timer? _holdTimer;
  Timer? _runTimer;
  Timer? _inspectionTimer;
  DateTime? _holdStartTime;
  DateTime? _runStartTime;
  DateTime? _inspectionStartTime;
  int _inspectionPenaltyMs = 0; // Penalización por inspección WCA

  // Timer thresholds in milliseconds (shared constants)
  static const int redThreshold = TimerThresholds.red;
  static const int yellowThreshold = TimerThresholds.yellow;
  static const int greenThreshold = TimerThresholds.green;

  TimerBloc() : super(TimerState.initial()) {
    on<TimerStartHold>(_onStartHold);
    on<TimerStopHold>(_onStopHold);
    on<TimerTick>(_onTick);
    on<TimerStart>(_onStart);
    on<TimerStop>(_onStop);
    on<TimerReset>(_onReset);
    on<TimerToggleInspection>(_onToggleInspection);
    on<TimerToggleHideTimer>(_onToggleHideTimer);
    on<TimerStartInspection>(_onStartInspection);
    on<TimerStopInspection>(_onStopInspection);
    on<TimerToggleCompeteMode>(_onToggleCompeteMode);
  }

  void _onStartHold(TimerStartHold event, Emitter<TimerState> emit) {
    if (state.status != TimerStatus.idle && state.status != TimerStatus.stopped) return;

    // Si la inspección está habilitada, iniciar inspección en lugar de hold
    if (state.inspectionEnabled) {
      add(const TimerStartInspection());
      return;
    }

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

    // Si está en inspección, detenerla y comenzar el timer real
    if (state.status == TimerStatus.inspection) {
      add(const TimerStopInspection());
      return;
    }

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
    } else if (state.status == TimerStatus.inspection) {
      _updateInspectionState(emit);
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

    final baseTime = DateTime.now().difference(_runStartTime!).inMilliseconds;
    
    // Aplicar penalización de inspección si existe
    final finalTime = _inspectionPenaltyMs == -1 
        ? -1 // DNF
        : baseTime + _inspectionPenaltyMs;
    
    emit(state.copyWith(
      status: TimerStatus.stopped,
      elapsedMs: finalTime,
    ));

    _triggerHapticFeedback();
  }

  void _onReset(TimerReset event, Emitter<TimerState> emit) {
    _holdTimer?.cancel();
    _runTimer?.cancel();
    _inspectionTimer?.cancel();
    _holdTimer = null;
    _runTimer = null;
    _inspectionTimer = null;
    _holdStartTime = null;
    _runStartTime = null;
    _inspectionStartTime = null;
    _inspectionPenaltyMs = 0; // Limpiar penalización

    emit(TimerState.initial());
  }

  void _onToggleInspection(TimerToggleInspection event, Emitter<TimerState> emit) {
    emit(state.copyWith(inspectionEnabled: !state.inspectionEnabled));
  }

  void _onToggleHideTimer(TimerToggleHideTimer event, Emitter<TimerState> emit) {
    emit(state.copyWith(hideTimerEnabled: !state.hideTimerEnabled));
  }

  void _onToggleCompeteMode(TimerToggleCompeteMode event, Emitter<TimerState> emit) {
    emit(state.copyWith(competeMode: !state.competeMode));
  }

  void _onStartInspection(TimerStartInspection event, Emitter<TimerState> emit) {
    if (state.status != TimerStatus.idle && state.status != TimerStatus.stopped) return;

    _inspectionStartTime = DateTime.now();
    emit(state.copyWith(
      status: TimerStatus.inspection,
      color: TimerColor.white,
      inspectionRemainingMs: 15000,
    ));

    _startInspectionTimer();
  }

  void _onStopInspection(TimerStopInspection event, Emitter<TimerState> emit) {
    _inspectionTimer?.cancel();
    _inspectionTimer = null;
    
    // Calcular penalización WCA basada en el tiempo de inspección
    if (_inspectionStartTime != null) {
      final inspectionDuration = DateTime.now().difference(_inspectionStartTime!).inMilliseconds;
      
      // Reglas WCA: +2 si entre 15-17 segundos, DNF si más de 17 segundos
      if (inspectionDuration > 17000) {
        _inspectionPenaltyMs = -1; // DNF
      } else if (inspectionDuration > 15000) {
        _inspectionPenaltyMs = 2000; // +2 segundos
      } else {
        _inspectionPenaltyMs = 0; // Sin penalización
      }
    }
    
    _inspectionStartTime = null;

    // Pasar al estado armed para comenzar el timer real
    emit(state.copyWith(
      status: TimerStatus.armed,
      color: TimerColor.green,
    ));
  }

  void _updateInspectionState(Emitter<TimerState> emit) {
    if (_inspectionStartTime == null) return;

    final elapsed = DateTime.now().difference(_inspectionStartTime!).inMilliseconds;
    final remaining = 15000 - elapsed;

    if (remaining <= 0) {
      // Inspección terminada, pasar a armed automáticamente
      _inspectionTimer?.cancel();
      _inspectionTimer = null;
      emit(state.copyWith(
        status: TimerStatus.armed,
        color: TimerColor.green,
        inspectionRemainingMs: 0,
      ));
      _triggerHapticFeedback();
    } else {
      emit(state.copyWith(inspectionRemainingMs: remaining));
    }
  }

  void _startInspectionTimer() {
    _inspectionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      add(const TimerTick());
    });
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
    _inspectionTimer?.cancel();
    return super.close();
  }
}