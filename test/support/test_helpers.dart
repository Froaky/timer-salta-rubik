import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/core/usecases/usecase.dart';
import 'package:salta_rubik/domain/entities/scramble.dart';
import 'package:salta_rubik/domain/entities/session.dart';
import 'package:salta_rubik/domain/entities/solve.dart';
import 'package:salta_rubik/domain/entities/statistics.dart';
import 'package:salta_rubik/domain/usecases/add_solve.dart';
import 'package:salta_rubik/domain/usecases/create_session.dart';
import 'package:salta_rubik/domain/usecases/delete_session.dart';
import 'package:salta_rubik/domain/usecases/delete_solve.dart';
import 'package:salta_rubik/domain/usecases/generate_scramble.dart';
import 'package:salta_rubik/domain/usecases/get_sessions.dart';
import 'package:salta_rubik/domain/usecases/get_solves.dart';
import 'package:salta_rubik/domain/usecases/get_statistics.dart';
import 'package:salta_rubik/domain/usecases/update_session.dart';
import 'package:salta_rubik/domain/usecases/update_solve.dart';
import 'package:salta_rubik/presentation/bloc/compete/compete_bloc.dart';
import 'package:salta_rubik/presentation/bloc/compete/compete_event.dart';
import 'package:salta_rubik/presentation/bloc/compete/compete_state.dart';
import 'package:salta_rubik/presentation/bloc/session/session_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_event.dart';
import 'package:salta_rubik/presentation/bloc/session/session_state.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_bloc.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_event.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_state.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_bloc.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_event.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_state.dart';

class MockAddSolve extends Mock implements AddSolve {}

class MockGetSolves extends Mock implements GetSolves {}

class MockGetStatistics extends Mock implements GetStatistics {}

class MockGenerateScramble extends Mock implements GenerateScramble {}

class MockUpdateSolve extends Mock implements UpdateSolve {}

class MockDeleteSolve extends Mock implements DeleteSolve {}

class MockCreateSession extends Mock implements CreateSession {}

class MockGetSessions extends Mock implements GetSessions {}

class MockUpdateSession extends Mock implements UpdateSession {}

class MockDeleteSession extends Mock implements DeleteSession {}

class MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

class MockSolveBloc extends MockBloc<SolveEvent, SolveState>
    implements SolveBloc {}

class MockTimerBloc extends MockBloc<TimerEvent, TimerState>
    implements TimerBloc {}

class MockCompeteBloc extends MockBloc<CompeteEvent, CompeteState>
    implements CompeteBloc {}

class FakeSessionEvent extends Fake implements SessionEvent {}

class FakeSolveEvent extends Fake implements SolveEvent {}

class FakeTimerEvent extends Fake implements TimerEvent {}

class FakeCompeteEvent extends Fake implements CompeteEvent {}

class FakeSession extends Fake implements Session {}

class FakeSolve extends Fake implements Solve {}

class FakeScramble extends Fake implements Scramble {}

class FakeStatistics extends Fake implements Statistics {}

class FakeGetSolvesParams extends Fake implements GetSolvesParams {}

class FakeNoParams extends Fake implements NoParams {}

bool _fallbacksRegistered = false;

void registerTestFallbacks() {
  if (_fallbacksRegistered) {
    return;
  }

  registerFallbackValue(FakeSessionEvent());
  registerFallbackValue(FakeSolveEvent());
  registerFallbackValue(FakeTimerEvent());
  registerFallbackValue(FakeCompeteEvent());
  registerFallbackValue(FakeSession());
  registerFallbackValue(FakeSolve());
  registerFallbackValue(FakeScramble());
  registerFallbackValue(FakeStatistics());
  registerFallbackValue(FakeGetSolvesParams());
  registerFallbackValue(FakeNoParams());

  _fallbacksRegistered = true;
}

Session buildSession({
  String id = 'session-1',
  String name = 'Session 1',
  String cubeType = '3x3',
  DateTime? createdAt,
}) {
  return Session(
    id: id,
    name: name,
    cubeType: cubeType,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}

Solve buildSolve({
  String id = 'solve-1',
  String sessionId = 'session-1',
  int timeMs = 12345,
  Penalty penalty = Penalty.none,
  String scramble = "R U R' U'",
  String cubeType = '3x3',
  int lane = 0,
  DateTime? createdAt,
  bool isSynced = false,
}) {
  return Solve(
    id: id,
    sessionId: sessionId,
    timeMs: timeMs,
    penalty: penalty,
    scramble: scramble,
    cubeType: cubeType,
    lane: lane,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    isSynced: isSynced,
  );
}

Scramble buildScramble({
  String notation = "R U R' U'",
  String cubeType = '3x3',
  List<String>? moves,
  DateTime? generatedAt,
}) {
  final resolvedMoves = moves ?? notation.split(' ');
  return Scramble(
    notation: notation,
    cubeType: cubeType,
    moves: resolvedMoves,
    generatedAt: generatedAt ?? DateTime(2024, 1, 1),
  );
}

Statistics buildStatistics({
  int? personalBest = 9000,
  int? meanOf3 = 10000,
  int? averageOf5 = 10500,
  int? averageOf12,
  int? averageOf25,
  int? averageOf100,
  int? averageOf200,
  int? averageOf500,
  int? averageOf1000,
  int totalSolves = 5,
  List<Solve>? recentSolves,
}) {
  return Statistics(
    personalBest: personalBest,
    meanOf3: meanOf3,
    averageOf5: averageOf5,
    averageOf12: averageOf12,
    averageOf25: averageOf25,
    averageOf100: averageOf100,
    averageOf200: averageOf200,
    averageOf500: averageOf500,
    averageOf1000: averageOf1000,
    totalSolves: totalSolves,
    recentSolves: recentSolves ?? const [],
  );
}
