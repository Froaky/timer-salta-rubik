import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/core/usecases/usecase.dart';
import 'package:salta_rubik/domain/entities/session.dart';
import 'package:salta_rubik/presentation/bloc/session/session_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_event.dart';
import 'package:salta_rubik/presentation/bloc/session/session_state.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockCreateSession createSession;
  late MockGetSessions getSessions;
  late MockUpdateSession updateSession;
  late MockDeleteSession deleteSession;

  setUpAll(registerTestFallbacks);

  setUp(() {
    createSession = MockCreateSession();
    getSessions = MockGetSessions();
    updateSession = MockUpdateSession();
    deleteSession = MockDeleteSession();

    when(() => createSession(any())).thenAnswer((_) async {});
    when(() => updateSession(any())).thenAnswer((_) async {});
    when(() => deleteSession(any())).thenAnswer((_) async {});
  });

  SessionBloc buildBloc() {
    return SessionBloc(
      createSession: createSession,
      getSessions: getSessions,
      updateSession: updateSession,
      deleteSession: deleteSession,
    );
  }

  final defaultSession = buildSession(
    id: 'default',
    name: 'Salta Rubik 3x3',
    cubeType: '3x3',
    createdAt: DateTime(1970, 1, 1),
  );
  final fourByFourSession = buildSession(
    id: 'session-4x4',
    name: 'Big Cubes',
    cubeType: '4x4',
    createdAt: DateTime(2024, 2, 1),
  );

  blocTest<SessionBloc, SessionState>(
    'loads sessions and selects the default session when available',
    build: () {
      when(() => getSessions(any())).thenAnswer(
        (_) async => [fourByFourSession, defaultSession],
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadSessions()),
    expect: () => [
      SessionState.initial().copyWith(status: SessionStatus.loading),
      SessionState.initial().copyWith(
        status: SessionStatus.loaded,
        sessions: [fourByFourSession, defaultSession],
        currentSession: defaultSession,
      ),
    ],
    verify: (_) {
      verify(() => getSessions(any<NoParams>())).called(1);
    },
  );

  blocTest<SessionBloc, SessionState>(
    'creates a default session if repository is empty',
    build: () {
      var callCount = 0;
      when(() => getSessions(any())).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? <Session>[] : [defaultSession];
      });
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadSessions()),
    expect: () => [
      SessionState.initial().copyWith(status: SessionStatus.loading),
      SessionState.initial().copyWith(
        status: SessionStatus.loaded,
        sessions: [defaultSession],
        currentSession: defaultSession,
      ),
    ],
    verify: (_) {
      verify(
        () => createSession(
          any(
            that: isA<Session>()
                .having((session) => session.id, 'id', 'default')
                .having((session) => session.cubeType, 'cubeType', '3x3'),
          ),
        ),
      ).called(1);
      verify(() => getSessions(any<NoParams>())).called(2);
    },
  );

  blocTest<SessionBloc, SessionState>(
    'preserves the currently selected session if it still exists after reload',
    build: () {
      when(() => getSessions(any())).thenAnswer(
        (_) async => [defaultSession, fourByFourSession],
      );
      return buildBloc();
    },
    seed: () => SessionState.initial().copyWith(
      status: SessionStatus.loaded,
      sessions: [defaultSession, fourByFourSession],
      currentSession: fourByFourSession,
    ),
    act: (bloc) => bloc.add(const LoadSessions()),
    expect: () => [
      SessionState.initial().copyWith(
        status: SessionStatus.loading,
        sessions: [defaultSession, fourByFourSession],
        currentSession: fourByFourSession,
      ),
      SessionState.initial().copyWith(
        status: SessionStatus.loaded,
        sessions: [defaultSession, fourByFourSession],
        currentSession: fourByFourSession,
      ),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'selects a session by id',
    build: buildBloc,
    seed: () => SessionState.initial().copyWith(
      status: SessionStatus.loaded,
      sessions: [defaultSession, fourByFourSession],
      currentSession: defaultSession,
    ),
    act: (bloc) => bloc.add(const SelectSession('session-4x4')),
    expect: () => [
      SessionState.initial().copyWith(
        status: SessionStatus.loaded,
        sessions: [defaultSession, fourByFourSession],
        currentSession: fourByFourSession,
      ),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'creates a new session and makes it current',
    build: () {
      when(() => getSessions(any())).thenAnswer(
        (_) async => [defaultSession, fourByFourSession],
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(CreateSessionEvent(fourByFourSession)),
    expect: () => [
      SessionState.initial().copyWith(
        status: SessionStatus.loaded,
        sessions: [defaultSession, fourByFourSession],
        currentSession: fourByFourSession,
      ),
    ],
    verify: (_) {
      verify(() => createSession(fourByFourSession)).called(1);
    },
  );

  blocTest<SessionBloc, SessionState>(
    'reloads sessions after an update',
    build: () {
      when(() => getSessions(any())).thenAnswer(
        (_) async => [defaultSession, fourByFourSession],
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(UpdateSessionEvent(fourByFourSession)),
    expect: () => [
      SessionState.initial().copyWith(status: SessionStatus.loading),
      SessionState.initial().copyWith(
        status: SessionStatus.loaded,
        sessions: [defaultSession, fourByFourSession],
        currentSession: defaultSession,
      ),
    ],
    verify: (_) {
      verify(() => updateSession(fourByFourSession)).called(1);
      verify(() => getSessions(any<NoParams>())).called(1);
    },
  );

  blocTest<SessionBloc, SessionState>(
    'emits error when loading sessions fails',
    build: () {
      when(() => getSessions(any())).thenThrow(Exception('boom'));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LoadSessions()),
    expect: () => [
      SessionState.initial().copyWith(status: SessionStatus.loading),
      SessionState.initial().copyWith(
        status: SessionStatus.error,
        errorMessage: 'Exception: boom',
      ),
    ],
  );
}
