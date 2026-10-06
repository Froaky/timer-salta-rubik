import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/timer_thresholds.dart';
import '../../../data/datasources/settings_local_datasource.dart';
import '../../../domain/entities/solve.dart';
import 'timer_event.dart';
import 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final int redThresholdMs;
  final int yellowThresholdMs;
  final int greenThresholdMs;
  final int inspectionDurationMs;
  final int inspectionPlusTwoThresholdMs;
  final int inspectionDnfThresholdMs;

  /// Persists the feature flags across launches. Optional so unit tests can
  /// construct a bloc without touching platform storage.
  final SettingsLocalDataSource? _settingsDataSource;
  Timer? _holdTimer;
  Timer? _runTimer;
  Timer? _inspectionTimer;
  DateTime? _holdStartTime;
  DateTime? _runStartTime;
  DateTime? _inspectionStartTime;
  DateTime? _lastStoppedAt;
  int _inspectionPenaltyMs = 0;
  bool _startedHoldFromInspection = false;
  bool _startedHoldFromStopped = false;

  static const int _stopCooldownMs = 500;

  TimerBloc({
    this.redThresholdMs = TimerThresholds.red,
    this.yellowThresholdMs = TimerThresholds.yellow,
    this.greenThresholdMs = TimerThresholds.green,
    this.inspectionDurationMs = 15000,
    this.inspectionPlusTwoThresholdMs = 15000,
    this.inspectionDnfThresholdMs = 17000,
    SettingsLocalDataSource? settingsDataSource,
  })  : _settingsDataSource = settingsDataSource,
        super(TimerState.initial()) {
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
    on<TimerToggleTapToStart>(_onToggleTapToStart);
    on<TimerStartImmediate>(_onStartImmediate);
    on<TimerLoadSettings>(_onLoadSettings);

    // Restore persisted preferences right away when a store is wired in.
    if (_settingsDataSource != null) {
      add(const TimerLoadSettings());
    }
  }

  void _onStartHold(TimerStartHold event, Emitter<TimerState> emit) {
    final canStart = state.status == TimerStatus.idle ||
        state.status == TimerStatus.stopped ||
        state.status == TimerStatus.inspection;
    if (!canStart) return;

    _startedHoldFromInspection = state.status == TimerStatus.inspection;
    _startedHoldFromStopped = state.status == TimerStatus.stopped;

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
      _startedHoldFromStopped = false;
      if (_startedHoldFromInspection) {
        _startedHoldFromInspection = false;
        add(const TimerStopInspection());
        add(const TimerStart());
      } else if (state.inspectionEnabled) {
        add(const TimerStartInspection());
      } else {
        add(const TimerStart());
      }
      return;
    }

    if (_startedHoldFromStopped) {
      _startedHoldFromStopped = false;
      emit(state.copyWith(
        status: TimerStatus.stopped,
        color: TimerColor.white,
        holdDurationMs: 0,
      ));
      return;
    }

    // Un toque breve durante la inspeccion no debe abortarla: el timer de
    // inspeccion sigue vivo, asi que solo se restaura el estado visual y el
    // reloj de inspeccion continua desde su inicio original (sin resetear
    // el countdown ni esquivar el +2/DNF por exceso).
    if (_startedHoldFromInspection) {
      _startedHoldFromInspection = false;
      emit(state.copyWith(
        status: TimerStatus.inspection,
        color: TimerColor.white,
        holdDurationMs: 0,
      ));
      return;
    }

    add(const TimerReset());
  }

  void _onTick(TimerTick event, Emitter<TimerState> emit) {
    if (state.status == TimerStatus.holdPending ||
        state.status == TimerStatus.armed) {
      _updateHoldState(emit);
    } else if (state.status == TimerStatus.inspection) {
      _updateInspectionState(emit);
    } else if (state.status == TimerStatus.running) {
      _updateRunningState(emit);
    }
  }

  void _onStart(TimerStart event, Emitter<TimerState> emit) {
    if (state.status != TimerStatus.armed) {
      return;
    }

    _runStartTime = DateTime.now();
    emit(state.copyWith(
      status: TimerStatus.running,
      color: TimerColor.white,
      elapsedMs: 0,
      startTime: _runStartTime,
      pendingPenalty: Penalty.none,
    ));

    _startRunTimer();
    _triggerHapticFeedback();
  }

  void _onStop(TimerStop event, Emitter<TimerState> emit) {
    if (state.status != TimerStatus.running) {
      return;
    }

    _runTimer?.cancel();
    _runTimer = null;

    final stoppedAt = event.stoppedAt ?? DateTime.now();
    final baseTime = event.elapsedMsOverride ??
        stoppedAt.difference(_runStartTime!).inMilliseconds;

    // La penalidad de inspeccion se traduce a un Penalty pendiente y se
    // consume aca mismo: si no se limpiara, un +2/DNF de inspeccion
    // contaminaria los solves siguientes que arrancan sin inspeccion.
    final pendingPenalty = switch (_inspectionPenaltyMs) {
      -1 => Penalty.dnf,
      2000 => Penalty.plus2,
      _ => Penalty.none,
    };
    _inspectionPenaltyMs = 0;

    _lastStoppedAt = stoppedAt;

    emit(state.copyWith(
      status: TimerStatus.stopped,
      elapsedMs: baseTime,
      pendingPenalty: pendingPenalty,
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
    _inspectionPenaltyMs = 0;
    _startedHoldFromInspection = false;
    _startedHoldFromStopped = false;
    _lastStoppedAt = null;

    emit(TimerState.initial());
  }

  void _onToggleInspection(
      TimerToggleInspection event, Emitter<TimerState> emit) {
    emit(state.copyWith(inspectionEnabled: !state.inspectionEnabled));
    _persistSettings();
  }

  void _onToggleHideTimer(
      TimerToggleHideTimer event, Emitter<TimerState> emit) {
    emit(state.copyWith(hideTimerEnabled: !state.hideTimerEnabled));
    _persistSettings();
  }

  void _onToggleCompeteMode(
      TimerToggleCompeteMode event, Emitter<TimerState> emit) {
    emit(state.copyWith(competeMode: !state.competeMode));
    _persistSettings();
  }

  void _onToggleTapToStart(
      TimerToggleTapToStart event, Emitter<TimerState> emit) {
    emit(state.copyWith(tapToStartEnabled: !state.tapToStartEnabled));
    _persistSettings();
  }

  Future<void> _onLoadSettings(
      TimerLoadSettings event, Emitter<TimerState> emit) async {
    final store = _settingsDataSource;
    if (store == null) {
      return;
    }

    // Preferencias corruptas o un backend de storage no disponible no deben
    // romper el arranque del timer: simplemente se conservan los defaults.
    try {
      final settings = await store.loadSettings();
      emit(state.copyWith(
        inspectionEnabled: settings.inspectionEnabled,
        hideTimerEnabled: settings.hideTimerEnabled,
        competeMode: settings.competeMode,
        tapToStartEnabled: settings.tapToStartEnabled,
      ));
    } catch (_) {
      // Mantener los valores por defecto.
    }
  }

  // Guardado inmediato y fire-and-forget: el toggle ya emitio el nuevo estado,
  // asi que persistimos el snapshot actual sin bloquear la UI.
  void _persistSettings() {
    final store = _settingsDataSource;
    if (store == null) {
      return;
    }

    unawaited(store.saveSettings(
      TimerSettingsData(
        inspectionEnabled: state.inspectionEnabled,
        hideTimerEnabled: state.hideTimerEnabled,
        competeMode: state.competeMode,
        tapToStartEnabled: state.tapToStartEnabled,
      ),
    ));
  }

  void _onStartImmediate(TimerStartImmediate event, Emitter<TimerState> emit) {
    if (state.status == TimerStatus.inspection) {
      add(const TimerStopInspection());
      add(const TimerStart());
      return;
    }

    if (state.status != TimerStatus.idle &&
        state.status != TimerStatus.stopped) {
      return;
    }

    if (state.status == TimerStatus.stopped &&
        state.tapToStartEnabled &&
        _lastStoppedAt != null &&
        DateTime.now().difference(_lastStoppedAt!).inMilliseconds <
            _stopCooldownMs) {
      return;
    }

    if (state.inspectionEnabled) {
      add(const TimerStartInspection());
      return;
    }

    _runStartTime = DateTime.now();
    emit(state.copyWith(
      status: TimerStatus.running,
      color: TimerColor.white,
      elapsedMs: 0,
      startTime: _runStartTime,
      pendingPenalty: Penalty.none,
    ));

    _startRunTimer();
    _triggerHapticFeedback();
  }

  void _onStartInspection(
      TimerStartInspection event, Emitter<TimerState> emit) {
    if (state.status != TimerStatus.idle &&
        state.status != TimerStatus.stopped &&
        state.status != TimerStatus.armed) {
      return;
    }

    _inspectionStartTime = DateTime.now();
    emit(state.copyWith(
      status: TimerStatus.inspection,
      color: TimerColor.white,
      inspectionRemainingMs: inspectionDurationMs,
    ));

    _startInspectionTimer();
  }

  void _onStopInspection(TimerStopInspection event, Emitter<TimerState> emit) {
    _inspectionTimer?.cancel();
    _inspectionTimer = null;

    if (_inspectionStartTime != null) {
      final inspectionDuration =
          DateTime.now().difference(_inspectionStartTime!).inMilliseconds;

      if (inspectionDuration > inspectionDnfThresholdMs) {
        _inspectionPenaltyMs = -1;
      } else if (inspectionDuration > inspectionPlusTwoThresholdMs) {
        _inspectionPenaltyMs = 2000;
      } else {
        _inspectionPenaltyMs = 0;
      }
    }

    _inspectionStartTime = null;

    emit(state.copyWith(
      status: TimerStatus.armed,
      color: TimerColor.green,
    ));
  }

  void _updateInspectionState(Emitter<TimerState> emit) {
    if (_inspectionStartTime == null) {
      return;
    }

    final elapsed =
        DateTime.now().difference(_inspectionStartTime!).inMilliseconds;
    final remaining = inspectionDurationMs - elapsed;

    emit(state.copyWith(
      inspectionRemainingMs: remaining > 0 ? remaining : 0,
    ));
  }

  void _startInspectionTimer() {
    _inspectionTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
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
    if (_holdStartTime == null) {
      return;
    }

    final holdDuration =
        DateTime.now().difference(_holdStartTime!).inMilliseconds;
    var newColor = TimerColor.red;
    var newStatus = TimerStatus.holdPending;

    if (holdDuration >= greenThresholdMs) {
      newColor = TimerColor.green;
      newStatus = TimerStatus.armed;
      if (state.status != TimerStatus.armed) {
        _triggerHapticFeedback();
      }
    } else if (holdDuration >= yellowThresholdMs) {
      newColor = TimerColor.yellow;
      if (state.color != TimerColor.yellow) {
        _triggerHapticFeedback();
      }
    } else if (holdDuration >= redThresholdMs) {
      newColor = TimerColor.red;
      if (state.color != TimerColor.red) {
        _triggerHapticFeedback();
      }
    }

    emit(state.copyWith(
      status: newStatus,
      color: newColor,
      holdDurationMs: holdDuration,
    ));
  }

  void _updateRunningState(Emitter<TimerState> emit) {
    if (_runStartTime == null) {
      return;
    }

    final elapsed = DateTime.now().difference(_runStartTime!).inMilliseconds;
    emit(state.copyWith(elapsedMs: elapsed));
  }

  Future<void> _triggerHapticFeedback() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }
    } catch (_) {
      // Ignore vibration errors in unsupported environments.
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
