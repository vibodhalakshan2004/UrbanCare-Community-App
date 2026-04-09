import 'package:urbancare_frontend/core/api/api_client.dart';
import 'package:urbancare_frontend/models/user.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<UserModel> signup({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    String role = 'citizen',
  }) async {
    final response = await _apiClient.postJson(
      '/auth/signup',
      body: {
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
        'role': role,
      },
    );

    return UserModel.fromSignupJson(response);
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    final token = (response['access_token'] ?? '').toString();
    if (token.isEmpty) {
      throw const ApiException(
        statusCode: 500,
        message: 'Token was not returned by backend.',
      );
    }

    return token;
  }
}
