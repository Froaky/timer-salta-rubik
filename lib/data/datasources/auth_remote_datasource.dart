import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../models/auth_session_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> getCurrentUser(String accessToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<AuthSessionModel> getCurrentUser(String accessToken) async {
    final response = await client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load auth session (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthSessionModel.fromAuthMeResponse(payload, accessToken);
  }
}
