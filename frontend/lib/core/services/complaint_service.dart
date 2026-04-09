import 'package:urbancare_frontend/core/api/api_client.dart';
import 'package:urbancare_frontend/models/complaint.dart';
import 'package:urbancare_frontend/models/location.dart';

class ComplaintService {
  ComplaintService(this._apiClient);

  final ApiClient _apiClient;

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
  }) async {
    final response = await _apiClient.postJson(
      '/complaints/$complaintId/verify',
      authRequired: true,
      queryParams: {
        'is_fixed': isFixed.toString(),
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
}
