import 'package:equatable/equatable.dart';

class AuthProviderProfile extends Equatable {
  final String provider;
  final String? wcaId;
  final String? email;
  final String? name;
  final String? countryIso2;
  final String? avatarUrl;

  const AuthProviderProfile({
    required this.provider,
    this.wcaId,
    this.email,
    this.name,
    this.countryIso2,
    this.avatarUrl,
  });

  @override
  List<Object?> get props =>
      [provider, wcaId, email, name, countryIso2, avatarUrl];
}

class AuthSession extends Equatable {
  final String accessToken;
  final String userId;
  final String? email;
  final String? name;
  final List<AuthProviderProfile> providers;

  const AuthSession({
    required this.accessToken,
    required this.userId,
    this.email,
    this.name,
    required this.providers,
  });

  bool get hasWcaLinked =>
      providers.any((provider) => provider.provider == 'wca');

  @override
  List<Object?> get props => [accessToken, userId, email, name, providers];
}
