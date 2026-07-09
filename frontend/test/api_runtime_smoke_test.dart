import 'package:flutter_test/flutter_test.dart';
import 'package:urbancare_frontend/core/api/api_client.dart';
import 'package:urbancare_frontend/core/services/auth_service.dart';
import 'package:urbancare_frontend/core/services/complaint_service.dart';
import 'package:urbancare_frontend/core/utils/token_storage.dart';
import 'package:urbancare_frontend/models/location.dart';

class _InMemoryTokenStorage extends TokenStorage {
  String? _token;

  @override
  Future<String?> getToken() async {
    return _token;
  }

  void setToken(String token) {
    _token = token;
  }
}

void main() {
  test('live backend smoke via frontend services', () async {
    const baseUrl = 'http://127.0.0.1:8000';
    final storage = _InMemoryTokenStorage();
    final apiClient = ApiClient(baseUrl: baseUrl, tokenStorage: storage);
    final authService = AuthService(apiClient);
    final complaintService = ComplaintService(apiClient);

    final now = DateTime.now().millisecondsSinceEpoch;
    final email = 'flutter.smoke.$now@test.com';
    final phoneSuffix = (now % 1000000000).toString().padLeft(9, '0');
    final phone = '9$phoneSuffix';
    const password = 'Pass@1234';

    final signupUser = await authService.signup(
      name: 'Flutter Smoke User',
      email: email,
      phoneNumber: phone,
      password: password,
      role: 'citizen',
    );
    expect(signupUser.email, email);

    final token = await authService.login(
      email: email,
      password: password,
    );
    expect(token.isNotEmpty, true);
    storage.setToken(token);

    final createdComplaint = await complaintService.createComplaint(
      issueType: 'road_damage',
      title: 'Flutter Runtime Smoke Complaint',
      description: 'Created from flutter test runtime',
      location: const AppLocation(
        latitude: 6.9271,
        longitude: 79.8612,
        address: 'Runtime Test Address',
        city: 'Colombo',
        district: 'Colombo',
      ),
    );
    expect(createdComplaint.complaintId.isNotEmpty, true);

    final complaints = await complaintService.fetchComplaints();
    expect(
      complaints.any((c) => c.complaintId == createdComplaint.complaintId),
      true,
    );

    final detail = await complaintService.fetchComplaintById(
      createdComplaint.complaintId,
    );
    expect(detail.complaintId, createdComplaint.complaintId);

    final verified = await complaintService.verifyComplaint(
      complaintId: createdComplaint.complaintId,
      isFixed: true,
      feedbackType: 'fixed',
    );
    expect(verified.complaintId, createdComplaint.complaintId);

    final nearby = await complaintService.fetchNearbyComplaints(
      lat: 6.9271,
      lng: 79.8612,
    );
    expect(nearby, isA<List>());
  });
}
