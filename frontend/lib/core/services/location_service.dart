import 'package:geolocator/geolocator.dart';
import 'package:urbancare_frontend/models/location.dart';

class LocationService {
  Future<AppLocation> getCurrentAppLocation({String? fallbackAddress}) async {
    await _ensurePermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: fallbackAddress ?? 'Current location',
    );
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
