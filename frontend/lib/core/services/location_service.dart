import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:urbancare_frontend/models/location.dart';

class LocationService {
  Future<AppLocation> getCurrentAppLocation({String? fallbackAddress}) async {
    await _ensurePermission();

    final position = await _resolveBestPosition();

    return AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: fallbackAddress ?? 'Current location',
    );
  }

  Future<AppLocation> getFreshCurrentAppLocation({String? fallbackAddress}) async {
    await _ensurePermission();

    final requestedAt = DateTime.now().toUtc();
    final minimumTimestamp = requestedAt.subtract(const Duration(seconds: 2));

    Position? current;
    Position? streamed;

    try {
      current = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings(
          timeLimit: const Duration(seconds: 25),
        ),
      );

      if (_isFreshReliablePosition(
        current,
        minimumTimestamp: minimumTimestamp,
        maxAge: const Duration(seconds: 20),
        maxAccuracyMeters: 180,
      )) {
        return AppLocation(
          latitude: current.latitude,
          longitude: current.longitude,
          address: fallbackAddress ?? 'Current location',
        );
      }
    } catch (_) {
      // Stream fallback below.
    }

    try {
      streamed = await Geolocator.getPositionStream(
        locationSettings: _locationSettings(
          timeLimit: const Duration(seconds: 20),
        ),
      ).firstWhere(_isUsablePosition).timeout(const Duration(seconds: 20));

      if (_isFreshReliablePosition(
        streamed,
        minimumTimestamp: minimumTimestamp,
        maxAge: const Duration(seconds: 30),
        maxAccuracyMeters: 220,
      )) {
        return AppLocation(
          latitude: streamed.latitude,
          longitude: streamed.longitude,
          address: fallbackAddress ?? 'Current location',
        );
      }
    } catch (_) {
      // Fall back to normal location resolution below.
    }

    // Final fallback keeps behavior resilient if emulator does not provide fresh timestamps.
    final fallback = await _resolveBestPosition();
    return AppLocation(
      latitude: fallback.latitude,
      longitude: fallback.longitude,
      address: fallbackAddress ?? 'Current location',
    );
  }

  Future<Position> _resolveBestPosition() async {
    final settings = _locationSettings(
      timeLimit: const Duration(seconds: 20),
    );

    Position? current;
    Position? streamed;
    Position? lastKnown;

    try {
      current = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      if (_isReliablePosition(
        current,
        maxAge: const Duration(seconds: 30),
        maxAccuracyMeters: 120,
      )) {
        return current;
      }
    } catch (_) {
      // Fallbacks below will attempt to get a usable position.
    }

    try {
      streamed = await Geolocator.getPositionStream(
        locationSettings: _locationSettings(
          timeLimit: const Duration(seconds: 15),
        ),
      ).first.timeout(const Duration(seconds: 15));
      if (_isReliablePosition(
        streamed,
        maxAge: const Duration(seconds: 30),
        maxAccuracyMeters: 120,
      )) {
        return streamed;
      }
    } catch (_) {
      // Ignore and throw a clear error below.
    }

    lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null &&
        _isReliablePosition(
          lastKnown,
          maxAge: const Duration(minutes: 2),
          maxAccuracyMeters: 250,
        )) {
      return lastKnown;
    }

    // If all strict checks fail, still return the best usable candidate to avoid hard-failing.
    if (current != null && _isUsablePosition(current)) {
      return current;
    }
    if (streamed != null && _isUsablePosition(streamed)) {
      return streamed;
    }
    if (lastKnown != null && _isUsablePosition(lastKnown)) {
      return lastKnown;
    }

    throw Exception('Unable to determine current location. Please set emulator location and try again.');
  }

  LocationSettings _locationSettings({Duration? timeLimit}) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        timeLimit: timeLimit,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      timeLimit: timeLimit,
    );
  }

  bool _isUsablePosition(Position position) {
    return position.latitude.abs() <= 90 &&
        position.longitude.abs() <= 180 &&
        !(position.latitude == 0 && position.longitude == 0);
  }

  bool _isReliablePosition(
    Position position, {
    required Duration maxAge,
    required double maxAccuracyMeters,
  }) {
    if (!_isUsablePosition(position)) {
      return false;
    }

    final timestamp = position.timestamp;
    final age = DateTime.now().toUtc().difference(timestamp.toUtc());
    if (age > maxAge) {
      return false;
    }

    // Some emulator/device providers may return 0 accuracy; treat it as acceptable.
    if (position.accuracy > 0 && position.accuracy > maxAccuracyMeters) {
      return false;
    }

    return true;
  }

  bool _isFreshReliablePosition(
    Position position, {
    required DateTime minimumTimestamp,
    required Duration maxAge,
    required double maxAccuracyMeters,
  }) {
    if (!_isReliablePosition(
      position,
      maxAge: maxAge,
      maxAccuracyMeters: maxAccuracyMeters,
    )) {
      return false;
    }

    final timestamp = position.timestamp.toUtc();
    return timestamp.isAfter(minimumTimestamp);
  }

  Future<void> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied.');
    }
  }
}
