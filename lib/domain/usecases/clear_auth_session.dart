import '../repositories/auth_repository.dart';

class ClearAuthSession {
  final AuthRepository repository;

  ClearAuthSession(this.repository);

  Future<void> call() {
    return repository.clearSession();
  }
}
