import 'package:equatable/equatable.dart';

import '../../../domain/entities/session.dart';

enum SessionStatus {
  initial,
  loading,
  loaded,
  error,
}

class SessionState extends Equatable {
  final SessionStatus status;
  final List<Session> sessions;
  final Session? currentSession;
  final String? errorMessage;

  const SessionState({
    required this.status,
    required this.sessions,
    this.currentSession,
    this.errorMessage,
  });

  factory SessionState.initial() {
    return const SessionState(
      status: SessionStatus.initial,
      sessions: [],
    );
  }

  SessionState copyWith({
    SessionStatus? status,
    List<Session>? sessions,
    Session? currentSession,
    String? errorMessage,
  }) {
    return SessionState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sessions,
        currentSession,
        errorMessage,
      ];
}