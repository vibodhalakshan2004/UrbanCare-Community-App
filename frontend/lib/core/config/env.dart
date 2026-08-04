import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class Env {
  const Env._();

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    // Android emulator cannot reach host machine through 127.0.0.1.
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }

  static const int defaultGeofenceRadiusMeters = 120;
}
