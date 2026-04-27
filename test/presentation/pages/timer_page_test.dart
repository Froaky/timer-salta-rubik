import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:salta_rubik/presentation/bloc/session/session_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_event.dart';
import 'package:salta_rubik/presentation/bloc/session/session_state.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_bloc.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_event.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_state.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_bloc.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_event.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_state.dart';
import 'package:salta_rubik/presentation/pages/timer_page.dart';
import 'package:salta_rubik/presentation/widgets/timer/timer_display.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockSessionBloc sessionBloc;
  late MockSolveBloc solveBloc;
  late MockTimerBloc timerBloc;
  final testerView = TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .views
      .first;

  setUpAll(registerTestFallbacks);

  setUp(() {
    sessionBloc = MockSessionBloc();
    solveBloc = MockSolveBloc();
    timerBloc = MockTimerBloc();
  });

  tearDown(() {
    testerView.resetPhysicalSize();
    testerView.resetDevicePixelRatio();
  });

  Widget buildPage({
    required SessionState sessionState,
    required SolveState solveState,
    required TimerState timerState,
    bool? enableDesktopExperienceOverride,
  }) {
    whenListen(sessionBloc, const Stream<SessionState>.empty(),
        initialState: sessionState);
    whenListen(solveBloc, const Stream<SolveState>.empty(),
        initialState: solveState);
    whenListen(timerBloc, const Stream<TimerState>.empty(),
        initialState: timerState);

    when(() => sessionBloc.state).thenReturn(sessionState);
    when(() => solveBloc.state).thenReturn(solveState);
    when(() => timerBloc.state).thenReturn(timerState);
    when(() => sessionBloc.add(any())).thenReturn(null);
    when(() => solveBloc.add(any())).thenReturn(null);
    when(() => timerBloc.add(any())).thenReturn(null);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>.value(value: sessionBloc),
        BlocProvider<SolveBloc>.value(value: solveBloc),
        BlocProvider<TimerBloc>.value(value: timerBloc),
      ],
      child: MaterialApp(
        home: TimerPage(
          enableDesktopExperienceOverride: enableDesktopExperienceOverride,
        ),
      ),
    );
  }

  final session = buildSession(
    id: 'default',
    name: 'Salta Rubik 3x3',
    cubeType: '3x3',
  );
  final scramble = buildScramble();
  final solves = List.generate(
    5,
    (index) => buildSolve(
      id: 'solve-$index',
      sessionId: session.id,
      createdAt: DateTime(2024, 1, 1, 0, 0, index),
    ),
  );
  final statistics = buildStatistics(
    totalSolves: solves.length,
    recentSolves: solves,
  );

  testWidgets('dispatches initial load and scramble events on first build',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
        ),
        timerState: TimerState.initial(),
      ),
    );
    await tester.pump();

    verify(() => sessionBloc.add(any(that: isA<LoadSessions>()))).called(1);
    verify(
      () => solveBloc.add(
        any(
          that: isA<GenerateNewScramble>()
              .having((event) => event.cubeType, 'cubeType', '3x3'),
        ),
      ),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets(
      'switches to statistics panel when analytics is tapped in normal mode',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: TimerState.initial(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.analytics));
    await tester.pumpAndSettle();

    expect(find.text('Current Averages'), findsOneWidget);
    expect(find.text('Personal Best'), findsOneWidget);
  });

  testWidgets(
      'blocks history while compete mode is active and timer is running',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: TimerState.initial().copyWith(
          status: TimerStatus.running,
          competeMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();

    expect(find.textContaining('modo competir'), findsOneWidget);
    expect(find.text('Current Averages'), findsNothing);
  });

  testWidgets('renders the small scramble preview inside the timer area',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: TimerState.initial(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('timer-scramble-preview-trigger')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('timer-scramble-preview-svg')),
      findsOneWidget,
    );
  });

  testWidgets(
      'keeps floating stats clear of the timer scramble preview on narrow mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: buildStatistics(
            totalSolves: 12,
            recentSolves: solves,
            averageOf12: 11000,
          ),
        ),
        timerState: TimerState.initial(),
        enableDesktopExperienceOverride: false,
      ),
    );
    await tester.pumpAndSettle();

    final statsFinder = find.byKey(const ValueKey('floating-stats'));
    final previewFinder =
        find.byKey(const ValueKey('timer-scramble-preview-trigger'));

    expect(statsFinder, findsOneWidget);
    expect(previewFinder, findsOneWidget);
    expect(
      tester.getRect(statsFinder).overlaps(tester.getRect(previewFinder)),
      isFalse,
    );

    final statsContainer = tester.widget<Container>(statsFinder);
    final decoration = statsContainer.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(10));
  });

  testWidgets('renders a compact scramble card above the timer',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: buildScramble(
            notation: "R U R' U'",
            cubeType: '2x2',
          ),
          statistics: statistics,
        ),
        timerState: TimerState.initial(),
      ),
    );
    await tester.pumpAndSettle();

    final scrambleCardHeight =
        tester.getSize(find.byKey(const ValueKey('main-scramble-card'))).height;

    expect(scrambleCardHeight, lessThan(140));
  });

  testWidgets('tapping the timer scramble preview opens the zoomed dialog',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: TimerState.initial(),
      ),
    );
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('timer-scramble-preview-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expanded-scramble-preview')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('expanded-scramble-preview-svg')),
      findsOneWidget,
    );
  });

  testWidgets('tapping the app title returns from solves to timer home view',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: TimerState.initial(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.list));
    await tester.pumpAndSettle();
    expect(find.text('Solves'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-title-button')));
    await tester.pumpAndSettle();

    expect(find.text('Solves'), findsNothing);
    expect(find.byType(TimerDisplay), findsOneWidget);
  });

  testWidgets('tapping outside the expanded scramble preview closes it',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: TimerState.initial(),
      ),
    );
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('timer-scramble-preview-trigger')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('expanded-scramble-preview')),
        findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('expanded-scramble-preview')), findsNothing);
  });

  testWidgets('system back closes the expanded scramble preview first',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: TimerState.initial(),
      ),
    );
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('timer-scramble-preview-trigger')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('expanded-scramble-preview')),
        findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('expanded-scramble-preview')), findsNothing);
    expect(find.byType(TimerPage), findsOneWidget);
  });

  testWidgets(
      'releasing after the bloc becomes armed dispatches stop hold without waiting for rebuild',
      (tester) async {
    final idleState = TimerState.initial();
    final armedState = idleState.copyWith(
      status: TimerStatus.armed,
      color: TimerColor.green,
    );

    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: idleState,
      ),
    );
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(TimerDisplay)));

    verify(() => timerBloc.add(any(that: isA<TimerStartHold>()))).called(1);

    when(() => timerBloc.state).thenReturn(armedState);

    await gesture.up();
    await tester.pump();

    verify(() => timerBloc.add(any(that: isA<TimerStopHold>()))).called(1);
  });

  testWidgets('hold pending keeps the non-immersive layout stable',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: TimerState.initial().copyWith(
          status: TimerStatus.holdPending,
          color: TimerColor.red,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TimerDisplay), findsOneWidget);
    expect(find.byKey(const ValueKey('timer-scramble-preview-trigger')),
        findsOneWidget);
  });

  testWidgets('uses desktop timer workspace on wide desktop-class screens',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: TimerState.initial(),
        enableDesktopExperienceOverride: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('desktop-scramble-preview-trigger')),
        findsOneWidget);
    expect(find.text('Hold Space'), findsOneWidget);
  });

  testWidgets(
      'spacebar starts hold and release stops hold on desktop-class input',
      (tester) async {
    final idleState = TimerState.initial();
    final armedState = idleState.copyWith(
      status: TimerStatus.armed,
      color: TimerColor.green,
    );

    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: idleState,
        enableDesktopExperienceOverride: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();

    verify(() => timerBloc.add(any(that: isA<TimerStartHold>()))).called(1);

    when(() => timerBloc.state).thenReturn(armedState);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    verify(() => timerBloc.add(any(that: isA<TimerStopHold>()))).called(1);
  });

  testWidgets('any non-escape key stops a running timer on desktop-class input',
      (tester) async {
    final runningState = TimerState.initial().copyWith(
      status: TimerStatus.running,
      elapsedMs: 520,
      startTime: DateTime.now().subtract(const Duration(milliseconds: 520)),
    );

    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: runningState,
        enableDesktopExperienceOverride: true,
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.pump();

    verify(() => timerBloc.add(any(that: isA<TimerStop>()))).called(1);
  });

  testWidgets('escape does not stop a running timer on desktop-class input',
      (tester) async {
    final runningState = TimerState.initial().copyWith(
      status: TimerStatus.running,
      elapsedMs: 520,
      startTime: DateTime.now().subtract(const Duration(milliseconds: 520)),
    );

    await tester.pumpWidget(
      buildPage(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          solves: solves,
          currentScramble: scramble,
          statistics: statistics,
        ),
        timerState: runningState,
        enableDesktopExperienceOverride: true,
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    verifyNever(() => timerBloc.add(any(that: isA<TimerStop>())));
  });
}
