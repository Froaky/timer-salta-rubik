import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class GetStoredAuthSession {
  final AuthRepository repository;

  GetStoredAuthSession(this.repository);

  Future<AuthSession?> call() {
    return repository.getStoredSession();
  }
}
