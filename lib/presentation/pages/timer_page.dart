import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_page.dart';

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
  final bool? enableDesktopExperienceOverride;

  const TimerPage({
    super.key,
    this.enableDesktopExperienceOverride,
  });

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const double _desktopLayoutBreakpoint = 1100;

  bool _showStatistics = false;
  bool _showSolveList = false;
  String? _lastSessionId;
  String? _lastCubeType;
  int? _latchedStopElapsedMs;
  int? _lastDisplayedElapsedMs;
  late final FocusNode _keyboardFocusNode;
  bool _spacebarPressed = false;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode(debugLabel: 'timer-page-keyboard-focus');
    // Load initial data
    context.read<SessionBloc>().add(LoadSessions());
    context.read<SolveBloc>().add(GenerateNewScramble('3x3'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestDesktopKeyboardFocus();
      }
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
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
            title: InkWell(
              key: const ValueKey('home-title-button'),
              borderRadius: BorderRadius.circular(8),
              onTap: _goToHomeView,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Salta Rubik'),
              ),
            ),
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
          body: BlocBuilder<TimerBloc, TimerState>(
            builder: (context, timerState) {
              final isTimerImmersive = _isTimerImmersive(timerState);
              final body = Column(
                children: [
                  if (!isTimerImmersive) const SessionSelector(),
                  Expanded(
                    child: _showStatistics
                        ? const StatisticsPanel()
                        : _showSolveList
                            ? const SolveList()
                            : _buildTimerView(isImmersive: isTimerImmersive),
                  ),
                ],
              );

              return _wrapWithDesktopKeyboardLayer(body);
            },
          ),
        ));
  }

  Widget _buildTimerView({required bool isImmersive}) {
    return BlocListener<TimerBloc, TimerState>(
      listener: (context, timerState) {
        if (timerState.status != TimerStatus.running &&
            _latchedStopElapsedMs != null) {
          setState(() {
            _latchedStopElapsedMs = null;
          });
        }

        if (timerState.status != TimerStatus.running) {
          _lastDisplayedElapsedMs = null;
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useDesktopLayout =
              !isImmersive && _useDesktopTimerLayout(constraints.maxWidth);

          if (useDesktopLayout) {
            return BlocBuilder<SessionBloc, SessionState>(
              builder: (context, sessionState) {
                return BlocBuilder<SolveBloc, SolveState>(
                  builder: (context, solveState) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1480),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    const ScrambleDisplay(),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: AnimatedScale(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        curve: Curves.easeOutCubic,
                                        scale: 1,
                                        child: _buildTimerWithControls(
                                          isImmersive: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 300,
                                child: _buildDesktopSidebar(
                                  solveState: solveState,
                                  sessionState: sessionState,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }

          return Column(
            children: [
              if (!isImmersive) const ScrambleDisplay(),
              Expanded(
                flex: 1,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  scale: isImmersive ? 1.02 : 1,
                  child: _buildTimerWithControls(isImmersive: isImmersive),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopSidebar({
    required SolveState solveState,
    required SessionState sessionState,
  }) {
    final currentSession = sessionState.currentSession;
    final currentScramble = solveState.currentScramble;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentSession != null)
          _DesktopInfoCard(
            title: 'Session',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSession.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentSession.cubeType.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                ),
              ],
            ),
          ),
        if (currentSession != null) const SizedBox(height: 16),
        _DesktopInfoCard(
          title: 'Keyboard',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShortcutRow('Start', 'Hold Space'),
              const SizedBox(height: 10),
              _buildShortcutRow('Release', 'Lift Space'),
              const SizedBox(height: 10),
              _buildShortcutRow('Stop', 'Any key except Esc'),
            ],
          ),
        ),
        if (currentScramble != null &&
            ScramblePreview.supports(currentScramble.cubeType)) ...[
          const SizedBox(height: 16),
          _DesktopInfoCard(
            title: 'Preview',
            child: GestureDetector(
              key: const ValueKey('desktop-scramble-preview-trigger'),
              onTap: () =>
                  _showExpandedScramblePreview(context, currentScramble),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.textMuted.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  children: [
                    ScramblePreview(
                      scramble: currentScramble,
                      width: 260,
                      height: 190,
                      showLabel: false,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      containerKey:
                          const ValueKey('desktop-scramble-preview-container'),
                      svgKey: const ValueKey('desktop-scramble-preview-svg'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click to expand',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimerWithControls({required bool isImmersive}) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, timerState) {
        return BlocBuilder<SessionBloc, SessionState>(
          builder: (context, sessionState) {
            return BlocBuilder<SolveBloc, SolveState>(
              builder: (context, solveState) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.all(isImmersive ? 0 : 16),
                  child: Stack(
                    children: [
                      TimerDisplay(
                        timerState: timerState,
                        onDisplayedElapsedChanged: (elapsedMs) {
                          _lastDisplayedElapsedMs = elapsedMs;
                        },
                        frozenElapsedMs: _latchedStopElapsedMs,
                        immersiveMode: isImmersive,
                        previewOverlay: isImmersive
                            ? null
                            : _buildTimerScramblePreview(
                                context,
                                solveState.currentScramble,
                              ),
                        onTapDown: _handleTimerTapDown,
                        onTapUp: _handleTimerTapUp,
                        onTapCancel: _handleTimerTapCancel,
                      ),
                      if (!isImmersive)
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

  bool _isTimerImmersive(TimerState timerState) {
    if (_showStatistics || _showSolveList) {
      return false;
    }

    switch (timerState.status) {
      case TimerStatus.inspection:
      case TimerStatus.running:
        return true;
      case TimerStatus.holdPending:
      case TimerStatus.armed:
      case TimerStatus.idle:
      case TimerStatus.stopped:
        return false;
    }
  }

  void _handleTimerTapDown() {
    _requestDesktopKeyboardFocus();
    final timerBloc = context.read<TimerBloc>();
    final timerState = timerBloc.state;

    if (timerState.status == TimerStatus.idle ||
        timerState.status == TimerStatus.stopped) {
      timerBloc.add(TimerStartHold());
      return;
    }

    if (timerState.status == TimerStatus.running) {
      _stopRunningTimer(timerBloc, timerState);
      return;
    }

    if (timerState.status == TimerStatus.inspection) {
      timerBloc.add(TimerStopHold());
    }
  }

  void _handleTimerTapUp() {
    _requestDesktopKeyboardFocus();
    final timerState = context.read<TimerBloc>().state;
    if (timerState.status == TimerStatus.holdPending ||
        timerState.status == TimerStatus.armed) {
      context.read<TimerBloc>().add(TimerStopHold());
    }
  }

  void _handleTimerTapCancel() {
    final timerState = context.read<TimerBloc>().state;
    if (timerState.status == TimerStatus.holdPending ||
        timerState.status == TimerStatus.armed) {
      context.read<TimerBloc>().add(TimerStopHold());
    }
  }

  void _stopRunningTimer(TimerBloc timerBloc, TimerState timerState) {
    final stoppedAt = DateTime.now();
    final displayedElapsedMs = _lastDisplayedElapsedMs ?? timerState.elapsedMs;
    setState(() {
      _latchedStopElapsedMs = displayedElapsedMs;
    });
    timerBloc.add(
      TimerStop(
        stoppedAt: stoppedAt,
        elapsedMsOverride: displayedElapsedMs,
      ),
    );
  }

  Widget _wrapWithDesktopKeyboardLayer(Widget child) {
    if (!_supportsDesktopClassInput) {
      return child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _requestDesktopKeyboardFocus(),
      child: Focus(
        autofocus: true,
        focusNode: _keyboardFocusNode,
        onKeyEvent: _handleDesktopKeyEvent,
        child: child,
      ),
    );
  }

  KeyEventResult _handleDesktopKeyEvent(FocusNode node, KeyEvent event) {
    if (!_supportsDesktopClassInput) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }

    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    final timerBloc = context.read<TimerBloc>();
    final timerState = timerBloc.state;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (_spacebarPressed) {
          return KeyEventResult.handled;
        }
        _spacebarPressed = true;

        if (timerState.status == TimerStatus.idle ||
            timerState.status == TimerStatus.stopped) {
          timerBloc.add(TimerStartHold());
          return KeyEventResult.handled;
        }
      }

      if (timerState.status == TimerStatus.running) {
        _stopRunningTimer(timerBloc, timerState);
        return KeyEventResult.handled;
      }
    }

    if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _spacebarPressed = false;
      if (timerState.status == TimerStatus.holdPending ||
          timerState.status == TimerStatus.armed) {
        timerBloc.add(TimerStopHold());
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _requestDesktopKeyboardFocus() {
    if (_supportsDesktopClassInput && !_keyboardFocusNode.hasFocus) {
      _keyboardFocusNode.requestFocus();
    }
  }

  bool _useDesktopTimerLayout(double maxWidth) {
    return _supportsDesktopClassInput && maxWidth >= _desktopLayoutBreakpoint;
  }

  bool get _supportsDesktopClassInput {
    final override = widget.enableDesktopExperienceOverride;
    if (override != null) {
      return override;
    }

    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  Widget _buildShortcutRow(String label, String shortcut) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.16),
            ),
          ),
          child: Text(
            shortcut,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
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
    final screenSize = MediaQuery.of(context).size;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) {
        return PopScope(
          canPop: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).pop(),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: (screenSize.width - 32).clamp(0, 520),
                      maxHeight: screenSize.height * 0.82,
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
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            key: const ValueKey(
                                'expanded-scramble-preview-close'),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.white.withValues(alpha: 0.92),
                            tooltip: 'Close scramble preview',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ),
                        Flexible(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final previewWidth = constraints.maxWidth.isFinite
                                  ? constraints.maxWidth
                                  : screenSize.width - 32;
                              final previewHeight =
                                  constraints.maxHeight.isFinite
                                      ? constraints.maxHeight
                                      : screenSize.height * 0.6;

                              return InteractiveViewer(
                                minScale: 1,
                                maxScale: 4,
                                child: SizedBox(
                                  width: previewWidth,
                                  height: previewHeight,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: ScramblePreview(
                                      scramble: scramble,
                                      width: 400,
                                      height: 300,
                                      showLabel: false,
                                      padding: EdgeInsets.zero,
                                      backgroundColor: Colors.transparent,
                                      containerKey: const ValueKey(
                                          'expanded-scramble-preview'),
                                      svgKey: const ValueKey(
                                          'expanded-scramble-preview-svg'),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _goToHomeView() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }

    setState(() {
      _showStatistics = false;
      _showSolveList = false;
    });
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
                    Navigator.of(context).pushNamed('/auth');
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

class _DesktopInfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DesktopInfoCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.textMuted.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
