import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geofence_service/geofence_service.dart' as geofence;
import 'package:urbancare_frontend/core/config/env.dart';
import 'package:urbancare_frontend/core/services/complaint_service.dart';
import 'package:urbancare_frontend/core/services/location_service.dart';
import 'package:urbancare_frontend/models/complaint.dart';

class AppGeofenceService {
  AppGeofenceService({
    required ComplaintService complaintService,
    required LocationService locationService,
  })  : _complaintService = complaintService,
        _locationService = locationService,
        _engine = geofence.GeofenceService.instance.setup(
          interval: 5000,
          accuracy: 100,
          loiteringDelayMs: 60000,
          statusChangeDelayMs: 10000,
          useActivityRecognition: true,
          allowMockLocations: false,
          printDevLog: false,
          geofenceRadiusSortType: geofence.GeofenceRadiusSortType.DESC,
        );

  final ComplaintService _complaintService;
  final LocationService _locationService;
  final geofence.GeofenceService _engine;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final Map<String, ComplaintModel> _complaintsById = {};

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(settings);

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _engine.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _engine.addStreamErrorListener(_onGeofenceError);
    _initialized = true;
  }

  Future<List<ComplaintModel>> refreshNearbyAndStart() async {
    await initialize();

    final userLocation = await _locationService.getCurrentAppLocation();
    final nearby = await _complaintService.fetchNearbyComplaints(
      lat: userLocation.latitude,
      lng: userLocation.longitude,
    );

    await _registerGeofences(nearby);
    return nearby;
  }

  Future<void> _registerGeofences(List<ComplaintModel> complaints) async {
    _complaintsById
      ..clear()
      ..addEntries(
        complaints.map((complaint) => MapEntry(complaint.complaintId, complaint)),
      );

    final list = <geofence.Geofence>[];

    for (final complaint in complaints) {
      final location = complaint.location;
      if (location == null) {
        continue;
      }

      list.add(
        geofence.Geofence(
          id: complaint.complaintId,
          latitude: location.latitude,
          longitude: location.longitude,
          radius: [
            geofence.GeofenceRadius(
              id: 'urbancare_radius',
              length: Env.defaultGeofenceRadiusMeters.toDouble(),
            ),
          ],
        ),
      );
    }

    await _engine.stop();

    if (list.isEmpty) {
      return;
    }

    await _engine.start(list);
  }

  Future<void> _onGeofenceStatusChanged(
    geofence.Geofence geofenceData,
    geofence.GeofenceRadius geofenceRadius,
    geofence.GeofenceStatus geofenceStatus,
    geofence.Location location,
  ) async {
    if (geofenceStatus != geofence.GeofenceStatus.ENTER &&
        geofenceStatus != geofence.GeofenceStatus.DWELL) {
      return;
    }

    final complaint = _complaintsById[geofenceData.id.toString()];
    if (complaint == null) {
      return;
    }

    final meters = geofenceRadius.length.toInt();
    final body = '${complaint.displayTitle} reported ${meters}m ahead';

    await _showNotification(
      id: complaint.complaintId.hashCode,
      title: 'UrbanCare Nearby Alert',
      body: body,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'urbancare_geofence_channel',
        'UrbanCare Geofence Alerts',
        channelDescription: 'Nearby complaints geofencing notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(id, title, body, details);
  }

  void _onGeofenceError(dynamic error) {
    // ignore: avoid_print
    print('Geofence error: $error');
  }

  Future<void> dispose() async {
    _engine.removeGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _engine.removeStreamErrorListener(_onGeofenceError);
    _engine.clearAllListeners();
    await _engine.stop();
  }
}
