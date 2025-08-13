import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/create_session.dart';
import '../../../domain/usecases/get_sessions.dart';
import 'session_event.dart';
import 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final CreateSession createSession;
  final GetSessions getSessions;

  SessionBloc({
    required this.createSession,
    required this.getSessions,
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
      final sessions = await getSessions(NoParams());
      
      // Set default session as current if none selected
      final currentSession = state.currentSession ?? 
          sessions.firstWhere(
            (s) => s.id == 'default',
            orElse: () => sessions.isNotEmpty ? sessions.first : throw Exception('No sessions found'),
          );
      
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
      
      // Reload sessions
      add(const LoadSessions());
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
      // Update session logic would be implemented here
      // For now, just reload
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
      // Delete session logic would be implemented here
      // For now, just reload
      add(const LoadSessions());
    } catch (e) {
      emit(state.copyWith(
        status: SessionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}