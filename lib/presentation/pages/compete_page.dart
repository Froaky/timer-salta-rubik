import 'dart:async';

import '../../core/constants/timer_thresholds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

import '../../domain/entities/solve.dart';
import '../../domain/entities/scramble.dart';

import '../bloc/compete/compete_bloc.dart';
import '../bloc/compete/compete_event.dart';
import '../bloc/compete/compete_state.dart';
import '../bloc/session/session_bloc.dart';
import '../bloc/session/session_state.dart';
import '../theme/app_theme.dart';
import '../widgets/category_icon.dart';

// Timer states and colors (same as main timer)
enum CompeteTimerStatus {
  idle,
  holdPending,
  armed,
  running,
  stopped,
}

enum CompeteTimerColor {
  white,
  red,
  yellow,
  green,
}

bool shouldIgnoreCompeteLaneInteraction({
  required CompeteTimerStatus laneStatus,
  required CompeteTimerStatus otherLaneStatus,
}) {
  return laneStatus == CompeteTimerStatus.stopped &&
      otherLaneStatus == CompeteTimerStatus.running;
}

class CompetePage extends StatefulWidget {
  const CompetePage({super.key});

  @override
  State<CompetePage> createState() => _CompetePageState();
}

class _CompetePageState extends State<CompetePage> {
  String? _selectedCubeType;
  bool _useSameScramble = true;
  bool _lane1ReleasedForSyncStart = false;
  bool _lane2ReleasedForSyncStart = false;

  // Timer states for each lane (exactly like main timer)
  CompeteTimerStatus _lane1Status = CompeteTimerStatus.idle;
  CompeteTimerStatus _lane2Status = CompeteTimerStatus.idle;
  CompeteTimerColor _lane1Color = CompeteTimerColor.white;
  CompeteTimerColor _lane2Color = CompeteTimerColor.white;

  // Timer data
  int _lane1ElapsedMs = 0;
  int _lane2ElapsedMs = 0;
  int _lane1HoldDurationMs = 0;
  int _lane2HoldDurationMs = 0;

  // Timer management
  Timer? _lane1HoldTimer;
  Timer? _lane2HoldTimer;
  Timer? _lane1RunTimer;
  Timer? _lane2RunTimer;
  // Usar reloj monotónico (Stopwatch) también para el hold
  Stopwatch? _lane1HoldStopwatch;
  Stopwatch? _lane2HoldStopwatch;
  // Use monotonic clocks via Stopwatch for competition timers
  Stopwatch? _competitionRunStopwatch;

  // Timer thresholds (same as main timer)
  static const int redThreshold = TimerThresholds.red;
  static const int yellowThreshold = TimerThresholds.yellow;
  static const int greenThreshold = TimerThresholds.green;

  @override
  void dispose() {
    _lane1HoldTimer?.cancel();
    _lane2HoldTimer?.cancel();
    _lane1RunTimer?.cancel();
    _lane2RunTimer?.cancel();
    _competitionRunStopwatch?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competencia'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CompeteBloc>().add(const ResetCompete());
              _resetAllTimers();
            },
          ),
        ],
      ),
      body: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, sessionState) {
          return BlocBuilder<CompeteBloc, CompeteState>(
            builder: (context, competeState) {
              if (competeState.status == CompeteStatus.initial) {
                return _buildSetupScreen(sessionState);
              }

              return _buildCompeteScreen(competeState);
            },
          );
        },
      ),
    );
  }

  Widget _buildSetupScreen(SessionState sessionState) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports_esports,
            size: 80,
            color: AppTheme.accentColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Configurar Competencia',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Cube type selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de Cubo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCubeType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Selecciona el tipo de cubo',
                    ),
                    items: const [
                      '3x3',
                      '2x2',
                      '4x4',
                      '5x5',
                      '6x6',
                      '7x7',
                      'pyraminx',
                      'megaminx',
                      'skewb',
                      'clock',
                      'sq1'
                    ].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            CategoryIcon(
                              cubeType: type,
                              size: 18,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.92),
                              backgroundPadding: const EdgeInsets.all(4),
                              backgroundRadius: 6,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                type.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCubeType = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Same scramble option
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Usar el mismo scramble para ambos jugadores',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Switch(
                    value: _useSameScramble,
                    onChanged: (value) {
                      setState(() {
                        _useSameScramble = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedCubeType != null
                  ? () {
                      // Reset all timers first
                      _resetAllTimers();

                      // Start compete round
                      context.read<CompeteBloc>().add(
                            StartCompeteRound(
                              cubeType: _selectedCubeType!,
                              useSameScramble: _useSameScramble,
                            ),
                          );
                    }
                  : null,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Iniciar Competencia',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompeteScreen(CompeteState competeState) {
    return Stack(
      children: [
        // Dual timer lanes - full screen
        Column(
          children: [
            // Lane 2 (top - inverted)
            Expanded(
              child: _buildLane(
                laneNumber: 2,
                laneData: competeState.lane2,
                scramble: competeState.scrambleLane2,
                isInverted: true,
                competeState: competeState,
              ),
            ),

            // Lane 1 (bottom - normal)
            Expanded(
              child: _buildLane(
                laneNumber: 1,
                laneData: competeState.lane1,
                scramble: competeState.scrambleLane1,
                isInverted: false,
                competeState: competeState,
              ),
            ),
          ],
        ),

        // Centered score display - clickeable
        Center(
          child: GestureDetector(
            onTap: () => _showCompetitionResults(competeState),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${competeState.lane1Score}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${competeState.lane2Score}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isLaneInteractionLocked(int laneNumber) {
    final laneStatus = laneNumber == 1 ? _lane1Status : _lane2Status;
    final otherLaneStatus = laneNumber == 1 ? _lane2Status : _lane1Status;

    return shouldIgnoreCompeteLaneInteraction(
      laneStatus: laneStatus,
      otherLaneStatus: otherLaneStatus,
    );
  }

  Widget _buildLane({
    required int laneNumber,
    required LaneData laneData,
    required Scramble? scramble,
    required bool isInverted,
    required CompeteState competeState,
  }) {
    // Get timer state for this lane
    final status = laneNumber == 1 ? _lane1Status : _lane2Status;
    final color = laneNumber == 1 ? _lane1Color : _lane2Color;
    final elapsedMs = laneNumber == 1 ? _lane1ElapsedMs : _lane2ElapsedMs;

    // Get display time and color
    final displayTime = _getFormattedTime(elapsedMs, status);
    final timerColor = _getTimerColor(color);
    final scrambleTextColor = _getScrambleTextColor(color);
    final showScramble =
        scramble != null && competeState.status != CompeteStatus.inProgress;

    Widget content = Listener(
      key: ValueKey('compete-lane-$laneNumber'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (_isLaneInteractionLocked(laneNumber)) return;

        if (laneNumber == 1) {
          if (status == CompeteTimerStatus.running) {
            _stopLane1Timer();
          } else {
            _onLane1TapDown();
          }
        } else {
          if (status == CompeteTimerStatus.running) {
            _stopLane2Timer();
          } else {
            _onLane2TapDown();
          }
        }
      },
      onPointerUp: (_) {
        if (_isLaneInteractionLocked(laneNumber)) return;

        if (laneNumber == 1) {
          _onLane1TapUp();
        } else {
          _onLane2TapUp();
        }
      },
      onPointerCancel: (_) {
        if (_isLaneInteractionLocked(laneNumber)) return;

        if (laneNumber == 1) {
          _onLane1TapCancel();
        } else {
          _onLane2TapCancel();
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: timerColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showScramble)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _buildScrambleDisplay(
                  scramble,
                  laneNumber: laneNumber,
                  textColor: scrambleTextColor,
                ),
              ),

            if (showScramble) const SizedBox(height: 12),

            // Timer display
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayTime,
                key: ValueKey('compete-lane-$laneNumber-timer'),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: color == CompeteTimerColor.white
                          ? Colors.black
                          : Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            const SizedBox(height: 8),

            // Player label
            Text(
              'Jugador $laneNumber',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color == CompeteTimerColor.white
                        ? Colors.black54
                        : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );

    // Invert content if needed
    if (isInverted) {
      content = Transform.rotate(
        angle: 3.14159, // 180 degrees
        child: content,
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: content,
    );
  }

  String _formatTime(int milliseconds) {
    final seconds = milliseconds / 1000;
    if (seconds < 60) {
      return seconds.toStringAsFixed(2);
    } else {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toStringAsFixed(2).padLeft(5, '0')}';
    }
  }

  Widget _buildScrambleDisplay(
    Scramble? scramble, {
    required int laneNumber,
    required Color textColor,
  }) {
    if (scramble == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final fontSize = width < 320 ? 10.0 : 11.0;

        return Text(
          scramble.notation,
          key: ValueKey('compete-lane-$laneNumber-scramble'),
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.15,
            color: textColor,
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        );
      },
    );
  }

  void _showCompetitionResults(CompeteState competeState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resultados de la Competencia'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Jugador 1
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jugador 1',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      if (competeState.lane1.solves.isEmpty)
                        const Text('Sin tiempos registrados')
                      else
                        ...competeState.lane1.solves.map((solve) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(_formatTime(solve.timeMs)),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Jugador 2
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jugador 2',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      if (competeState.lane2.solves.isEmpty)
                        const Text('Sin tiempos registrados')
                      else
                        ...competeState.lane2.solves.map((solve) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(_formatTime(solve.timeMs)),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Timer management methods (exactly like main timer)
  void _resetAllTimers() {
    setState(() {
      _lane1Status = CompeteTimerStatus.idle;
      _lane2Status = CompeteTimerStatus.idle;
      _lane1Color = CompeteTimerColor.white;
      _lane2Color = CompeteTimerColor.white;
      _lane1ElapsedMs = 0;
      _lane2ElapsedMs = 0;
      _lane1HoldDurationMs = 0;
      _lane2HoldDurationMs = 0;
    });

    _lane1HoldTimer?.cancel();
    _lane2HoldTimer?.cancel();
    _lane1RunTimer?.cancel();
    _lane2RunTimer?.cancel();
    _lane1HoldTimer = null;
    _lane2HoldTimer = null;
    _lane1RunTimer = null;
    _lane2RunTimer = null;
    _lane1HoldStopwatch?.stop();
    _lane2HoldStopwatch?.stop();
    _lane1HoldStopwatch = null;
    _lane2HoldStopwatch = null;
    _competitionRunStopwatch?.stop();
    _competitionRunStopwatch = null;
    _lane1ReleasedForSyncStart = false;
    _lane2ReleasedForSyncStart = false;
  }

  // Lane 1 timer methods
  void _onLane1TapDown() {
    if (_lane1Status != CompeteTimerStatus.idle &&
        _lane1Status != CompeteTimerStatus.stopped) return;

    _lane1HoldStopwatch = Stopwatch()..start();
    setState(() {
      _lane1Status = CompeteTimerStatus.holdPending;
      _lane1Color = CompeteTimerColor.red;
      _lane1HoldDurationMs = 0;
    });

    _startLane1HoldTimer();
  }

  void _onLane1TapUp() {
    final holdDuration =
        _lane1HoldStopwatch?.elapsedMilliseconds ?? _lane1HoldDurationMs;

    _lane1HoldTimer?.cancel();
    _lane1HoldTimer = null;
    _lane1HoldStopwatch?.stop();
    _lane1HoldStopwatch = null;

    if (_lane1Status == CompeteTimerStatus.armed ||
        holdDuration >= greenThreshold) {
      if (_lane1Status != CompeteTimerStatus.armed) {
        setState(() {
          _lane1Status = CompeteTimerStatus.armed;
          _lane1Color = CompeteTimerColor.green;
          _lane1HoldDurationMs = holdDuration;
        });
      }

      _handleArmedLaneRelease(lane: 1);
    } else if (_lane1Status == CompeteTimerStatus.holdPending) {
      _resetAllTimers();
    }
  }

  void _onLane1TapCancel() {
    _lane1HoldTimer?.cancel();
    _lane1HoldTimer = null;
    _lane1HoldStopwatch?.stop();
    _lane1HoldStopwatch = null;
    _resetAllTimers();
  }

  void _handleArmedLaneRelease({required int lane}) {
    final otherLaneHoldDuration = lane == 1
        ? _lane2HoldStopwatch?.elapsedMilliseconds ?? _lane2HoldDurationMs
        : _lane1HoldStopwatch?.elapsedMilliseconds ?? _lane1HoldDurationMs;
    final otherLaneReady = otherLaneHoldDuration >= greenThreshold ||
        (lane == 1 ? _lane2ReleasedForSyncStart : _lane1ReleasedForSyncStart);

    if (!otherLaneReady) {
      _resetAllTimers();
      return;
    }

    setState(() {
      if (lane == 1) {
        _lane1ReleasedForSyncStart = true;
      } else {
        _lane2ReleasedForSyncStart = true;
      }
    });

    _tryStartCompetitionTimers();
  }

  void _tryStartCompetitionTimers() {
    if (_competitionRunStopwatch != null) {
      return;
    }

    if (_lane1Status != CompeteTimerStatus.armed ||
        _lane2Status != CompeteTimerStatus.armed ||
        !_lane1ReleasedForSyncStart ||
        !_lane2ReleasedForSyncStart) {
      return;
    }

    _startCompetitionTimers();
  }

  void _startCompetitionTimers() {
    _lane1RunTimer?.cancel();
    _lane2RunTimer?.cancel();
    _lane1RunTimer = null;
    _lane2RunTimer = null;
    _competitionRunStopwatch?.stop();
    _competitionRunStopwatch = Stopwatch()..start();

    setState(() {
      _lane1Status = CompeteTimerStatus.running;
      _lane2Status = CompeteTimerStatus.running;
      _lane1Color = CompeteTimerColor.white;
      _lane2Color = CompeteTimerColor.white;
      _lane1ElapsedMs = 0;
      _lane2ElapsedMs = 0;
      _lane1HoldDurationMs = 0;
      _lane2HoldDurationMs = 0;
      _lane1ReleasedForSyncStart = false;
      _lane2ReleasedForSyncStart = false;
    });

    _startLane1RunTimer();
    _startLane2RunTimer();
    _triggerHapticFeedback();
    context.read<CompeteBloc>().add(const StartLane(lane: 1));
    context.read<CompeteBloc>().add(const StartLane(lane: 2));
  }

  void _stopLane1Timer() {
    if (_lane1Status != CompeteTimerStatus.running) return;

    _lane1RunTimer?.cancel();
    _lane1RunTimer = null;
    final currentState = context.read<CompeteBloc>().state;
    final finalTime =
        _competitionRunStopwatch?.elapsedMilliseconds ?? _lane1ElapsedMs;
    final scrambleNotation = currentState.scrambleLane1?.notation;
    final isLastRunningLane = _lane2Status != CompeteTimerStatus.running;

    if (isLastRunningLane) {
      _competitionRunStopwatch?.stop();
      _competitionRunStopwatch = null;
    }

    setState(() {
      _lane1Status = CompeteTimerStatus.stopped;
      _lane1ElapsedMs = finalTime;
    });

    _triggerHapticFeedback();
    _saveLane1Solve(finalTime, scrambleNotation);
    context.read<CompeteBloc>().add(StopLane(lane: 1, finishedAtMs: finalTime));
  }

  // Lane 2 timer methods
  void _onLane2TapDown() {
    if (_lane2Status != CompeteTimerStatus.idle &&
        _lane2Status != CompeteTimerStatus.stopped) return;

    _lane2HoldStopwatch = Stopwatch()..start();
    setState(() {
      _lane2Status = CompeteTimerStatus.holdPending;
      _lane2Color = CompeteTimerColor.red;
      _lane2HoldDurationMs = 0;
    });

    _startLane2HoldTimer();
  }

  void _onLane2TapUp() {
    final holdDuration =
        _lane2HoldStopwatch?.elapsedMilliseconds ?? _lane2HoldDurationMs;

    _lane2HoldTimer?.cancel();
    _lane2HoldTimer = null;
    _lane2HoldStopwatch?.stop();
    _lane2HoldStopwatch = null;

    if (_lane2Status == CompeteTimerStatus.armed ||
        holdDuration >= greenThreshold) {
      if (_lane2Status != CompeteTimerStatus.armed) {
        setState(() {
          _lane2Status = CompeteTimerStatus.armed;
          _lane2Color = CompeteTimerColor.green;
          _lane2HoldDurationMs = holdDuration;
        });
      }

      _handleArmedLaneRelease(lane: 2);
    } else if (_lane2Status == CompeteTimerStatus.holdPending) {
      _resetAllTimers();
    }
  }

  void _onLane2TapCancel() {
    _lane2HoldTimer?.cancel();
    _lane2HoldTimer = null;
    _lane2HoldStopwatch?.stop();
    _lane2HoldStopwatch = null;
    _resetAllTimers();
  }

  void _stopLane2Timer() {
    if (_lane2Status != CompeteTimerStatus.running) return;

    _lane2RunTimer?.cancel();
    _lane2RunTimer = null;
    final currentState = context.read<CompeteBloc>().state;
    final finalTime =
        _competitionRunStopwatch?.elapsedMilliseconds ?? _lane2ElapsedMs;
    final scrambleNotation = currentState.scrambleLane2?.notation;
    final isLastRunningLane = _lane1Status != CompeteTimerStatus.running;

    if (isLastRunningLane) {
      _competitionRunStopwatch?.stop();
      _competitionRunStopwatch = null;
    }

    setState(() {
      _lane2Status = CompeteTimerStatus.stopped;
      _lane2ElapsedMs = finalTime;
    });

    _triggerHapticFeedback();
    _saveLane2Solve(finalTime, scrambleNotation);
    context.read<CompeteBloc>().add(StopLane(lane: 2, finishedAtMs: finalTime));
  }

  // Timer update methods
  void _startLane1HoldTimer() {
    _lane1HoldTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _updateLane1HoldState();
    });
  }

  void _startLane2HoldTimer() {
    _lane2HoldTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _updateLane2HoldState();
    });
  }

  void _startLane1RunTimer() {
    _lane1RunTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _updateLane1RunningState();
    });
  }

  void _startLane2RunTimer() {
    _lane2RunTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _updateLane2RunningState();
    });
  }

  void _updateLane1HoldState() {
    if (_lane1HoldStopwatch == null) return;

    final holdDuration = _lane1HoldStopwatch!.elapsedMilliseconds;
    CompeteTimerColor newColor = CompeteTimerColor.red;
    CompeteTimerStatus newStatus = CompeteTimerStatus.holdPending;

    // Check if we were in stopped state and need to reset
    final wasInStoppedState = _lane1Status == CompeteTimerStatus.stopped;

    if (holdDuration >= greenThreshold) {
      newColor = CompeteTimerColor.green;
      if (wasInStoppedState) {
        // Reset to idle when holding from stopped state
        newStatus = CompeteTimerStatus.idle;
        _lane1HoldTimer?.cancel();
        _lane1HoldTimer = null;
        _lane1HoldStopwatch?.stop();
        _lane1HoldStopwatch = null;
        setState(() {
          _lane1Status = CompeteTimerStatus.idle;
          _lane1Color = CompeteTimerColor.white;
          _lane1ElapsedMs = 0;
          _lane1HoldDurationMs = 0;
        });
        _triggerHapticFeedback();
        return;
      } else {
        newStatus = CompeteTimerStatus.armed;
        if (_lane1Status != CompeteTimerStatus.armed) {
          _triggerHapticFeedback();
        }
      }
    } else if (holdDuration >= yellowThreshold) {
      newColor = CompeteTimerColor.yellow;
      if (_lane1Color != CompeteTimerColor.yellow) {
        _triggerHapticFeedback();
      }
    } else if (holdDuration >= redThreshold) {
      newColor = CompeteTimerColor.red;
      if (_lane1Color != CompeteTimerColor.red) {
        _triggerHapticFeedback();
      }
    }

    setState(() {
      _lane1Status = newStatus;
      _lane1Color = newColor;
      _lane1HoldDurationMs = holdDuration;
    });
  }

  void _updateLane2HoldState() {
    if (_lane2HoldStopwatch == null) return;

    final holdDuration = _lane2HoldStopwatch!.elapsedMilliseconds;
    CompeteTimerColor newColor = CompeteTimerColor.red;
    CompeteTimerStatus newStatus = CompeteTimerStatus.holdPending;

    // Check if we were in stopped state and need to reset
    final wasInStoppedState = _lane2Status == CompeteTimerStatus.stopped;

    if (holdDuration >= greenThreshold) {
      newColor = CompeteTimerColor.green;
      if (wasInStoppedState) {
        // Reset to idle when holding from stopped state
        newStatus = CompeteTimerStatus.idle;
        _lane2HoldTimer?.cancel();
        _lane2HoldTimer = null;
        _lane2HoldStopwatch?.stop();
        _lane2HoldStopwatch = null;
        setState(() {
          _lane2Status = CompeteTimerStatus.idle;
          _lane2Color = CompeteTimerColor.white;
          _lane2ElapsedMs = 0;
          _lane2HoldDurationMs = 0;
        });
        _triggerHapticFeedback();
        return;
      } else {
        newStatus = CompeteTimerStatus.armed;
        if (_lane2Status != CompeteTimerStatus.armed) {
          _triggerHapticFeedback();
        }
      }
    } else if (holdDuration >= yellowThreshold) {
      newColor = CompeteTimerColor.yellow;
      if (_lane2Color != CompeteTimerColor.yellow) {
        _triggerHapticFeedback();
      }
    } else if (holdDuration >= redThreshold) {
      newColor = CompeteTimerColor.red;
      if (_lane2Color != CompeteTimerColor.red) {
        _triggerHapticFeedback();
      }
    }

    setState(() {
      _lane2Status = newStatus;
      _lane2Color = newColor;
      _lane2HoldDurationMs = holdDuration;
    });
  }

  void _updateLane1RunningState() {
    if (_lane1Status != CompeteTimerStatus.running) {
      return;
    }
    final elapsed = _competitionRunStopwatch?.elapsedMilliseconds ?? 0;
    setState(() {
      _lane1ElapsedMs = elapsed;
    });
  }

  void _updateLane2RunningState() {
    if (_lane2Status != CompeteTimerStatus.running) {
      return;
    }
    final elapsed = _competitionRunStopwatch?.elapsedMilliseconds ?? 0;
    setState(() {
      _lane2ElapsedMs = elapsed;
    });
  }

  // Utility methods
  Future<void> _triggerHapticFeedback() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      // Ignore vibration errors
    }
  }

  Color _getTimerColor(CompeteTimerColor color) {
    switch (color) {
      case CompeteTimerColor.red:
        return AppTheme.timerRed;
      case CompeteTimerColor.yellow:
        return AppTheme.timerYellow;
      case CompeteTimerColor.green:
        return AppTheme.timerGreen;
      default:
        return AppTheme.timerWhite;
    }
  }

  Color _getScrambleTextColor(CompeteTimerColor color) {
    switch (color) {
      case CompeteTimerColor.red:
        return Colors.white;
      case CompeteTimerColor.yellow:
      case CompeteTimerColor.green:
      case CompeteTimerColor.white:
        return Colors.black87;
    }
  }

  String _getFormattedTime(int elapsedMs, CompeteTimerStatus status) {
    if (status == CompeteTimerStatus.idle) {
      return '0.00';
    }

    final seconds = elapsedMs / 1000;

    if (seconds >= 60) {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      return '$minutes:${remainingSeconds.toStringAsFixed(2).padLeft(5, '0')}';
    } else {
      return seconds.toStringAsFixed(2);
    }
  }

  void _saveLane1Solve(int finalTime, String? scrambleNotation) {
    if (scrambleNotation == null) return;

    final solve = Solve(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: 'compete_session',
      timeMs: finalTime,
      penalty: Penalty.none,
      scramble: scrambleNotation,
      cubeType: _selectedCubeType ?? '3x3',
      lane: 1,
      createdAt: DateTime.now(),
    );

    context.read<CompeteBloc>().add(AddCompeteSolve(solve: solve, lane: 1));
    // No generamos nuevos scrambles aquí para no cambiar la ronda en curso.
    // Los scrambles para la siguiente ronda se generan cuando se inicia una nueva ronda.
  }

  void _saveLane2Solve(int finalTime, String? scrambleNotation) {
    if (scrambleNotation == null) return;

    final solve = Solve(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: 'compete_session',
      timeMs: finalTime,
      penalty: Penalty.none,
      scramble: scrambleNotation,
      cubeType: _selectedCubeType ?? '3x3',
      lane: 2,
      createdAt: DateTime.now(),
    );

    context.read<CompeteBloc>().add(AddCompeteSolve(solve: solve, lane: 2));
    // No generamos nuevos scrambles aquí para no cambiar la ronda en curso.
    // Los scrambles para la siguiente ronda se generan cuando se inicia una nueva ronda.
  }

  // La asignación de puntos ahora se realiza de forma centralizada en CompeteBloc
  // cuando ambas pistas han terminado, para evitar dobles asignaciones y manejar empates.
}
