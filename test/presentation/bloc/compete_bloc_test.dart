import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/presentation/bloc/compete/compete_bloc.dart';
import 'package:salta_rubik/presentation/bloc/compete/compete_event.dart';
import 'package:salta_rubik/presentation/bloc/compete/compete_state.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockGenerateScramble generateScramble;

  setUpAll(registerTestFallbacks);

  setUp(() {
    generateScramble = MockGenerateScramble();
  });

  CompeteBloc buildBloc() {
    return CompeteBloc(generateScramble: generateScramble);
  }

  final scrambleA = buildScramble(notation: "R U R' U'");
  final scrambleB = buildScramble(
    notation: "F R U R' U' F'",
    generatedAt: DateTime(2024, 1, 2),
  );
  final lane1Solve = buildSolve(id: 'lane1', lane: 1, timeMs: 10000);
  blocTest<CompeteBloc, CompeteState>(
    'starts round with same scramble on both lanes when configured',
    build: () {
      when(() => generateScramble(any())).thenReturn(scrambleA);
      return buildBloc();
    },
    act: (bloc) => bloc.add(const StartCompeteRound(cubeType: '3x3')),
    expect: () => [
      CompeteState.initial().copyWith(
        status: CompeteStatus.ready,
        scrambleLane1: scrambleA,
        scrambleLane2: scrambleA,
        lane1: const LaneData(solves: []),
        lane2: const LaneData(solves: []),
        useSameScramble: true,
        cubeType: '3x3',
      ),
    ],
    verify: (_) {
      verify(() => generateScramble('3x3')).called(1);
    },
  );

  blocTest<CompeteBloc, CompeteState>(
    'starts round with different scrambles when requested',
    build: () {
      var callCount = 0;
      when(() => generateScramble(any())).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? scrambleA : scrambleB;
      });
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const StartCompeteRound(cubeType: '3x3', useSameScramble: false),
    ),
    expect: () => [
      CompeteState.initial().copyWith(
        status: CompeteStatus.ready,
        scrambleLane1: scrambleA,
        scrambleLane2: scrambleB,
        lane1: const LaneData(solves: []),
        lane2: const LaneData(solves: []),
        useSameScramble: false,
        cubeType: '3x3',
      ),
    ],
    verify: (_) {
      verify(() => generateScramble('3x3')).called(2);
    },
  );

  blocTest<CompeteBloc, CompeteState>(
    'adds solves to the correct lane',
    build: buildBloc,
    seed: () => CompeteState.initial().copyWith(status: CompeteStatus.ready),
    act: (bloc) => bloc.add(AddCompeteSolve(solve: lane1Solve, lane: 1)),
    expect: () => [
      CompeteState.initial().copyWith(
        status: CompeteStatus.ready,
        lane1: LaneData(
          solves: [lane1Solve],
          currentTimeMs: lane1Solve.effectiveTimeMs,
          isFinished: true,
        ),
      ),
    ],
  );

  blocTest<CompeteBloc, CompeteState>(
    'updates lane timer without finishing the solve',
    build: buildBloc,
    act: (bloc) => bloc.add(const UpdateLaneTimer(lane: 2, elapsedMs: 4321)),
    expect: () => [
      CompeteState.initial().copyWith(
        lane2: const LaneData(solves: [], currentTimeMs: 4321),
      ),
    ],
  );

  test('scores a round when both lanes stop and refreshes scrambles', () async {
    var callCount = 0;
    when(() => generateScramble(any())).thenAnswer((_) {
      callCount++;
      switch (callCount) {
        case 1:
          return scrambleA;
        case 2:
          return scrambleB;
        default:
          return scrambleA;
      }
    });

    final bloc = buildBloc();
    bloc.add(const StartCompeteRound(cubeType: '3x3'));
    await Future<void>.delayed(Duration.zero);

    bloc.add(const StartLane(lane: 1));
    bloc.add(const StartLane(lane: 2));
    await Future<void>.delayed(Duration.zero);

    bloc.add(const StopLane(lane: 1, finishedAtMs: 9500));
    bloc.add(const StopLane(lane: 2, finishedAtMs: 10300));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(bloc.state.status, CompeteStatus.finished);
    expect(bloc.state.winner, 'lane1');
    expect(bloc.state.lane1Score, 1);
    expect(bloc.state.lane2Score, 0);
    expect(bloc.state.roundScored, isTrue);
    expect(bloc.state.scrambleLane1, scrambleB);
    expect(bloc.state.scrambleLane2, scrambleB);

    await bloc.close();
  });

  test('marks ties without awarding points', () async {
    when(() => generateScramble(any())).thenReturn(scrambleA);

    final bloc = buildBloc();
    bloc.add(const StartCompeteRound(cubeType: '3x3'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const StartLane(lane: 1));
    bloc.add(const StartLane(lane: 2));
    await Future<void>.delayed(Duration.zero);

    bloc.add(const StopLane(lane: 1, finishedAtMs: 10000));
    bloc.add(const StopLane(lane: 2, finishedAtMs: 10000));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(bloc.state.winner, 'tie');
    expect(bloc.state.lane1Score, 0);
    expect(bloc.state.lane2Score, 0);

    await bloc.close();
  });

  blocTest<CompeteBloc, CompeteState>(
    'generates new competition scrambles on demand',
    build: () {
      var callCount = 0;
      when(() => generateScramble(any())).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? scrambleA : scrambleB;
      });
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const GenerateCompeteScrambles(cubeType: '3x3', useSameScramble: false),
    ),
    expect: () => [
      CompeteState.initial().copyWith(
        scrambleLane1: scrambleA,
        scrambleLane2: scrambleB,
        useSameScramble: false,
      ),
    ],
  );

  blocTest<CompeteBloc, CompeteState>(
    'awards points manually',
    build: buildBloc,
    act: (bloc) => bloc.add(const AwardPoint(lane: 2)),
    expect: () => [
      CompeteState.initial().copyWith(lane2Score: 1),
    ],
  );

  blocTest<CompeteBloc, CompeteState>(
    'resets compete state',
    build: buildBloc,
    seed: () => CompeteState.initial().copyWith(
      status: CompeteStatus.finished,
      lane1Score: 3,
      lane2Score: 2,
      winner: 'lane1',
    ),
    act: (bloc) => bloc.add(const ResetCompete()),
    expect: () => [
      CompeteState.initial(),
    ],
  );
}
