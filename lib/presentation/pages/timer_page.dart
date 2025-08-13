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

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  bool _showStatistics = false;
  bool _showSolveList = false;

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
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Salta Rubik'),
        actions: [
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
          
          // Timer display
          Expanded(
            flex: 4,
            child: _buildTimerDisplay(),
          ),
          
          // Controls
          Expanded(
            flex: 1,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, TimerState state) {
        return GestureDetector(
          onTapDown: (_) {
            if (state.status == TimerStatus.idle || state.status == TimerStatus.stopped) {
              context.read<TimerBloc>().add(TimerStartHold());
            } else if (state.status == TimerStatus.running) {
              context.read<TimerBloc>().add(TimerStop());
            }
          },
          onTapUp: (_) {
            if (state.status == TimerStatus.holdPending || state.status == TimerStatus.armed) {
              context.read<TimerBloc>().add(TimerStopHold());
            }
          },
          onTapCancel: () {
            if (state.status == TimerStatus.holdPending || state.status == TimerStatus.armed) {
              context.read<TimerBloc>().add(TimerStopHold());
            }
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.getTimerColor(state.color.name),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                state.formattedTime,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: state.color == TimerColor.white ? Colors.black : Colors.white,
                  fontSize: _getTimerFontSize(state.formattedTime),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, timerState) {
        return BlocBuilder<SessionBloc, SessionState>(
          builder: (context, sessionState) {
            return BlocBuilder<SolveBloc, SolveState>(
              builder: (context, solveState) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reset button
                      ElevatedButton(
                        onPressed: timerState.status != TimerStatus.running
                            ? () {
                                context.read<TimerBloc>().add(TimerReset());
                              }
                            : null,
                        child: const Text('Reset'),
                      ),
                      
                      // New scramble button
                      ElevatedButton(
                        onPressed: timerState.status == TimerStatus.idle ||
                                timerState.status == TimerStatus.stopped
                            ? () {
                                final sessionState = context.read<SessionBloc>().state;
                                final currentSession = sessionState.currentSession;
                                if (currentSession != null) {
                                  context.read<SolveBloc>().add(GenerateNewScramble(currentSession.cubeType));
                                }
                              }
                            : null,
                    child: solveState.isGeneratingScramble
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('New Scramble'),
                  ),
                    ],
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