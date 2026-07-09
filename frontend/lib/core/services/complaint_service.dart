import 'package:image_picker/image_picker.dart';
import 'package:urbancare_frontend/core/api/api_client.dart';
import 'package:urbancare_frontend/models/complaint.dart';
import 'package:urbancare_frontend/models/location.dart';

class ComplaintService {
  ComplaintService(this._apiClient);

  final ApiClient _apiClient;

  Future<String?> uploadComplaintImage({required XFile? image}) async {
    if (image == null) {
      return null;
    }

    final bytes = await image.readAsBytes();
    final filename = image.name.isEmpty ? 'image.jpg' : image.name;

    final response = await _apiClient.postMultipart(
      '/complaints/upload-image',
      fieldName: 'image',
      filename: filename,
      bytes: bytes,
      authRequired: true,
    );

    final imageUrl = (response['image_url'] ?? '').toString();
    return imageUrl.isEmpty ? null : imageUrl;
  }

  Future<ComplaintModel> createComplaint({
    required String issueType,
    required String title,
    required String description,
    required AppLocation location,
    String? primaryImageUrl,
  }) async {
    final response = await _apiClient.postJson(
      '/complaints/',
      authRequired: true,
      body: {
        'issue_type': issueType,
        'title': title,
        'description': description,
        'location': location.toApiJson(),
        'image_urls': primaryImageUrl == null ? <String>[] : [primaryImageUrl],
      },
    );

    return ComplaintModel.fromComplaintJson(response);
  }

  Future<List<ComplaintModel>> fetchComplaints() async {
    final response = await _apiClient.getList(
      '/complaints/',
      authRequired: true,
    );

    return response
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => ComplaintModel.fromComplaintJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<ComplaintModel> fetchComplaintById(String complaintId) async {
    final response = await _apiClient.getJson(
      '/complaints/$complaintId',
      authRequired: true,
    );

    return ComplaintModel.fromComplaintJson(response);
  }

  Future<ComplaintModel> verifyComplaint({
    required String complaintId,
    required bool isFixed,
    required String feedbackType,
  }) async {
    final response = await _apiClient.postJson(
      '/complaints/$complaintId/verify',
      authRequired: true,
      queryParams: {
        'is_fixed': isFixed.toString(),
        'feedback_type': feedbackType,
      },
      body: const {},
    );

    return ComplaintModel.fromComplaintJson(response);
  }

  Future<List<ComplaintModel>> fetchNearbyComplaints({
    required double lat,
    required double lng,
  }) async {
    final response = await _apiClient.getList(
      '/geofence/nearby',
      queryParams: {
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );

    return response
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => ComplaintModel.fromNearbyJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<List<ComplaintModel>> fetchMyComplaints() async {
    final response = await _apiClient.getList(
      '/complaints/my',
      authRequired: true,
    );

    return response
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => ComplaintModel.fromComplaintJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }
}
