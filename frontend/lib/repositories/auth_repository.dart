import 'dart:convert';

import 'package:urbancare_frontend/core/services/auth_service.dart';
import 'package:urbancare_frontend/core/utils/token_storage.dart';
import 'package:urbancare_frontend/models/user.dart';

class AuthRepository {
  AuthRepository({
    required AuthService authService,
    required TokenStorage tokenStorage,
  })  : _authService = authService,
        _tokenStorage = tokenStorage;

  final AuthService _authService;
  final TokenStorage _tokenStorage;

  Future<UserModel> signup({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
  }) {
    return _authService.signup(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      role: 'citizen',
    );
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final token = await _authService.login(
      email: email,
      password: password,
    );

    final payload = _decodeJwtPayload(token);
    final userId = (payload['user_id'] ?? '').toString();
    final role = (payload['role'] ?? 'citizen').toString();

    final fallbackName = email.split('@').first;
    final user = UserModel(
      userId: userId,
      name: fallbackName,
      email: email,
      role: role,
    );

    await _tokenStorage.saveSession(
      token: token,
      userId: user.userId,
      name: user.name,
      email: user.email,
      role: user.role,
    );

    return user;
  }

  Future<UserModel?> getSavedUser() async {
    final session = await _tokenStorage.getSession();
    final token = session['token'];

    if (token == null || token.isEmpty) {
      return null;
    }

    return UserModel.fromSession(session);
  }

  Future<bool> hasValidSession() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() {
    return _tokenStorage.clearSession();
  }

  Future<UserModel> getProfile() {
    return _authService.fetchProfile();
  }

  Future<UserModel> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? password,
  }) async {
    final updated = await _authService.updateProfile(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );
    // Cache locally so getSavedUser returns latest data
    await updateLocalSession(
      name: updated.name,
      email: updated.email,
      phone: updated.phoneNumber ?? '',
    );
    return updated;
  }

  Future<void> updateLocalSession({
    required String name,
    required String email,
    required String phone,
  }) async {
    await _tokenStorage.savePhone(phone);
    // Overwrite name/email using the existing session keys
    final session = await _tokenStorage.getSession();
    await _tokenStorage.saveSession(
      token: session['token'] ?? '',
      userId: session['userId'] ?? '',
      name: name,
      email: email,
      role: session['role'] ?? 'citizen',
    );
    if (phone.isNotEmpty) {
      await _tokenStorage.savePhone(phone);
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return <String, dynamic>{};
    }

    final normalized = base64Url.normalize(parts[1]);
    final payload = utf8.decode(base64Url.decode(normalized));
    final decoded = jsonDecode(payload);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }
}
