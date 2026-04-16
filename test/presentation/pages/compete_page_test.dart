import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
}
