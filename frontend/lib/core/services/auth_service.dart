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

  Future<UserModel> fetchProfile() async {
    final response = await _apiClient.getJson(
      '/auth/me',
      authRequired: true,
    );
    return UserModel.fromSignupJson(response);
  }

  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (password != null && password.isNotEmpty) body['password'] = password;

    final response = await _apiClient.putJson(
      '/auth/me',
      authRequired: true,
      body: body,
    );
    return UserModel.fromSignupJson(response);
  }
}
