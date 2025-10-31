import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/create_session.dart';
import '../../../domain/usecases/get_sessions.dart';
import '../../../domain/usecases/update_session.dart';
import '../../../domain/usecases/delete_session.dart';
import '../../../domain/entities/session.dart';
import 'session_event.dart';
import 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final CreateSession createSession;
  final GetSessions getSessions;
  final UpdateSession updateSession;
  final DeleteSession deleteSession;

  SessionBloc({
    required this.createSession,
    required this.getSessions,
    required this.updateSession,
    required this.deleteSession,
  }) : super(SessionState.initial()) {
    on<LoadSessions>(_onLoadSessions);
    on<CreateSessionEvent>(_onCreateSession);
    on<SelectSession>(_onSelectSession);
    on<UpdateSessionEvent>(_onUpdateSession);
    on<DeleteSessionEvent>(_onDeleteSession);
  }

  Future<void> _onLoadSessions(LoadSessions event, Emitter<SessionState> emit) async {
    emit(state.copyWith(status: SessionStatus.loading));

    try {
      var sessions = await getSessions(NoParams());

      // Ensure a default session exists if database was created previously without seed
      if (sessions.isEmpty) {
        await createSession(Session(
          id: 'default',
          name: 'Salta Rubik 3x3',
          cubeType: '3x3',
          createdAt: DateTime(1970, 1, 1),
        ));
        sessions = await getSessions(NoParams());
      }
      
      // Ensure the currentSession exists in the freshly loaded list.
      // If the previously selected session was deleted or doesn't exist, fallback to default or first.
      Session? currentSession;
      if (state.currentSession != null) {
        final prevId = state.currentSession!.id;
        final matches = sessions.where((s) => s.id == prevId);
        currentSession = matches.isNotEmpty ? matches.first : null;
      }

      // Fallbacks when there's no valid previously selected session
      currentSession ??= sessions.where((s) => s.id == 'default').isNotEmpty
          ? sessions.firstWhere((s) => s.id == 'default')
          : (sessions.isNotEmpty ? sessions.first : null);
      
      emit(state.copyWith(
        status: SessionStatus.loaded,
        sessions: sessions,
        currentSession: currentSession,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SessionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateSession(CreateSessionEvent event, Emitter<SessionState> emit) async {
    try {
      await createSession(event.session);
      // After creating, load sessions and set the newly created one as current
      final sessions = await getSessions(NoParams());
      emit(state.copyWith(
        status: SessionStatus.loaded,
        sessions: sessions,
        currentSession: sessions.firstWhere(
          (s) => s.id == event.session.id,
          orElse: () => event.session,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SessionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSelectSession(SelectSession event, Emitter<SessionState> emit) async {
    final session = state.sessions.firstWhere(
      (s) => s.id == event.sessionId,
      orElse: () => throw Exception('Session not found'),
    );
    
    emit(state.copyWith(currentSession: session));
  }

  Future<void> _onUpdateSession(UpdateSessionEvent event, Emitter<SessionState> emit) async {
    try {
      await updateSession(event.session);
      add(const LoadSessions());
    } catch (e) {
      emit(state.copyWith(
        status: SessionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteSession(DeleteSessionEvent event, Emitter<SessionState> emit) async {
    try {
      await deleteSession(event.sessionId);
      add(const LoadSessions());
    } catch (e) {
      emit(state.copyWith(
        status: SessionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}