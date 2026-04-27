import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/domain/entities/solve.dart';
import 'package:salta_rubik/presentation/bloc/compete/compete_bloc.dart';
import 'package:salta_rubik/presentation/bloc/compete/compete_state.dart';
import 'package:salta_rubik/presentation/bloc/session/session_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_state.dart';
import 'package:salta_rubik/presentation/pages/compete_page.dart';
import 'package:salta_rubik/presentation/theme/app_theme.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockSessionBloc sessionBloc;
  late MockCompeteBloc competeBloc;

  setUpAll(registerTestFallbacks);

  setUp(() {
    sessionBloc = MockSessionBloc();
    competeBloc = MockCompeteBloc();
  });

  Widget buildPage({
    required SessionState sessionState,
    required CompeteState competeState,
  }) {
    when(() => sessionBloc.state).thenReturn(sessionState);
    when(
      () => sessionBloc.stream,
    ).thenAnswer((_) => const Stream<SessionState>.empty());
    when(() => competeBloc.state).thenReturn(competeState);
    when(
      () => competeBloc.stream,
    ).thenAnswer((_) => const Stream<CompeteState>.empty());
    when(() => sessionBloc.add(any())).thenReturn(null);
    when(() => competeBloc.add(any())).thenReturn(null);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>.value(value: sessionBloc),
        BlocProvider<CompeteBloc>.value(value: competeBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const CompetePage(),
      ),
    );
  }

  final session = buildSession(
    id: 'session-1',
    name: 'Competition Session',
    cubeType: '5x5',
  );
  const longNotation =
      "Rw U2 Fw' Dw2 Rw' Uw Fw2 Dw' Lw2 B2 Rw Uw' Fw' Rw2 Uw2 Lw' Fw Dw Rw2 Uw' B2";
  final shortScramble = buildScramble(
    cubeType: '3x3',
    notation: "R U R' U'",
  );

  SessionState buildSessionState() {
    return SessionState.initial().copyWith(
      status: SessionStatus.loaded,
      sessions: [session],
      currentSession: session,
    );
  }

  CompeteState buildReadyState({
    required String cubeType,
    required String lane1Notation,
    required String lane2Notation,
  }) {
    return CompeteState.initial().copyWith(
      status: CompeteStatus.ready,
      scrambleLane1: buildScramble(
        cubeType: cubeType,
        notation: lane1Notation,
      ),
      scrambleLane2: buildScramble(
        cubeType: cubeType,
        notation: lane2Notation,
      ),
      lane1: const LaneData(solves: []),
      lane2: const LaneData(solves: []),
      cubeType: cubeType,
    );
  }

  Future<TestGesture> holdLane(
    WidgetTester tester,
    int laneNumber, {
    Duration duration = const Duration(milliseconds: 1000),
    int pointer = 1,
  }) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('compete-lane-$laneNumber'))),
      pointer: pointer,
    );
    await tester.pump(duration);
    return gesture;
  }

  testWidgets('a single lane does not start the competition', (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: buildSessionState(),
        competeState: buildReadyState(
          cubeType: '3x3',
          lane1Notation: shortScramble.notation,
          lane2Notation: shortScramble.notation,
        ),
      ),
    );
    await tester.pumpAndSettle();
    clearInteractions(competeBloc);

    final lane1Gesture = await holdLane(tester, 1);
    await lane1Gesture.up();
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.key == const ValueKey('compete-lane-1-timer') &&
            widget.data == '0.00',
      ),
      findsOneWidget,
    );
  });

  test(
    'ignores input only when a lane is stopped and the other lane is still running',
    () {
      expect(
        shouldIgnoreCompeteLaneInteraction(
          laneStatus: CompeteTimerStatus.stopped,
          otherLaneStatus: CompeteTimerStatus.running,
        ),
        isTrue,
      );

      expect(
        shouldIgnoreCompeteLaneInteraction(
          laneStatus: CompeteTimerStatus.stopped,
          otherLaneStatus: CompeteTimerStatus.stopped,
        ),
        isFalse,
      );

      expect(
        shouldIgnoreCompeteLaneInteraction(
          laneStatus: CompeteTimerStatus.idle,
          otherLaneStatus: CompeteTimerStatus.running,
        ),
        isFalse,
      );
    },
  );

  testWidgets('renders long scrambles with adaptive text styling',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: buildSessionState(),
        competeState: buildReadyState(
          cubeType: '5x5',
          lane1Notation: longNotation,
          lane2Notation: shortScramble.notation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrambleText = tester.widget<Text>(
      find.byKey(const ValueKey('compete-lane-1-scramble')),
    );

    expect(scrambleText.data, longNotation);
    expect(scrambleText.softWrap, isTrue);
    expect(scrambleText.maxLines, isNull);
    expect(scrambleText.overflow, isNull);
    expect(scrambleText.style?.color, Colors.black87);
  });

  testWidgets('hides scrambles while a competition round is in progress',
      (tester) async {
    await tester.pumpWidget(
      buildPage(
        sessionState: buildSessionState(),
        competeState: buildReadyState(
          cubeType: '3x3',
          lane1Notation: shortScramble.notation,
          lane2Notation: shortScramble.notation,
        ).copyWith(
          status: CompeteStatus.inProgress,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('compete-lane-1-scramble')), findsNothing);
    expect(find.byKey(const ValueKey('compete-lane-2-scramble')), findsNothing);
  });

  testWidgets('renders subtle per-lane stats overlay (US-011)', (tester) async {
    final lane1Solves = [
      buildSolve(
          id: 's1-1',
          timeMs: 12000,
          createdAt: DateTime(2024, 1, 1, 12, 0)),
      buildSolve(
          id: 's1-2',
          timeMs: 11500,
          createdAt: DateTime(2024, 1, 1, 12, 1)),
      buildSolve(
          id: 's1-3',
          timeMs: 13000,
          createdAt: DateTime(2024, 1, 1, 12, 2)),
      buildSolve(
          id: 's1-4',
          timeMs: 12200,
          createdAt: DateTime(2024, 1, 1, 12, 3)),
      buildSolve(
          id: 's1-5',
          timeMs: 11800,
          createdAt: DateTime(2024, 1, 1, 12, 4)),
    ];
    final lane2Solves = [
      buildSolve(
          id: 's2-1',
          timeMs: 14000,
          createdAt: DateTime(2024, 1, 1, 12, 0)),
    ];

    final state = buildReadyState(
      cubeType: '3x3',
      lane1Notation: shortScramble.notation,
      lane2Notation: shortScramble.notation,
    ).copyWith(
      lane1: LaneData(solves: lane1Solves),
      lane2: LaneData(solves: lane2Solves),
    );

    await tester.pumpWidget(
      buildPage(
        sessionState: buildSessionState(),
        competeState: state,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('compete-lane-1-stats')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compete-lane-2-stats')),
      findsOneWidget,
    );
    // Lane 2 only has one solve, ao5/ao12 should be placeholders (no crash).
    expect(find.text('ao5'), findsWidgets);
    expect(find.text('ao12'), findsWidgets);
  });

  testWidgets(
      'comparative per-round results dialog groups by scramble (FIX-018)',
      (tester) async {
    final lane1Solves = [
      buildSolve(
        id: 'l1-r1',
        timeMs: 12340,
        scramble: 'R U R\' U\'',
        createdAt: DateTime(2024, 1, 1, 12, 0),
        lane: 1,
      ),
      buildSolve(
        id: 'l1-r2',
        timeMs: 11000,
        scramble: 'F R U R\' U\' F\'',
        createdAt: DateTime(2024, 1, 1, 12, 5),
        lane: 1,
      ),
    ];
    final lane2Solves = [
      buildSolve(
        id: 'l2-r1',
        timeMs: 13500,
        scramble: 'R U R\' U\'',
        createdAt: DateTime(2024, 1, 1, 12, 0),
        lane: 2,
      ),
    ];

    final state = buildReadyState(
      cubeType: '3x3',
      lane1Notation: shortScramble.notation,
      lane2Notation: shortScramble.notation,
    ).copyWith(
      status: CompeteStatus.finished,
      lane1: LaneData(solves: lane1Solves),
      lane2: LaneData(solves: lane2Solves),
    );

    await tester.pumpWidget(
      buildPage(
        sessionState: buildSessionState(),
        competeState: state,
      ),
    );
    await tester.pumpAndSettle();

    // Open the round-results dialog by tapping the central VS pill.
    await tester.tap(find.text('VS'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('compete-results-rounds')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compete-results-round-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compete-results-round-1')),
      findsOneWidget,
    );

    // Round 0 must show both lane times paired with the same scramble.
    final lane1Round0 = tester.widget<Text>(
      find.byKey(const ValueKey('compete-results-round-0-lane1')),
    );
    final lane2Round0 = tester.widget<Text>(
      find.byKey(const ValueKey('compete-results-round-0-lane2')),
    );
    final scrambleRound0 = tester.widget<Text>(
      find.byKey(const ValueKey('compete-results-round-0-scramble')),
    );
    expect(lane1Round0.data, '12.34');
    expect(lane2Round0.data, '13.50');
    expect(scrambleRound0.data, 'R U R\' U\'');

    // Round 1 only has lane 1 — lane 2 must show a placeholder, not crash.
    final lane2Round1 = tester.widget<Text>(
      find.byKey(const ValueKey('compete-results-round-1-lane2')),
    );
    expect(lane2Round1.data, '-');
  });
}
