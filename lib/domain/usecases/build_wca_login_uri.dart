import '../repositories/auth_repository.dart';

class BuildWcaLoginUri {
  final AuthRepository repository;

  BuildWcaLoginUri(this.repository);

  Uri call({required bool isWeb}) {
    return repository.buildWcaLoginUri(isWeb: isWeb);
  }
}
