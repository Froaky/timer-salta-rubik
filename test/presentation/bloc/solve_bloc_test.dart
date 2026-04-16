import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/domain/usecases/get_solves.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_bloc.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_event.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_state.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockAddSolve addSolve;
  late MockGetSolves getSolves;
  late MockGetStatistics getStatistics;
  late MockGenerateScramble generateScramble;
  late MockUpdateSolve updateSolve;
  late MockDeleteSolve deleteSolve;
  late MockDeleteSolvesBySession deleteSolvesBySession;

  setUpAll(registerTestFallbacks);

  setUp(() {
    addSolve = MockAddSolve();
    getSolves = MockGetSolves();
    getStatistics = MockGetStatistics();
    generateScramble = MockGenerateScramble();
    updateSolve = MockUpdateSolve();
    deleteSolve = MockDeleteSolve();
    deleteSolvesBySession = MockDeleteSolvesBySession();

    when(() => addSolve(any())).thenAnswer((_) async {});
    when(() => updateSolve(any())).thenAnswer((_) async {});
    when(() => deleteSolve(any())).thenAnswer((_) async {});
    when(() => deleteSolvesBySession(any())).thenAnswer((_) async {});
  });

  SolveBloc buildBloc() {
    return SolveBloc(
      addSolve: addSolve,
      getSolves: getSolves,
      getStatistics: getStatistics,
      generateScramble: generateScramble,
      updateSolve: updateSolve,
      deleteSolve: deleteSolve,
      deleteSolvesBySession: deleteSolvesBySession,
    );
  }

  final sampleSolve = buildSolve();
  final sampleStats = buildStatistics(recentSolves: [sampleSolve]);
  final emptyStats = buildStatistics(
    personalBest: null,
    meanOf3: null,
    averageOf5: null,
    totalSolves: 0,
    recentSolves: const [],
  );
  final sampleScramble = buildScramble();

  blocTest<SolveBloc, SolveState>(
    'loads solves for a session',
    build: () {
      when(() => getSolves(any())).thenAnswer((_) async => [sampleSolve]);
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadSolves(sessionId: 'session-1')),
    expect: () => [
      SolveState.initial().copyWith(
        status: SolveStatus.loading,
        sessionId: 'session-1',
        statistics: null,
        errorMessage: null,
      ),
      SolveState.initial().copyWith(
        status: SolveStatus.loaded,
        sessionId: 'session-1',
        solves: [sampleSolve],
      ),
    ],
    verify: (_) {
      verify(
        () => getSolves(
          const GetSolvesParams(
              sessionId: 'session-1', limit: null, offset: null),
        ),
      ).called(1);
    },
  );

  blocTest<SolveBloc, SolveState>(
    'emits error when loading solves fails',
    build: () {
      when(() => getSolves(any())).thenThrow(Exception('load failed'));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadSolves(sessionId: 'session-1')),
    expect: () => [
      SolveState.initial().copyWith(
        status: SolveStatus.loading,
        sessionId: 'session-1',
        statistics: null,
        errorMessage: null,
      ),
      SolveState.initial().copyWith(
        status: SolveStatus.error,
        sessionId: 'session-1',
        errorMessage: 'Exception: load failed',
      ),
    ],
  );

  blocTest<SolveBloc, SolveState>(
    'generates a scramble and clears loading flag',
    build: () {
      when(() => generateScramble(any())).thenReturn(sampleScramble);
      return buildBloc();
    },
    act: (bloc) => bloc.add(const GenerateNewScramble('3x3')),
    expect: () => [
      SolveState.initial().copyWith(isGeneratingScramble: true),
      SolveState.initial().copyWith(
        currentScramble: sampleScramble,
        isGeneratingScramble: false,
      ),
    ],
  );

  blocTest<SolveBloc, SolveState>(
    'loads statistics for a session',
    build: () {
      when(() => getStatistics(any())).thenAnswer((_) async => sampleStats);
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadStatistics('session-1')),
    expect: () => [
      SolveState.initial().copyWith(
        sessionId: 'session-1',
        statistics: sampleStats,
      ),
    ],
  );

  test('add solve orchestrates reloads, statistics refresh, and next scramble',
      () async {
    when(() => getSolves(any())).thenAnswer((_) async => [sampleSolve]);
    when(() => getStatistics(any())).thenAnswer((_) async => sampleStats);
    when(() => generateScramble(any())).thenReturn(sampleScramble);

    final bloc = buildBloc();
    bloc.add(AddSolveEvent(sampleSolve));

    await untilCalled(() => generateScramble(any()));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(() => addSolve(sampleSolve)).called(1);
    verify(
      () => getSolves(
        const GetSolvesParams(
            sessionId: 'session-1', limit: null, offset: null),
      ),
    ).called(1);
    verify(() => getStatistics('session-1')).called(1);
    verify(() => generateScramble('3x3')).called(1);

    expect(bloc.state.status, SolveStatus.loaded);
    expect(bloc.state.sessionId, 'session-1');
    expect(bloc.state.solves, [sampleSolve]);
    expect(bloc.state.statistics, sampleStats);
    expect(bloc.state.currentScramble, sampleScramble);

    await bloc.close();
  });

  test('update solve reloads solves and statistics', () async {
    final updatedSolve = sampleSolve.copyWith(timeMs: 14000);
    when(() => getSolves(any())).thenAnswer((_) async => [updatedSolve]);
    when(() => getStatistics(any())).thenAnswer((_) async => sampleStats);

    final bloc = buildBloc();
    bloc.add(UpdateSolveEvent(updatedSolve));

    await untilCalled(() => getStatistics(any()));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(() => updateSolve(updatedSolve)).called(1);
    verify(() => getStatistics(updatedSolve.sessionId)).called(1);
    expect(bloc.state.sessionId, 'session-1');
    expect(bloc.state.solves, [updatedSolve]);
    expect(bloc.state.statistics, sampleStats);

    await bloc.close();
  });

  test('delete solve reloads using current session from state', () async {
    var getSolvesCallCount = 0;
    when(() => getSolves(any())).thenAnswer((_) async {
      getSolvesCallCount++;
      return getSolvesCallCount == 1 ? [sampleSolve] : [];
    });
    when(() => getStatistics(any())).thenAnswer((_) async => sampleStats);

    final bloc = buildBloc();
    bloc.add(const LoadSolves(sessionId: 'session-1'));
    await untilCalled(() => getSolves(any()));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(const DeleteSolveEvent('solve-1'));

    await untilCalled(() => getStatistics(any()));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(() => deleteSolve('solve-1')).called(1);
    verify(
      () => getSolves(
        const GetSolvesParams(
            sessionId: 'session-1', limit: null, offset: null),
      ),
    ).called(2);
    verify(() => getStatistics('session-1')).called(1);

    await bloc.close();
  });

  test('delete session solves clears the current session history', () async {
    var getSolvesCallCount = 0;
    when(() => getSolves(any())).thenAnswer((_) async {
      getSolvesCallCount++;
      return getSolvesCallCount == 1 ? [sampleSolve] : [];
    });
    when(() => getStatistics(any())).thenAnswer((_) async => emptyStats);

    final bloc = buildBloc();
    bloc.add(const LoadSolves(sessionId: 'session-1'));
    await untilCalled(() => getSolves(any()));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(const DeleteSessionSolvesEvent('session-1'));

    await untilCalled(() => getStatistics(any()));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    verify(() => deleteSolvesBySession('session-1')).called(1);
    verify(
      () => getSolves(
        const GetSolvesParams(
            sessionId: 'session-1', limit: null, offset: null),
      ),
    ).called(2);
    verify(() => getStatistics('session-1')).called(1);
    expect(bloc.state.solves, isEmpty);
    expect(bloc.state.statistics, emptyStats);

    await bloc.close();
  });
}
