import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:urbancare_frontend/models/complaint.dart';
import 'package:urbancare_frontend/repositories/complaint_repository.dart';
import 'package:urbancare_frontend/widgets/primary_button.dart';
import 'package:urbancare_frontend/theme/app_theme.dart';

<<<<<<< HEAD
enum _VerificationChoice { fixed, stillThere, gotWorse }

=======
>>>>>>> origin/main
class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
    required this.complaintRepository,
  });

  final ComplaintModel complaint;
  final ComplaintRepository complaintRepository;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late ComplaintModel _complaint;
  _VerificationChoice? _selectedChoice;
  bool _loading = true;
  bool _verifying = false;
  final _mapController = fm.MapController();

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    _selectedChoice = _choiceFromComplaint(_complaint);
    _loadLatest();
  }

<<<<<<< HEAD
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }



  _VerificationChoice? _choiceFromComplaint(ComplaintModel complaint) {
    final feedback = complaint.myFeedbackType?.toLowerCase().trim();
    if (feedback == 'fixed') {
      return _VerificationChoice.fixed;
    }
    if (feedback == 'got_worse') {
      return _VerificationChoice.gotWorse;
    }
    if (feedback == 'still_there') {
      return _VerificationChoice.stillThere;
    }

    if (complaint.myVerification == true) {
      return _VerificationChoice.fixed;
    }
    if (complaint.myVerification == false) {
      return _VerificationChoice.stillThere;
    }
    return null;
  }

  Future<void> _loadLatest() async {
    try {
      final fresh =
          await widget.complaintRepository.getComplaintById(_complaint.complaintId);

=======
  Future<void> _loadLatest() async {
    try {
      final fresh =
          await widget.complaintRepository.getComplaintById(_complaint.complaintId);

>>>>>>> origin/main
      if (!mounted) return;
      setState(() {
        _complaint = ComplaintModel(
          complaintId: fresh.complaintId,
          issueType: fresh.issueType.isEmpty ? _complaint.issueType : fresh.issueType,
          description: fresh.description.isEmpty
              ? _complaint.description
              : fresh.description,
          status: fresh.status,
          citizenId: fresh.citizenId ?? _complaint.citizenId,
          locationId: fresh.locationId ?? _complaint.locationId,
          location: fresh.location ?? _complaint.location,
          distanceMeters: _complaint.distanceMeters ?? fresh.distanceMeters,
          primaryImageUrl: fresh.primaryImageUrl ?? _complaint.primaryImageUrl,
          myVerification: fresh.myVerification,
          myFeedbackType: fresh.myFeedbackType,
        );
<<<<<<< HEAD
        _selectedChoice = _choiceFromComplaint(_complaint);
=======
>>>>>>> origin/main
      });
    } catch (_) {
      // Keep existing data on detail if fetch fails.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _verify({
    required bool isFixed,
    required _VerificationChoice choice,
    required String successMessage,
  }) async {
    if (_verifying) {
      return;
    }

    setState(() => _verifying = true);
    try {
      final updated = await widget.complaintRepository.verifyComplaint(
        complaintId: _complaint.complaintId,
        isFixed: isFixed,
        feedbackType: _feedbackTypeFromChoice(choice),
      );

      if (!mounted) return;
      setState(() {
        _complaint = ComplaintModel(
          complaintId: updated.complaintId,
          issueType:
              updated.issueType.isEmpty ? _complaint.issueType : updated.issueType,
          description:
              updated.description.isEmpty ? _complaint.description : updated.description,
          status: updated.status,
          citizenId: updated.citizenId ?? _complaint.citizenId,
          locationId: updated.locationId ?? _complaint.locationId,
          location: _complaint.location,
          distanceMeters: _complaint.distanceMeters,
          primaryImageUrl: _complaint.primaryImageUrl,
          myVerification: updated.myVerification,
          myFeedbackType: updated.myFeedbackType,
        );
        _selectedChoice = _choiceFromComplaint(_complaint) ?? choice;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  String _feedbackTypeFromChoice(_VerificationChoice choice) {
    switch (choice) {
      case _VerificationChoice.fixed:
        return 'fixed';
      case _VerificationChoice.stillThere:
        return 'still_there';
      case _VerificationChoice.gotWorse:
        return 'got_worse';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_complaint.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.fill04,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: _complaint.primaryImageUrl == null
                      ? Text(
                          _complaint.emoji,
                          style: const TextStyle(fontSize: 56),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            _complaint.primaryImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Text(
                              _complaint.emoji,
                              style: const TextStyle(fontSize: 56),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _complaint.displayTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _complaint.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    color: context.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _complaint.description,
                  style: TextStyle(
                    color: context.onSurface,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.fill04,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    _complaint.location?.address ??
                        '📍 ${_complaint.location?.latitude.toStringAsFixed(5) ?? '-'}, '
                            '${_complaint.location?.longitude.toStringAsFixed(5) ?? '-'}',
                    style: TextStyle(color: context.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 18),
                if (_complaint.location != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 250,
                          child: fm.FlutterMap(
                            mapController: _mapController,
                            options: fm.MapOptions(
                              initialCenter: latlng.LatLng(
                                _complaint.location!.latitude,
                                _complaint.location!.longitude,
                              ),
                              initialZoom: 15,
                            ),
                            children: [
                              fm.TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.urbancare.urbancare_frontend',
                              ),
                              fm.MarkerLayer(
                                markers: [
                                  fm.Marker(
                                    point: latlng.LatLng(
                                      _complaint.location!.latitude,
                                      _complaint.location!.longitude,
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Color(0xFFEF4444),
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton(
                              mini: true,
                              heroTag: 'zoom_in',
                              backgroundColor: Colors.white,
                              onPressed: () {
                                _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom + 1,
                                );
                              },
                              child: const Icon(Icons.add, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              mini: true,
                              heroTag: 'zoom_out',
                              backgroundColor: Colors.white,
                              onPressed: () {
                                _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom - 1,
                                );
                              },
                              child: const Icon(Icons.remove, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                const SizedBox(height: 4),
                const Text(
                  'Confirm current status',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: _selectedChoice == _VerificationChoice.stillThere
                      ? '✓ 😐 Still There'
                      : '😐 Still There',
                  loading: _verifying,
                  isSecondary: _selectedChoice != _VerificationChoice.stillThere,
                  onPressed: () => _verify(
                    isFixed: false,
                    choice: _VerificationChoice.stillThere,
                    successMessage: 'Marked as still there.',
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: _selectedChoice == _VerificationChoice.fixed
                      ? '✓ ✅ It\'s Fixed!'
                      : '✅ It\'s Fixed!',
                  loading: _verifying,
                  isSecondary: _selectedChoice != _VerificationChoice.fixed,
                  onPressed: () => _verify(
                    isFixed: true,
                    choice: _VerificationChoice.fixed,
                    successMessage: 'Marked as fixed. Thanks!',
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: _selectedChoice == _VerificationChoice.gotWorse
                      ? '✓ ⚠️ Got Worse'
                      : '⚠️ Got Worse',
                  loading: _verifying,
                  isSecondary: _selectedChoice != _VerificationChoice.gotWorse,
                  onPressed: () => _verify(
                    isFixed: false,
                    choice: _VerificationChoice.gotWorse,
                    successMessage: 'Marked as getting worse.',
                  ),
                ),
              ],
            ),
    );
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'fixed' || normalized == 'closed' || normalized == 'resolved') {
      return const Color(0xFF4ADE80);
    }
    if (normalized == 'in_progress' || normalized == 'assigned') {
      return const Color(0xFF60A5FA);
    }
    return const Color(0xFFFBBF24);
  }
}
