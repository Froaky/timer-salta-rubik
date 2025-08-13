import 'package:equatable/equatable.dart';

import '../../../domain/entities/session.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessions extends SessionEvent {
  const LoadSessions();
}

class CreateSessionEvent extends SessionEvent {
  final Session session;

  const CreateSessionEvent(this.session);

  @override
  List<Object> get props => [session];
}

class SelectSession extends SessionEvent {
  final String sessionId;

  const SelectSession(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}

class UpdateSessionEvent extends SessionEvent {
  final Session session;

  const UpdateSessionEvent(this.session);

  @override
  List<Object> get props => [session];
}

class DeleteSessionEvent extends SessionEvent {
  final String sessionId;

  const DeleteSessionEvent(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}