import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/solve.dart';

import '../bloc/timer/timer_bloc.dart';
import '../bloc/timer/timer_event.dart';
import '../bloc/timer/timer_state.dart';
import '../bloc/solve/solve_bloc.dart';
import '../bloc/solve/solve_event.dart';
import '../bloc/solve/solve_state.dart';
import '../bloc/session/session_state.dart';
import '../bloc/session/session_event.dart';
import '../bloc/session/session_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/scramble_display.dart';
import '../widgets/statistics_panel.dart';
import '../widgets/solve_list.dart';
import '../widgets/session_selector.dart';
import 'compete_page.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  bool _showStatistics = false;
  bool _showSolveList = false;
  String? _lastSessionId;
  String? _lastCubeType;

  @override
  void initState() {
    super.initState();
    // Load initial data
    context.read<SessionBloc>().add(LoadSessions());
    context.read<SolveBloc>().add(GenerateNewScramble('3x3'));
  }

  void _onSessionChanged(SessionState sessionState) {
    if (sessionState.currentSession != null) {
      // Load solves for the current session
      context.read<SolveBloc>().add(LoadSolves(sessionId: sessionState.currentSession!.id));
      context.read<SolveBloc>().add(LoadStatistics(sessionState.currentSession!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listener: (context, sessionState) {
        _onSessionChanged(sessionState);
        // Auto-generate scramble when session changes or its cube type changes
        final current = sessionState.currentSession;
        if (current != null) {
          final changedId = current.id != _lastSessionId;
          final changedCube = current.cubeType != _lastCubeType;
          if (changedId || changedCube) {
            _lastSessionId = current.id;
            _lastCubeType = current.cubeType;
            context.read<SolveBloc>().add(GenerateNewScramble(current.cubeType));
          }
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Salta Rubik'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_esports),
            tooltip: 'Modo Competencia',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CompetePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(_showStatistics ? Icons.timer : Icons.analytics),
            onPressed: () {
              setState(() {
                _showStatistics = !_showStatistics;
                if (_showStatistics) _showSolveList = false;
              });
            },
          ),
          IconButton(
            icon: Icon(_showSolveList ? Icons.timer : Icons.list),
            onPressed: () {
              setState(() {
                _showSolveList = !_showSolveList;
                if (_showSolveList) _showStatistics = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Session selector
          const SessionSelector(),
          
          // Main content
          Expanded(
            child: _showStatistics
                ? const StatisticsPanel()
                : _showSolveList
                    ? const SolveList()
                    : _buildTimerView(),
          ),
        ],
      ),
    )
    );
  }

  Widget _buildTimerView() {
    return BlocListener<TimerBloc, TimerState>(
      listener: (context, timerState) {
        // When timer stops, save the solve and generate new scramble
        if (timerState.status == TimerStatus.stopped && timerState.elapsedMs > 0) {
          _saveSolve(timerState.elapsedMs);
          // Generate new scramble automatically
          final sessionState = context.read<SessionBloc>().state;
          final currentSession = sessionState.currentSession;
          if (currentSession != null) {
            context.read<SolveBloc>().add(GenerateNewScramble(currentSession.cubeType));
          }
        }
      },
      child: Column(
        children: [
          // Scramble display
          const Expanded(
            flex: 2,
            child: ScrambleDisplay(),
          ),
          
          // Timer display with overlaid controls
          Expanded(
            flex: 5,
            child: _buildTimerWithControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWithControls() {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, TimerState timerState) {
        return BlocBuilder<SessionBloc, SessionState>(
          builder: (context, sessionState) {
            return BlocBuilder<SolveBloc, SolveState>(
              builder: (context, solveState) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      // Timer background
                      GestureDetector(
                        onTapDown: (_) {
                          if (timerState.status == TimerStatus.idle || timerState.status == TimerStatus.stopped) {
                            context.read<TimerBloc>().add(TimerStartHold());
                          } else if (timerState.status == TimerStatus.running) {
                            context.read<TimerBloc>().add(TimerStop());
                          }
                        },
                        onTapUp: (_) {
                          if (timerState.status == TimerStatus.holdPending || timerState.status == TimerStatus.armed) {
                            context.read<TimerBloc>().add(TimerStopHold());
                          }
                        },
                        onTapCancel: () {
                          if (timerState.status == TimerStatus.holdPending || timerState.status == TimerStatus.armed) {
                            context.read<TimerBloc>().add(TimerStopHold());
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.getTimerColor(timerState.color.name),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              timerState.formattedTime,
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: timerState.color == TimerColor.white ? Colors.black : Colors.white,
                                fontSize: _getTimerFontSize(timerState.formattedTime),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Floating action buttons
                      if (timerState.status != TimerStatus.running)
                        // Reset button - top left
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: timerState.status != TimerStatus.running
                                    ? () {
                                        context.read<TimerBloc>().add(TimerReset());
                                      }
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh_rounded,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Reset',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // New scramble button - top right
                      if (timerState.status != TimerStatus.running)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: (timerState.status == TimerStatus.idle ||
                                        timerState.status == TimerStatus.stopped)
                                    ? () {
                                        final currentSession = sessionState.currentSession;
                                        if (currentSession != null) {
                                          context.read<SolveBloc>().add(GenerateNewScramble(currentSession.cubeType));
                                        }
                                      }
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      solveState.isGeneratingScramble
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.shuffle_rounded,
                                              color: Colors.white.withValues(alpha: 0.9),
                                              size: 18,
                                            ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Scramble',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]
                  ),
                );
              },
            );
          },
        );
      },
    );
  }



  double _getTimerFontSize(String timeText) {
    // Adjust font size based on text length
    if (timeText.length <= 5) return 72; // "12.34"
    if (timeText.length <= 8) return 60; // "1:23.45"
    return 48; // "12:34.56"
  }

  void _saveSolve(int timeMs) {
    print('DEBUG: _saveSolve called with timeMs: $timeMs');
    
    final sessionState = context.read<SessionBloc>().state;
    final solveState = context.read<SolveBloc>().state;

    final currentSession = sessionState.currentSession;
    final currentScramble = solveState.currentScramble;
    
    print('DEBUG: currentSession: ${currentSession?.id}');
    print('DEBUG: currentScramble: ${currentScramble?.notation}');
    
    if (currentSession == null || currentScramble == null) {
      print('DEBUG: Missing session or scramble, not saving');
      return;
    }

    final solve = Solve(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: currentSession.id,
      timeMs: timeMs,
      penalty: Penalty.none,
      scramble: currentScramble.notation,
      cubeType: currentSession.cubeType,
      lane: 0,
      createdAt: DateTime.now(),
    );

    print('DEBUG: Created solve: ${solve.id}, time: ${solve.timeMs}ms, session: ${solve.sessionId}');
    print('DEBUG: Solve scramble: ${solve.scramble}');
    print('DEBUG: Solve createdAt: ${solve.createdAt}');

    context.read<SolveBloc>().add(AddSolveEvent(solve));
    context.read<SolveBloc>().add(GenerateNewScramble(currentSession.cubeType));
  }
}