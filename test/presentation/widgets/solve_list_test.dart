import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/domain/entities/solve.dart';
import 'package:salta_rubik/presentation/bloc/session/session_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_state.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_bloc.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_event.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_state.dart';
import 'package:salta_rubik/presentation/theme/app_theme.dart';
import 'package:salta_rubik/presentation/widgets/solve_list.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockSessionBloc sessionBloc;
  late MockSolveBloc solveBloc;

  setUpAll(registerTestFallbacks);

  setUp(() {
    sessionBloc = MockSessionBloc();
    solveBloc = MockSolveBloc();
  });

  Widget buildWidget({
    required SessionState sessionState,
    required SolveState solveState,
  }) {
    when(() => sessionBloc.state).thenReturn(sessionState);
    when(() => sessionBloc.stream)
        .thenAnswer((_) => const Stream<SessionState>.empty());
    when(() => solveBloc.state).thenReturn(solveState);
    when(() => solveBloc.stream)
        .thenAnswer((_) => const Stream<SolveState>.empty());
    when(() => sessionBloc.add(any())).thenReturn(null);
    when(() => solveBloc.add(any())).thenReturn(null);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>.value(value: sessionBloc),
        BlocProvider<SolveBloc>.value(value: solveBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SolveList(),
        ),
      ),
    );
  }

  testWidgets('deletes all solves in the active session from header action',
      (tester) async {
    final session = buildSession();
    final solve = buildSolve();

    await tester.pumpWidget(
      buildWidget(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          sessionId: session.id,
          solves: [solve],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete all solves in session'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Session Solves'), findsOneWidget);
    expect(find.text('Delete all'), findsOneWidget);

    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();

    verify(() => solveBloc.add(const DeleteSessionSolvesEvent('session-1')))
        .called(1);
  });

  group('manual solve entry', () {
    testWidgets('adds a manual solve with the current scramble and penalty',
        (tester) async {
      final session = buildSession();
      final solve = buildSolve();

      await tester.pumpWidget(
        buildWidget(
          sessionState: SessionState.initial().copyWith(
            status: SessionStatus.loaded,
            sessions: [session],
            currentSession: session,
          ),
          solveState: SolveState.initial().copyWith(
            status: SolveStatus.loaded,
            sessionId: session.id,
            solves: [solve],
            currentScramble: buildScramble(notation: "F2 R U'"),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add solve manually'));
      await tester.pumpAndSettle();

      expect(find.text('Add Solve'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '12.34');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final captured = verify(() => solveBloc.add(captureAny())).captured;
      final added = captured.whereType<AddSolveEvent>().toList();
      expect(added, hasLength(1));
      expect(added.single.solve.timeMs, 12340);
      expect(added.single.solve.sessionId, 'session-1');
      expect(added.single.solve.cubeType, session.cubeType);
      expect(added.single.solve.penalty, Penalty.none);
      expect(added.single.solve.lane, 0);
      expect(added.single.solve.scramble, "F2 R U'");
      expect(find.text('Add Solve'), findsNothing);
    });

    testWidgets('supports minutes notation and DNF penalty', (tester) async {
      final session = buildSession();

      await tester.pumpWidget(
        buildWidget(
          sessionState: SessionState.initial().copyWith(
            status: SessionStatus.loaded,
            sessions: [session],
            currentSession: session,
          ),
          solveState: SolveState.initial().copyWith(
            status: SolveStatus.loaded,
            sessionId: session.id,
            solves: [buildSolve()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add solve manually'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1:23.45');
      await tester.tap(find.text('No penalty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DNF (Did Not Finish)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final captured = verify(() => solveBloc.add(captureAny())).captured;
      final added = captured.whereType<AddSolveEvent>().toList();
      expect(added, hasLength(1));
      expect(added.single.solve.timeMs, 83450);
      expect(added.single.solve.penalty, Penalty.dnf);
    });

    testWidgets('rejects invalid input without dispatching', (tester) async {
      final session = buildSession();

      await tester.pumpWidget(
        buildWidget(
          sessionState: SessionState.initial().copyWith(
            status: SessionStatus.loaded,
            sessions: [session],
            currentSession: session,
          ),
          solveState: SolveState.initial().copyWith(
            status: SolveStatus.loaded,
            sessionId: session.id,
            solves: [buildSolve()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add solve manually'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Add Solve'), findsOneWidget);
      expect(
        find.text('Enter a valid time, e.g. 12.34 or 1:23.45'),
        findsOneWidget,
      );
      verifyNever(() => solveBloc.add(any(that: isA<AddSolveEvent>())));
    });

    testWidgets('offers manual entry from the empty state', (tester) async {
      final session = buildSession();

      await tester.pumpWidget(
        buildWidget(
          sessionState: SessionState.initial().copyWith(
            status: SessionStatus.loaded,
            sessions: [session],
            currentSession: session,
          ),
          solveState: SolveState.initial().copyWith(
            status: SolveStatus.loaded,
            sessionId: session.id,
            solves: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add time manually'));
      await tester.pumpAndSettle();

      expect(find.text('Add Solve'), findsOneWidget);
    });
  });

  group('parseManualTimeMs', () {
    test('accepts seconds, comma decimals and minutes notation', () {
      expect(parseManualTimeMs('12.34'), 12340);
      expect(parseManualTimeMs('12,34'), 12340);
      expect(parseManualTimeMs('1:23.45'), 83450);
      expect(parseManualTimeMs('1:5'), 65000);
      expect(parseManualTimeMs('0.01'), 10);
      expect(parseManualTimeMs(' 9.5 '), 9500);
      expect(parseManualTimeMs('.5'), 500);
    });

    test('rejects zero, negatives, exponents and malformed input', () {
      expect(parseManualTimeMs(''), isNull);
      expect(parseManualTimeMs('0'), isNull);
      expect(parseManualTimeMs('0:00.00'), isNull);
      expect(parseManualTimeMs('-5'), isNull);
      expect(parseManualTimeMs('1e3'), isNull);
      expect(parseManualTimeMs('Infinity'), isNull);
      expect(parseManualTimeMs('abc'), isNull);
      expect(parseManualTimeMs('1:2:3'), isNull);
      expect(parseManualTimeMs('1:75.00'), isNull);
      expect(parseManualTimeMs('-1:30.00'), isNull);
      expect(parseManualTimeMs('1:'), isNull);
      expect(parseManualTimeMs(':30'), isNull);
    });
  });

  group('sorting', () {
    testWidgets('orders solves by fastest time when selected', (tester) async {
      final session = buildSession();
      final fast = buildSolve(
        id: 'solve-fast',
        timeMs: 1000,
        createdAt: DateTime(2024, 1, 1),
      );
      final slow = buildSolve(
        id: 'solve-slow',
        timeMs: 5000,
        createdAt: DateTime(2024, 1, 2),
      );

      await tester.pumpWidget(
        buildWidget(
          sessionState: SessionState.initial().copyWith(
            status: SessionStatus.loaded,
            sessions: [session],
            currentSession: session,
          ),
          solveState: SolveState.initial().copyWith(
            status: SolveStatus.loaded,
            sessionId: session.id,
            solves: [fast, slow],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default: fecha descendente → el más nuevo (lento) arriba.
      expect(
        tester.getTopLeft(find.text('5.00')).dy,
        lessThan(tester.getTopLeft(find.text('1.00')).dy),
      );

      await tester.tap(find.byTooltip('Sort solves'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Time (fastest first)'));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('1.00')).dy,
        lessThan(tester.getTopLeft(find.text('5.00')).dy),
      );
    });

    testWidgets('puts DNF solves last when sorting by fastest time',
        (tester) async {
      final session = buildSession();
      final dnf = buildSolve(
        id: 'solve-dnf',
        timeMs: 500,
        penalty: Penalty.dnf,
        createdAt: DateTime(2024, 1, 3),
      );
      final normal = buildSolve(
        id: 'solve-normal',
        timeMs: 5000,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        buildWidget(
          sessionState: SessionState.initial().copyWith(
            status: SessionStatus.loaded,
            sessions: [session],
            currentSession: session,
          ),
          solveState: SolveState.initial().copyWith(
            status: SolveStatus.loaded,
            sessionId: session.id,
            solves: [dnf, normal],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sort solves'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Time (fastest first)'));
      await tester.pumpAndSettle();

      // El DNF (aunque su timeMs crudo sea menor) va al final.
      expect(
        tester.getTopLeft(find.text('5.00')).dy,
        lessThan(tester.getTopLeft(find.text('DNF').first).dy),
      );
    });
  });
}
