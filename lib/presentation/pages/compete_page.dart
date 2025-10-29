import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

import '../../domain/entities/solve.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/scramble.dart';

import '../bloc/compete/compete_bloc.dart';
import '../bloc/compete/compete_event.dart';
import '../bloc/compete/compete_state.dart';
import '../bloc/session/session_bloc.dart';
import '../bloc/session/session_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scramble_display.dart';

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

class CompetePage extends StatefulWidget {
  const CompetePage({super.key});

  @override
  State<CompetePage> createState() => _CompetePageState();
}

class _CompetePageState extends State<CompetePage> {
  String? _selectedCubeType;
  bool _useSameScramble = true;
  
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
  DateTime? _lane1HoldStartTime;
  DateTime? _lane2HoldStartTime;
  DateTime? _lane1RunStartTime;
  DateTime? _lane2RunStartTime;
  
  // Timer thresholds (same as main timer)
  static const int redThreshold = 0;
  static const int yellowThreshold = 200;
  static const int greenThreshold = 500;
  
  @override
  void dispose() {
    _lane1HoldTimer?.cancel();
    _lane2HoldTimer?.cancel();
    _lane1RunTimer?.cancel();
    _lane2RunTimer?.cancel();
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
                    decoration: const InputDecoration(
                      hintText: 'Selecciona el tipo de cubo',
                    ),
                    items: const [
                      DropdownMenuItem(value: '3x3', child: Text('3x3x3')),
                      DropdownMenuItem(value: '2x2', child: Text('2x2x2')),
                      DropdownMenuItem(value: '4x4', child: Text('4x4x4')),
                      DropdownMenuItem(value: '5x5', child: Text('5x5x5')),
                      DropdownMenuItem(value: 'pyraminx', child: Text('Pyraminx')),
                      DropdownMenuItem(value: 'megaminx', child: Text('Megaminx')),
                      DropdownMenuItem(value: 'skewb', child: Text('Skewb')),
                    ],
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
                      
                      // Generate initial scrambles
                      context.read<CompeteBloc>().add(
                        GenerateCompeteScrambles(
                          cubeType: _selectedCubeType ?? '3x3',
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
    
    Widget content = GestureDetector(
      onTapDown: (_) {
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
      onTapUp: (_) {
        if (laneNumber == 1) {
          _onLane1TapUp();
        } else {
          _onLane2TapUp();
        }
      },
      onTapCancel: () {
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
            // Scramble display
            if (scramble != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildScrambleDisplay(scramble),
              ),
            
            const SizedBox(height: 20),
            
            // Timer display
            Text(
              displayTime,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: color == CompeteTimerColor.white ? Colors.black : Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Player label
            Text(
              'Jugador $laneNumber',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color == CompeteTimerColor.white ? Colors.black54 : Colors.white70,
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

  Widget _buildScrambleDisplay(Scramble? scramble) {
    if (scramble == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textMuted.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        scramble.notation,
        style: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 12,
          color: AppTheme.textPrimary,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    _lane1HoldStartTime = null;
    _lane2HoldStartTime = null;
    _lane1RunStartTime = null;
    _lane2RunStartTime = null;
  }

  // Lane 1 timer methods
  void _onLane1TapDown() {
    if (_lane1Status != CompeteTimerStatus.idle && _lane1Status != CompeteTimerStatus.stopped) return;
    
    _lane1HoldStartTime = DateTime.now();
    setState(() {
      _lane1Status = CompeteTimerStatus.holdPending;
      _lane1Color = CompeteTimerColor.red;
      _lane1HoldDurationMs = 0;
    });
    
    _startLane1HoldTimer();
  }

  void _onLane1TapUp() {
    _lane1HoldTimer?.cancel();
    _lane1HoldTimer = null;
    
    if (_lane1Status == CompeteTimerStatus.armed) {
      _startLane1Timer();
    } else if (_lane1Status == CompeteTimerStatus.holdPending) {
      _resetLane1Timer();
    }
    // If stopped, do nothing - keep the time visible
  }

  void _onLane1TapCancel() {
    _lane1HoldTimer?.cancel();
    _lane1HoldTimer = null;
    _resetLane1Timer();
  }

  void _startLane1Timer() {
    _lane1RunStartTime = DateTime.now();
    setState(() {
      _lane1Status = CompeteTimerStatus.running;
      _lane1Color = CompeteTimerColor.white;
      _lane1ElapsedMs = 0;
    });
    
    _startLane1RunTimer();
    _triggerHapticFeedback();
  }

  void _stopLane1Timer() {
    if (_lane1Status != CompeteTimerStatus.running) return;
    
    _lane1RunTimer?.cancel();
    _lane1RunTimer = null;
    
    final finalTime = DateTime.now().difference(_lane1RunStartTime!).inMilliseconds;
    
    setState(() {
      _lane1Status = CompeteTimerStatus.stopped;
      _lane1ElapsedMs = finalTime;
    });
    
    _triggerHapticFeedback();
    _saveLane1Solve();
  }

  void _resetLane1Timer() {
    setState(() {
      _lane1Status = CompeteTimerStatus.idle;
      _lane1Color = CompeteTimerColor.white;
      _lane1ElapsedMs = 0;
      _lane1HoldDurationMs = 0;
    });
  }

  // Lane 2 timer methods
  void _onLane2TapDown() {
    if (_lane2Status != CompeteTimerStatus.idle && _lane2Status != CompeteTimerStatus.stopped) return;
    
    _lane2HoldStartTime = DateTime.now();
    setState(() {
      _lane2Status = CompeteTimerStatus.holdPending;
      _lane2Color = CompeteTimerColor.red;
      _lane2HoldDurationMs = 0;
    });
    
    _startLane2HoldTimer();
  }

  void _onLane2TapUp() {
    _lane2HoldTimer?.cancel();
    _lane2HoldTimer = null;
    
    if (_lane2Status == CompeteTimerStatus.armed) {
      _startLane2Timer();
    } else if (_lane2Status == CompeteTimerStatus.holdPending) {
      _resetLane2Timer();
    }
    // If stopped, do nothing - keep the time visible
  }

  void _onLane2TapCancel() {
    _lane2HoldTimer?.cancel();
    _lane2HoldTimer = null;
    _resetLane2Timer();
  }

  void _startLane2Timer() {
    _lane2RunStartTime = DateTime.now();
    setState(() {
      _lane2Status = CompeteTimerStatus.running;
      _lane2Color = CompeteTimerColor.white;
      _lane2ElapsedMs = 0;
    });
    
    _startLane2RunTimer();
    _triggerHapticFeedback();
  }

  void _stopLane2Timer() {
    if (_lane2Status != CompeteTimerStatus.running) return;
    
    _lane2RunTimer?.cancel();
    _lane2RunTimer = null;
    
    final finalTime = DateTime.now().difference(_lane2RunStartTime!).inMilliseconds;
    
    setState(() {
      _lane2Status = CompeteTimerStatus.stopped;
      _lane2ElapsedMs = finalTime;
    });
    
    _triggerHapticFeedback();
    _saveLane2Solve();
  }

  void _resetLane2Timer() {
    setState(() {
      _lane2Status = CompeteTimerStatus.idle;
      _lane2Color = CompeteTimerColor.white;
      _lane2ElapsedMs = 0;
      _lane2HoldDurationMs = 0;
    });
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
    if (_lane1HoldStartTime == null) return;
    
    final holdDuration = DateTime.now().difference(_lane1HoldStartTime!).inMilliseconds;
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
    if (_lane2HoldStartTime == null) return;
    
    final holdDuration = DateTime.now().difference(_lane2HoldStartTime!).inMilliseconds;
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
    if (_lane1RunStartTime == null) return;
    
    final elapsed = DateTime.now().difference(_lane1RunStartTime!).inMilliseconds;
    setState(() {
      _lane1ElapsedMs = elapsed;
    });
  }

  void _updateLane2RunningState() {
    if (_lane2RunStartTime == null) return;
    
    final elapsed = DateTime.now().difference(_lane2RunStartTime!).inMilliseconds;
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

  void _saveLane1Solve() {
    final competeState = context.read<CompeteBloc>().state;
    
    if (competeState.scrambleLane1 == null) return;
    
    final solve = Solve(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: 'compete_session',
      timeMs: _lane1ElapsedMs,
      penalty: Penalty.none,
      scramble: competeState.scrambleLane1!.notation,
      cubeType: _selectedCubeType ?? '3x3',
      lane: 1,
      createdAt: DateTime.now(),
    );
    
    context.read<CompeteBloc>().add(AddCompeteSolve(solve: solve, lane: 1));
    _checkAndAwardPoint(solve, 1);
    _generateNewScrambles();
  }

  void _saveLane2Solve() {
    final competeState = context.read<CompeteBloc>().state;
    
    if (competeState.scrambleLane2 == null) return;
    
    final solve = Solve(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: 'compete_session',
      timeMs: _lane2ElapsedMs,
      penalty: Penalty.none,
      scramble: competeState.scrambleLane2!.notation,
      cubeType: _selectedCubeType ?? '3x3',
      lane: 2,
      createdAt: DateTime.now(),
    );
    
    context.read<CompeteBloc>().add(AddCompeteSolve(solve: solve, lane: 2));
    _checkAndAwardPoint(solve, 2);
    _generateNewScrambles();
  }

  void _generateNewScrambles() {
    context.read<CompeteBloc>().add(
      GenerateCompeteScrambles(
        cubeType: _selectedCubeType ?? '3x3',
        useSameScramble: _useSameScramble,
      ),
    );
  }

  void _checkAndAwardPoint(Solve newSolve, int laneNumber) {
    Future.delayed(const Duration(milliseconds: 100), () {
      final updatedState = context.read<CompeteBloc>().state;
      
      if (updatedState.lane1.solves.length == updatedState.lane2.solves.length && 
          updatedState.lane1.solves.isNotEmpty && 
          updatedState.lane2.solves.isNotEmpty) {
        
        final lane1LastSolve = updatedState.lane1.solves.last;
        final lane2LastSolve = updatedState.lane2.solves.last;
        
        if (lane1LastSolve.timeMs < lane2LastSolve.timeMs) {
          context.read<CompeteBloc>().add(const AwardPoint(lane: 1));
        } else if (lane2LastSolve.timeMs < lane1LastSolve.timeMs) {
          context.read<CompeteBloc>().add(const AwardPoint(lane: 2));
        }
      }
    });
  }
}