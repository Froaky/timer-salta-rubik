import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/presentation/bloc/session/session_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_event.dart';
import 'package:salta_rubik/presentation/bloc/session/session_state.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_bloc.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_event.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_state.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_bloc.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_state.dart';
import 'package:salta_rubik/presentation/pages/timer_page.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockSessionBloc sessionBloc;
  late MockSolveBloc solveBloc;
  late MockTimerBloc timerBloc;

  setUpAll(registerTestFallbacks);

  setUp(() {
    sessionBloc = MockSessionBloc();
    solveBloc = MockSolveBloc();
    timerBloc = MockTimerBloc();
  });

  Widget buildPage({
    required SessionState sessionState,
    required SolveState solveState,
    required TimerState timerState,
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
      child: const MaterialApp(
        home: TimerPage(),
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

    await tester.tap(find.byKey(const ValueKey('timer-scramble-preview-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expanded-scramble-preview')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('expanded-scramble-preview-svg')),
      findsOneWidget,
    );
  });
}
