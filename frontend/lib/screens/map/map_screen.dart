import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:urbancare_frontend/models/complaint.dart';
import 'package:urbancare_frontend/models/location.dart';
import 'package:urbancare_frontend/repositories/complaint_repository.dart';
import 'package:urbancare_frontend/widgets/complaint_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.complaintRepository,
  });

  final ComplaintRepository complaintRepository;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _loading = true;
  String? _error;
  AppLocation? _userLocation;
  List<ComplaintModel> _nearby = const [];

  final osm.MapController _osmMapController = osm.MapController();
  GoogleMapController? _googleMapController;

  latlng.LatLng _osmCenterValue = const latlng.LatLng(6.9271, 79.8612);
  double _mapZoom = 14;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      AppLocation? location;
      try {
        location = await widget.complaintRepository.getCurrentLocation();
      } catch (_) {
        location = null;
      }

      List<ComplaintModel> nearby;
      if (location != null) {
        nearby = await widget.complaintRepository.getNearbyComplaints();
      } else {
        nearby = await widget.complaintRepository.getAllComplaints();
      }

      if (nearby.isEmpty) {
        nearby = await widget.complaintRepository.getAllComplaints();
      }

      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _nearby = nearby;
        if (location != null) {
          _osmCenterValue = latlng.LatLng(location.latitude, location.longitude);
        }
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

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    }

    for (final complaint in _nearby) {
      final loc = complaint.location;
      if (loc == null) {
        continue;
      }

      markers.add(
        Marker(
          markerId: MarkerId(complaint.complaintId),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(
            title: complaint.displayTitle,
            snippet: complaint.status,
          ),
        ),
      );
    }

    return markers;
  }

  latlng.LatLng _osmCenter() {
    return _osmCenterValue;
  }

  List<osm.Marker> _buildOsmMarkers() {
    final markers = <osm.Marker>[];

    if (_userLocation != null) {
      markers.add(
        osm.Marker(
          point: latlng.LatLng(_userLocation!.latitude, _userLocation!.longitude),
          width: 42,
          height: 42,
          child: const Icon(
            Icons.my_location,
            color: Color(0xFF60A5FA),
            size: 30,
          ),
        ),
      );
    }

    for (final complaint in _nearby) {
      final location = complaint.location;
      if (location == null) {
        continue;
      }

      markers.add(
        osm.Marker(
          point: latlng.LatLng(location.latitude, location.longitude),
          width: 34,
          height: 34,
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFF59E0B),
            size: 30,
          ),
        ),
      );
    }

    return markers;
  }

  void _zoomIn() {
    const minZoom = 3.0;
    const maxZoom = 19.0;
    final nextZoom = (_mapZoom + 1).clamp(minZoom, maxZoom).toDouble();

    if (kIsWeb) {
      _osmMapController.move(_osmCenterValue, nextZoom);
    } else {
      _googleMapController?.animateCamera(CameraUpdate.zoomTo(nextZoom));
    }

    setState(() => _mapZoom = nextZoom);
  }

  void _zoomOut() {
    const minZoom = 3.0;
    const maxZoom = 19.0;
    final nextZoom = (_mapZoom - 1).clamp(minZoom, maxZoom).toDouble();

    if (kIsWeb) {
      _osmMapController.move(_osmCenterValue, nextZoom);
    } else {
      _googleMapController?.animateCamera(CameraUpdate.zoomTo(nextZoom));
    }

    setState(() => _mapZoom = nextZoom);
  }

  Widget _buildZoomControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Community Map')),
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
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final center = _userLocation == null
        ? const LatLng(6.9271, 79.8612)
        : LatLng(_userLocation!.latitude, _userLocation!.longitude);

    return Scaffold(
      appBar: AppBar(title: const Text('Community Map')),
      body: Column(
        children: [
          Container(
            height: 310,
            margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: kIsWeb
                      ? osm.FlutterMap(
                          mapController: _osmMapController,
                          options: osm.MapOptions(
                            initialCenter: _osmCenter(),
                            initialZoom: _mapZoom,
                            interactionOptions: const osm.InteractionOptions(
                              flags: osm.InteractiveFlag.all,
                            ),
                            onPositionChanged: (position, hasGesture) {
                              final nextCenter = position.center;
                              final nextZoom = position.zoom;
                              if (nextCenter != null) {
                                _osmCenterValue = nextCenter;
                              }
                              if (nextZoom != null) {
                                _mapZoom = nextZoom;
                              }
                            },
                          ),
                          children: [
                            osm.TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.urbancare.urbancare_frontend',
                            ),
                            osm.MarkerLayer(markers: _buildOsmMarkers()),
                          ],
                        )
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: center,
                            zoom: _mapZoom,
                          ),
                          onMapCreated: (controller) {
                            _googleMapController = controller;
                          },
                          onCameraMove: (position) {
                            _mapZoom = position.zoom;
                          },
                          myLocationEnabled: _userLocation != null,
                          myLocationButtonEnabled: _userLocation != null,
                          zoomControlsEnabled: true,
                          zoomGesturesEnabled: true,
                          markers: _buildMarkers(),
                        ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: [
                      _buildZoomControlButton(
                        icon: Icons.add,
                        onPressed: _zoomIn,
                      ),
                      const SizedBox(height: 8),
                      _buildZoomControlButton(
                        icon: Icons.remove,
                        onPressed: _zoomOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _nearby.isEmpty
                ? const Center(
                    child: Text(
                      'No nearby complaints found for this location.',
                      style: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemBuilder: (_, index) {
                        final complaint = _nearby[index];
                        return ComplaintCard(complaint: complaint);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: _nearby.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
