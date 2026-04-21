import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class CompleteWcaCallback {
  final AuthRepository repository;

  CompleteWcaCallback(this.repository);

  Future<AuthSession?> call(Uri callbackUri) {
    return repository.completeWcaCallback(callbackUri);
  }
}
