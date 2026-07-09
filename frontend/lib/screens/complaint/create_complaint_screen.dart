import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:urbancare_frontend/models/location.dart';
import 'package:urbancare_frontend/repositories/complaint_repository.dart';
import 'package:urbancare_frontend/widgets/primary_button.dart';
import 'package:urbancare_frontend/widgets/text_input.dart';
import 'package:urbancare_frontend/theme/app_theme.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({
    super.key,
    required this.complaintRepository,
  });

  final ComplaintRepository complaintRepository;

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _picker = ImagePicker();

  bool _loadingLocation = true;
  bool _submitting = false;
  bool _manualLocationMode = false;
  AppLocation? _location;
  AppLocation? _selectedLocation;
  latlng.LatLng? _mapCenter;
  int _mapRevision = 0;
  XFile? _pickedImage;
  String _issueType = 'road_damage';

  static const _issueItems = <String, String>{
    'road_damage': '🚧 Road Damage',
    'streetlight': '💡 Street Light',
    'garbage': '🗑️ Garbage',
    'water': '🌊 Water / Flooding',
    'other': '📌 Other',
  };

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation({
    bool forceSelectCurrent = false,
    bool requireFresh = false,
  }) async {
    setState(() => _loadingLocation = true);
    try {
      final location = requireFresh
          ? await widget.complaintRepository.getFreshCurrentLocation()
          : await widget.complaintRepository.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _location = location;
        if (forceSelectCurrent) {
          _selectedLocation = location;
        } else if (_manualLocationMode) {
          _selectedLocation ??= location;
        } else {
          _selectedLocation = location;
        }
        _syncMapCenter();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    await _loadLocation(forceSelectCurrent: true, requireFresh: true);
  }

  String _formatCoordinates(AppLocation location) {
    return '${location.latitude.toStringAsFixed(5)}, '
        '${location.longitude.toStringAsFixed(5)}';
  }

  void _toggleManualLocationMode(bool enabled) {
    setState(() {
      _manualLocationMode = enabled;

      // Manual mode off means user wants to use current GPS location directly.
      if (!enabled && _location != null) {
        _selectedLocation = _location;
      }

      _syncMapCenter();
    });
  }

  void _selectLocation(double latitude, double longitude) {
    if (!_manualLocationMode) {
      return;
    }

    setState(() {
      _selectedLocation = AppLocation(
        latitude: latitude,
        longitude: longitude,
        address: _location?.address ?? 'Selected from map',
        city: _location?.city,
        district: _location?.district,
      );
      _syncMapCenter();
    });
  }

  void _syncMapCenter() {
    final target = _selectedLocation ?? _location;
    if (target == null) {
      return;
    }

    _mapCenter = latlng.LatLng(target.latitude, target.longitude);
    _mapRevision++;
  }

  void _selectLocationOnOsmMap(latlng.LatLng target) {
    _selectLocation(target.latitude, target.longitude);
  }

  List<osm.Marker> _buildOsmLocationMarkers() {
    final markers = <osm.Marker>[];

    if (_location != null) {
      markers.add(
        osm.Marker(
          point: latlng.LatLng(_location!.latitude, _location!.longitude),
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

    if (_selectedLocation != null) {
      markers.add(
        osm.Marker(
          point: latlng.LatLng(
            _selectedLocation!.latitude,
            _selectedLocation!.longitude,
          ),
          width: 38,
          height: 38,
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFF59E0B),
            size: 32,
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() => _pickedImage = image);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedLocation = _selectedLocation ?? _location;
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please allow location and try again.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.complaintRepository.createComplaint(
        issueType: _issueType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        image: _pickedImage,
        location: selectedLocation,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TYPE',
                style: TextStyle(
                  color: context.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _issueType,
                decoration: const InputDecoration(),
                items: _issueItems.entries
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.key,
                        child: Text(item.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _issueType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextInput(
                controller: _titleController,
                hint: 'Title',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextInput(
                controller: _descriptionController,
                hint: 'Describe the issue...',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Text(
                'LOCATION',
                style: TextStyle(
                  color: context.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.fill04,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: _loadingLocation
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedLocation == null
                                  ? 'Location unavailable'
                                  : _formatCoordinates(_selectedLocation!),
                              style: TextStyle(color: context.onSurfaceVariant),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.fill08,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _manualLocationMode ? 'Manual' : 'Current',
                              style: TextStyle(
                                color: context.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: _loadLocation,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.fill04,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_location_alt_outlined, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Issue is a bit away? Select location manually',
                        style: TextStyle(color: context.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                    Switch.adaptive(
                      value: _manualLocationMode,
                      onChanged: _toggleManualLocationMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 210,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: _loadingLocation
                    ? const Center(child: CircularProgressIndicator())
                    : (_location == null && _selectedLocation == null)
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Location unavailable. Refresh and allow location to pick on map.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.onSurfaceVariant),
                              ),
                            ),
                          )
                        : osm.FlutterMap(
                            key: ValueKey<String>(
                              '${(_mapCenter ?? latlng.LatLng((_selectedLocation ?? _location!).latitude, (_selectedLocation ?? _location!).longitude)).latitude.toStringAsFixed(6)}:'
                              '${(_mapCenter ?? latlng.LatLng((_selectedLocation ?? _location!).latitude, (_selectedLocation ?? _location!).longitude)).longitude.toStringAsFixed(6)}:'
                              '$_manualLocationMode:'
                              '$_mapRevision',
                            ),
                            options: osm.MapOptions(
                              initialCenter: _mapCenter ??
                                  latlng.LatLng(
                                    (_selectedLocation ?? _location!).latitude,
                                    (_selectedLocation ?? _location!).longitude,
                                  ),
                              initialZoom: 16,
                              onTap: _manualLocationMode
                                  ? (_, point) => _selectLocationOnOsmMap(point)
                                  : null,
                            ),
                            children: [
                              osm.TileLayer(
                                urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.urbancare.urbancare_frontend',
                              ),
                              osm.MarkerLayer(markers: _buildOsmLocationMarkers()),
                            ],
                          ),
              ),
              const SizedBox(height: 6),
              Text(
                _manualLocationMode
                    ? 'Tap on the map to choose complaint location. Blue marker is current location.'
                    : 'Using your current location. Enable manual mode to select a different point.',
                style: TextStyle(color: context.onSurfaceVariant, fontSize: 12),
              ),
              if (_location != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _loadingLocation ? null : _useCurrentLocation,
                    icon: const Icon(Icons.my_location_outlined),
                    label: const Text('Use current location'),
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'PHOTO',
                style: TextStyle(
                  color: context.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_outlined),
                label: Text(
                  _pickedImage == null ? 'Choose image' : 'Change image',
                ),
              ),
              if (_pickedImage != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(
                          _pickedImage!.path,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_pickedImage!.path),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Report',
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
