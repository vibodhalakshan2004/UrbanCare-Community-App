import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:urbancare_frontend/core/services/geofence_service.dart';
import 'package:urbancare_frontend/models/complaint.dart';
import 'package:urbancare_frontend/models/location.dart';
import 'package:urbancare_frontend/models/user.dart';
import 'package:urbancare_frontend/repositories/auth_repository.dart';
import 'package:urbancare_frontend/repositories/complaint_repository.dart';
import 'package:urbancare_frontend/screens/complaint/complaint_detail_screen.dart';
import 'package:urbancare_frontend/screens/complaint/create_complaint_screen.dart';
import 'package:urbancare_frontend/screens/map/map_screen.dart';
import 'package:urbancare_frontend/widgets/complaint_card.dart';
import 'package:urbancare_frontend/widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authRepository,
    required this.complaintRepository,
    required this.geofenceService,
    required this.onSignOut,
  });

  final AuthRepository authRepository;
  final ComplaintRepository complaintRepository;
  final AppGeofenceService geofenceService;
  final VoidCallback onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  UserModel? _user;
  List<ComplaintModel> _nearby = const [];
  AppLocation? _mapCenter;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final user = await widget.authRepository.getSavedUser();

      List<ComplaintModel> nearby;
      try {
        nearby = await widget.geofenceService.refreshNearbyAndStart();
      } catch (_) {
        try {
          nearby = await widget.complaintRepository.getNearbyComplaints();
        } catch (_) {
          nearby = await widget.complaintRepository.getAllComplaints();
        }
      }

      if (nearby.isEmpty) {
        nearby = await widget.complaintRepository.getAllComplaints();
      }

      AppLocation? mapCenter;
      try {
        mapCenter = await widget.complaintRepository.getCurrentLocation();
      } catch (_) {
        for (final complaint in nearby) {
          if (complaint.location != null) {
            mapCenter = complaint.location;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _nearby = nearby;
        _mapCenter = mapCenter;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _goToCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateComplaintScreen(
          complaintRepository: widget.complaintRepository,
        ),
      ),
    );

    if (created == true) {
      await _loadDashboard(showLoader: false);
    }
  }

  Future<void> _goToMap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapScreen(
          complaintRepository: widget.complaintRepository,
        ),
      ),
    );
    await _loadDashboard(showLoader: false);
  }

  Future<void> _openComplaint(ComplaintModel complaint) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComplaintDetailScreen(
          complaint: complaint,
          complaintRepository: widget.complaintRepository,
        ),
      ),
    );
    await _loadDashboard(showLoader: false);
  }

  Future<void> _signOut() async {
    await widget.authRepository.logout();
    widget.onSignOut();
  }

  String _welcomeName() {
    final savedName = _user?.name.trim() ?? '';
    if (savedName.isNotEmpty) {
      final firstName = savedName.split(RegExp(r'\s+')).first.trim();
      if (firstName.isNotEmpty) {
        return firstName;
      }
    }

    final emailName = (_user?.email.trim() ?? '').split('@').first.trim();
    if (emailName.isNotEmpty) {
      return emailName;
    }

    return 'Neighbour';
  }

  LatLng _mapPreviewCenter() {
    if (_mapCenter != null) {
      return LatLng(_mapCenter!.latitude, _mapCenter!.longitude);
    }

    for (final complaint in _nearby) {
      final location = complaint.location;
      if (location != null) {
        return LatLng(location.latitude, location.longitude);
      }
    }

    return const LatLng(6.9271, 79.8612);
  }

  Set<Marker> _buildMapPreviewMarkers() {
    final markers = <Marker>{};

    if (_mapCenter != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('home_current_location'),
          position: LatLng(_mapCenter!.latitude, _mapCenter!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Current location'),
        ),
      );
    }

    for (final complaint in _nearby.take(20)) {
      final location = complaint.location;
      if (location == null) {
        continue;
      }

      markers.add(
        Marker(
          markerId: MarkerId('home_${complaint.complaintId}'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: complaint.displayTitle,
            snippet: complaint.status,
          ),
        ),
      );
    }

    return markers;
  }

  latlng.LatLng _mapPreviewCenterOsm() {
    final center = _mapPreviewCenter();
    return latlng.LatLng(center.latitude, center.longitude);
  }

  List<osm.Marker> _buildOsmMapPreviewMarkers() {
    final markers = <osm.Marker>[];

    if (_mapCenter != null) {
      markers.add(
        osm.Marker(
          point: latlng.LatLng(_mapCenter!.latitude, _mapCenter!.longitude),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.my_location,
            color: Color(0xFF60A5FA),
            size: 28,
          ),
        ),
      );
    }

    for (final complaint in _nearby.take(20)) {
      final location = complaint.location;
      if (location == null) {
        continue;
      }

      markers.add(
        osm.Marker(
          point: latlng.LatLng(location.latitude, location.longitude),
          width: 30,
          height: 30,
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFF59E0B),
            size: 26,
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadDashboard,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadDashboard(showLoader: false),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'Community Platform',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC4C4C4),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _signOut,
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Text('🏙️', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'UrbanCare',
                          style: GoogleFonts.syne(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome back, ${_welcomeName()}',
                      style: const TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Complain',
                      onPressed: _goToCreate,
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Map',
                      isSecondary: true,
                      onPressed: _goToMap,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MAP PREVIEW',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: IgnorePointer(
                                child: kIsWeb
                                    ? osm.FlutterMap(
                                        options: osm.MapOptions(
                                          initialCenter: _mapPreviewCenterOsm(),
                                          initialZoom: 14,
                                        ),
                                        children: [
                                          osm.TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'com.urbancare.urbancare_frontend',
                                          ),
                                          osm.MarkerLayer(
                                            markers: _buildOsmMapPreviewMarkers(),
                                          ),
                                        ],
                                      )
                                    : GoogleMap(
                                        initialCameraPosition: CameraPosition(
                                          target: _mapPreviewCenter(),
                                          zoom: 14,
                                        ),
                                        markers: _buildMapPreviewMarkers(),
                                        myLocationEnabled: _mapCenter != null,
                                        myLocationButtonEnabled: false,
                                        zoomControlsEnabled: false,
                                        compassEnabled: false,
                                      ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _goToMap,
                              child: const Text('Open full map'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'NEARBY ALERTS',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _nearby.length.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA3A3A3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_nearby.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Text(
                    'No nearby alerts right now.',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                )
              else
                ..._nearby.map(
                  (complaint) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ComplaintCard(
                      complaint: complaint,
                      onTap: () => _openComplaint(complaint),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
