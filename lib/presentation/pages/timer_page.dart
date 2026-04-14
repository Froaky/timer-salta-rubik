import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_page.dart';
import 'auth_page.dart';

import '../../domain/entities/scramble.dart';
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
import '../widgets/scramble_preview.dart';
import '../widgets/statistics_panel.dart';
import '../widgets/solve_list.dart';
import '../widgets/session_selector.dart';
import '../widgets/timer/timer_display.dart';
import '../widgets/timer/timer_actions.dart';
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
  int? _latchedStopElapsedMs;

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
      context
          .read<SolveBloc>()
          .add(LoadSolves(sessionId: sessionState.currentSession!.id));
      context
          .read<SolveBloc>()
          .add(LoadStatistics(sessionState.currentSession!.id));
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
              context
                  .read<SolveBloc>()
                  .add(GenerateNewScramble(current.cubeType));
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
                  final timerState = context.read<TimerBloc>().state;
                  final isTimerActive =
                      timerState.status == TimerStatus.running ||
                          timerState.status == TimerStatus.inspection ||
                          timerState.status == TimerStatus.holdPending ||
                          timerState.status == TimerStatus.armed;

                  // Si está en modo competir y el timer está activo, no permitir acceso
                  if (timerState.competeMode && isTimerActive) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'No se puede ver estadísticas durante una resolución en modo competir'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _showStatistics = !_showStatistics;
                    if (_showStatistics) _showSolveList = false;
                  });
                },
              ),
              IconButton(
                icon: Icon(_showSolveList ? Icons.timer : Icons.list),
                onPressed: () {
                  final timerState = context.read<TimerBloc>().state;
                  final isTimerActive =
                      timerState.status == TimerStatus.running ||
                          timerState.status == TimerStatus.inspection ||
                          timerState.status == TimerStatus.holdPending ||
                          timerState.status == TimerStatus.armed;

                  // Si está en modo competir y el timer está activo, no permitir acceso
                  if (timerState.competeMode && isTimerActive) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'No se puede ver el historial durante una resolución en modo competir'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _showSolveList = !_showSolveList;
                    if (_showSolveList) _showStatistics = false;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showMenu();
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
        ));
  }

  Widget _buildTimerView() {
    return BlocListener<TimerBloc, TimerState>(
      listener: (context, timerState) {
        if (timerState.status != TimerStatus.running &&
            _latchedStopElapsedMs != null) {
          setState(() {
            _latchedStopElapsedMs = null;
          });
        }

        // When timer stops, save the solve and generate new scramble
        if (timerState.status == TimerStatus.stopped &&
            timerState.elapsedMs > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            _saveSolve(timerState.elapsedMs);
          });
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
      builder: (context, timerState) {
        return BlocBuilder<SessionBloc, SessionState>(
          builder: (context, sessionState) {
            return BlocBuilder<SolveBloc, SolveState>(
              builder: (context, solveState) {
                final displayTimerState = _latchedStopElapsedMs != null &&
                        timerState.status == TimerStatus.running
                    ? timerState.copyWith(elapsedMs: _latchedStopElapsedMs)
                    : timerState;

                return Container(
                  margin: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      // Timer Visualization
                      TimerDisplay(
                        timerState: displayTimerState,
                        previewOverlay: _buildTimerScramblePreview(
                          context,
                          solveState.currentScramble,
                        ),
                        onTapDown: () {
                          if (timerState.status == TimerStatus.idle ||
                              timerState.status == TimerStatus.stopped) {
                            context.read<TimerBloc>().add(TimerStartHold());
                          } else if (timerState.status == TimerStatus.running) {
                            final stoppedAt = DateTime.now();
                            final startTime = timerState.startTime;
                            if (startTime != null) {
                              setState(() {
                                _latchedStopElapsedMs = stoppedAt
                                    .difference(startTime)
                                    .inMilliseconds;
                              });
                            }
                            context.read<TimerBloc>().add(
                                  TimerStop(stoppedAt: stoppedAt),
                                );
                          } else if (timerState.status ==
                              TimerStatus.inspection) {
                            context.read<TimerBloc>().add(TimerStopHold());
                          }
                        },
                        onTapUp: () {
                          if (timerState.status == TimerStatus.holdPending ||
                              timerState.status == TimerStatus.armed) {
                            context.read<TimerBloc>().add(TimerStopHold());
                          }
                        },
                        onTapCancel: () {
                          if (timerState.status == TimerStatus.holdPending ||
                              timerState.status == TimerStatus.armed) {
                            context.read<TimerBloc>().add(TimerStopHold());
                          }
                        },
                      ),

                      // Floating action buttons
                      TimerActions(
                        status: timerState.status,
                        isGeneratingScramble: solveState.isGeneratingScramble,
                        onReset: () =>
                            context.read<TimerBloc>().add(TimerReset()),
                        onScramble: () {
                          final currentSession = sessionState.currentSession;
                          if (currentSession != null) {
                            context.read<SolveBloc>().add(
                                GenerateNewScramble(currentSession.cubeType));
                          }
                        },
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

  Widget? _buildTimerScramblePreview(BuildContext context, Scramble? scramble) {
    if (scramble == null || !ScramblePreview.supports(scramble.cubeType)) {
      return null;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showExpandedScramblePreview(context, scramble),
      child: Container(
        key: const ValueKey('timer-scramble-preview-trigger'),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF5C5C5C).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            ScramblePreview(
              scramble: scramble,
              width: 132,
              height: 102,
              showLabel: false,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              containerKey: const ValueKey('timer-scramble-preview'),
              svgKey: const ValueKey('timer-scramble-preview-svg'),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  Icons.zoom_in_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpandedScramblePreview(BuildContext context, Scramble scramble) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 460,
                maxHeight: 420,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5C5C5C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: ScramblePreview(
                        scramble: scramble,
                        width: 400,
                        height: 300,
                        showLabel: false,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        containerKey:
                            const ValueKey('expanded-scramble-preview'),
                        svgKey:
                            const ValueKey('expanded-scramble-preview-svg'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveSolve(int timeMs) {
    final sessionState = context.read<SessionBloc>().state;
    final solveState = context.read<SolveBloc>().state;

    final currentSession = sessionState.currentSession;
    final currentScramble = solveState.currentScramble;

    if (currentSession == null || currentScramble == null) {
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

    context.read<SolveBloc>().add(AddSolveEvent(solve));
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<TimerBloc, TimerState>(
          builder: (context, timerState) {
            final isTimerActive = timerState.status == TimerStatus.running ||
                timerState.status == TimerStatus.inspection ||
                timerState.status == TimerStatus.holdPending ||
                timerState.status == TimerStatus.armed;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Historial'),
                  enabled: !(timerState.competeMode && isTimerActive),
                  onTap: () {
                    if (timerState.competeMode && isTimerActive) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'No se puede ver el historial durante una resolución en modo competir'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    // Alternar a la vista de lista de solves
                    setState(() {
                      _showSolveList = true;
                      _showStatistics = false;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar sesión'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implementar cierre de sesión
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
