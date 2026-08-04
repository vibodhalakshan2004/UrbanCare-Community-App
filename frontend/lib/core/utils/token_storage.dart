import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'uc_auth_token';
  static const _userIdKey = 'uc_user_id';
  static const _nameKey = 'uc_name';
  static const _emailKey = 'uc_email';
  static const _roleKey = 'uc_role';
  static const _phoneKey = 'uc_phone';
  static const _themeModeKey = 'uc_theme_mode';
  static const _notificationEnabledKey = 'uc_notifications_enabled';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveSession({
    required String token,
    required String userId,
    required String name,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _roleKey, value: role);
  }

  Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<Map<String, String?>> getSession() async {
    return {
      'token': await _storage.read(key: _tokenKey),
      'userId': await _storage.read(key: _userIdKey),
      'name': await _storage.read(key: _nameKey),
      'email': await _storage.read(key: _emailKey),
      'role': await _storage.read(key: _roleKey),
      'phone': await _storage.read(key: _phoneKey),
    };
  }

  Future<void> savePhone(String phone) {
    return _storage.write(key: _phoneKey, value: phone);
  }

  Future<String?> getPhone() {
    return _storage.read(key: _phoneKey);
  }

  Future<void> saveThemeMode(String value) {
    return _storage.write(key: _themeModeKey, value: value);
  }

  Future<String?> getThemeMode() {
    return _storage.read(key: _themeModeKey);
  }

  Future<void> saveNotificationEnabled(bool enabled) {
    return _storage.write(
      key: _notificationEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool?> getNotificationEnabled() async {
    final value = await _storage.read(key: _notificationEnabledKey);
    if (value == null) {
      return null;
    }

    return value == 'true';
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _phoneKey);
  }
}
