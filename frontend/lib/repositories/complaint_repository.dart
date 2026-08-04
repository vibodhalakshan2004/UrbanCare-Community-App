import 'package:image_picker/image_picker.dart';
import 'package:urbancare_frontend/core/services/complaint_service.dart';
import 'package:urbancare_frontend/core/services/location_service.dart';
import 'package:urbancare_frontend/models/complaint.dart';
import 'package:urbancare_frontend/models/location.dart';
import 'package:urbancare_frontend/repositories/auth_repository.dart';

class ComplaintRepository {
  ComplaintRepository({
    required ComplaintService complaintService,
    required LocationService locationService,
    required AuthRepository authRepository,
  })  : _complaintService = complaintService,
        _locationService = locationService,
        _authRepository = authRepository;

  final ComplaintService _complaintService;
  final LocationService _locationService;
  final AuthRepository _authRepository;

  Future<List<ComplaintModel>> getAllComplaints() {
    return _complaintService.fetchComplaints();
  }

  Future<ComplaintModel> getComplaintById(String complaintId) {
    return _complaintService.fetchComplaintById(complaintId);
  }

  Future<List<ComplaintModel>> getNearbyComplaints() async {
    final location = await _locationService.getCurrentAppLocation();

    return _complaintService.fetchNearbyComplaints(
      lat: location.latitude,
      lng: location.longitude,
    );
  }

  Future<AppLocation> getCurrentLocation() {
    return _locationService.getCurrentAppLocation();
  }

  Future<AppLocation> getFreshCurrentLocation() {
    return _locationService.getFreshCurrentAppLocation();
  }

  Future<ComplaintModel> createComplaint({
    required String issueType,
    required String title,
    required String description,
    required XFile? image,
    AppLocation? location,
  }) async {
    final user = await _authRepository.getSavedUser();
    if (user == null || user.userId.isEmpty) {
      throw Exception('User session not found. Please login again.');
    }

    final resolvedLocation =
        location ??
        await _locationService.getCurrentAppLocation(
          fallbackAddress: 'Current device location',
        );

    final imageUrl = await _complaintService.uploadComplaintImage(image: image);

    final payloadDescription = title.trim().isEmpty
        ? description
        : '$title\n\n$description';

    return _complaintService.createComplaint(
      issueType: issueType,
      title: title,
      description: payloadDescription,
      location: resolvedLocation,
      primaryImageUrl: imageUrl,
    );
  }

  Future<ComplaintModel> verifyComplaint({
    required String complaintId,
    required bool isFixed,
    required String feedbackType,
  }) async {
    final user = await _authRepository.getSavedUser();
    if (user == null || user.userId.isEmpty) {
      throw Exception('User session not found. Please login again.');
    }

    return _complaintService.verifyComplaint(
      complaintId: complaintId,
      isFixed: isFixed,
      feedbackType: feedbackType,
    );
  }

  Future<List<ComplaintModel>> getMyComplaints() {
    return _complaintService.fetchMyComplaints();
  }
}
