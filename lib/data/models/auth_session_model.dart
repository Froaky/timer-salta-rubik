import 'dart:convert';

import '../../domain/entities/auth_session.dart';

class AuthProviderProfileModel extends AuthProviderProfile {
  const AuthProviderProfileModel({
    required super.provider,
    super.wcaId,
    super.email,
    super.name,
    super.countryIso2,
    super.avatarUrl,
  });

  factory AuthProviderProfileModel.fromMap(Map<String, dynamic> map) {
    return AuthProviderProfileModel(
      provider: map['provider'] as String,
      wcaId: map['wcaId'] as String?,
      email: map['email'] as String?,
      name: map['name'] as String?,
      countryIso2: map['countryIso2'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'wcaId': wcaId,
      'email': email,
      'name': name,
      'countryIso2': countryIso2,
      'avatarUrl': avatarUrl,
    };
  }
}

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required super.userId,
    super.email,
    super.name,
    required List<AuthProviderProfileModel> super.providers,
  });

  factory AuthSessionModel.fromAuthMeResponse(
    Map<String, dynamic> payload,
    String accessToken,
  ) {
    final user = payload['user'] as Map<String, dynamic>;
    final providers = (user['providers'] as List<dynamic>? ?? const [])
        .map((entry) => AuthProviderProfileModel.fromMap(
              Map<String, dynamic>.from(entry as Map),
            ))
        .toList();

    return AuthSessionModel(
      accessToken: accessToken,
      userId: user['id'] as String,
      email: user['email'] as String?,
      name: user['name'] as String?,
      providers: providers,
    );
  }

  factory AuthSessionModel.fromStorage(String rawValue) {
    final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
    return AuthSessionModel(
      accessToken: decoded['accessToken'] as String,
      userId: decoded['userId'] as String,
      email: decoded['email'] as String?,
      name: decoded['name'] as String?,
      providers: (decoded['providers'] as List<dynamic>? ?? const [])
          .map((entry) => AuthProviderProfileModel.fromMap(
                Map<String, dynamic>.from(entry as Map),
              ))
          .toList(),
    );
  }

  String toStorage() {
    return jsonEncode({
      'accessToken': accessToken,
      'userId': userId,
      'email': email,
      'name': name,
      'providers': providers
          .map(
            (provider) => AuthProviderProfileModel(
              provider: provider.provider,
              wcaId: provider.wcaId,
              email: provider.email,
              name: provider.name,
              countryIso2: provider.countryIso2,
              avatarUrl: provider.avatarUrl,
            ).toMap(),
          )
          .toList(),
    });
  }
}
