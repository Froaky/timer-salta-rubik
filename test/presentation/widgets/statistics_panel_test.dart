import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/presentation/bloc/session/session_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_state.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_bloc.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_event.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_state.dart';
import 'package:salta_rubik/presentation/widgets/statistics_panel.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockSessionBloc sessionBloc;
  late MockSolveBloc solveBloc;

  setUpAll(registerTestFallbacks);

  setUp(() {
    sessionBloc = MockSessionBloc();
    solveBloc = MockSolveBloc();
  });

  Widget buildPanel({
    required SessionState sessionState,
    required SolveState solveState,
  }) {
    whenListen(
      sessionBloc,
      const Stream<SessionState>.empty(),
      initialState: sessionState,
    );
    whenListen(
      solveBloc,
      const Stream<SolveState>.empty(),
      initialState: solveState,
    );

    when(() => sessionBloc.state).thenReturn(sessionState);
    when(() => solveBloc.state).thenReturn(solveState);
    when(() => solveBloc.add(any())).thenReturn(null);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>.value(value: sessionBloc),
        BlocProvider<SolveBloc>.value(value: solveBloc),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: StatisticsPanel(),
        ),
      ),
    );
  }

  final session = buildSession();

  testWidgets('hides averages whose minimum solve count has not been met', (
    tester,
  ) async {
    final solves = List.generate(
      5,
      (index) => buildSolve(
        id: 'solve-$index',
        createdAt: DateTime(2024, 1, 1, 0, 0, index),
      ),
    );

    await tester.pumpWidget(
      buildPanel(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          sessionId: session.id,
          solves: solves,
          statistics: buildStatistics(
            totalSolves: 5,
            averageOf5: 10500,
            recentSolves: solves,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current Averages'), findsOneWidget);
    expect(find.text('Average of 5 (ao5)'), findsOneWidget);
    expect(find.text('Average of 12 (ao12)'), findsNothing);
    expect(find.text('Average of 25 (ao25)'), findsNothing);
    expect(find.text('Average of 100 (ao100)'), findsNothing);
  });

  testWidgets('shows ao12 once the session reaches 12 solves', (tester) async {
    final solves = List.generate(
      12,
      (index) => buildSolve(
        id: 'solve-$index',
        createdAt: DateTime(2024, 1, 1, 0, 0, index),
      ),
    );

    await tester.pumpWidget(
      buildPanel(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          sessionId: session.id,
          solves: solves,
          statistics: buildStatistics(
            totalSolves: 12,
            averageOf5: 10500,
            averageOf12: 12000,
            recentSolves: solves,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Average of 5 (ao5)'), findsOneWidget);
    expect(find.text('Average of 12 (ao12)'), findsOneWidget);
    expect(find.text('Average of 25 (ao25)'), findsNothing);
  });

  testWidgets('reloads session data instead of rendering stale averages', (
    tester,
  ) async {
    final solves = List.generate(
      5,
      (index) => buildSolve(
        id: 'solve-$index',
        sessionId: 'old-session',
        createdAt: DateTime(2024, 1, 1, 0, 0, index),
      ),
    );

    await tester.pumpWidget(
      buildPanel(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          sessionId: 'old-session',
          solves: solves,
          statistics: buildStatistics(
            totalSolves: 12,
            averageOf5: 10500,
            averageOf12: 12000,
            recentSolves: solves,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    verify(
      () => solveBloc.add(
        const LoadSolves(sessionId: 'session-1'),
      ),
    ).called(1);
    verify(() => solveBloc.add(const LoadStatistics('session-1'))).called(1);
    expect(find.text('Average of 12 (ao12)'), findsNothing);
  });
}
