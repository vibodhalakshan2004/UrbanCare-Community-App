import 'package:urbancare_frontend/models/location.dart';

class ComplaintModel {
  const ComplaintModel({
    required this.complaintId,
    required this.issueType,
    required this.description,
    required this.status,
    this.citizenId,
    this.locationId,
    this.location,
    this.distanceMeters,
    this.primaryImageUrl,
<<<<<<< HEAD
    this.myVerification,
    this.myFeedbackType,
    this.verificationCount = 0,
    this.notFixedCount = 0,
=======
>>>>>>> origin/main
  });

  final String complaintId;
  final String issueType;
  final String description;
  final String status;
  final String? citizenId;
  final String? locationId;
  final AppLocation? location;
  final double? distanceMeters;
  final String? primaryImageUrl;
<<<<<<< HEAD
  final bool? myVerification;
  final String? myFeedbackType;
  final int verificationCount;
  final int notFixedCount;
=======
>>>>>>> origin/main

  String get displayTitle {
    return _issueTypeLabels[issueType] ?? issueType.replaceAll('_', ' ');
  }

  String get emoji {
    return _issueTypeEmoji[issueType] ?? '📌';
  }

  bool get isResolved {
    final value = status.toLowerCase();
    return value == 'fixed' || value == 'closed' || value == 'resolved';
  }

  String get shortDescription {
    final normalized = description.replaceAll('\n', ' ').trim();
    if (normalized.length <= 90) {
      return normalized;
    }
    return '${normalized.substring(0, 90)}...';
  }

  factory ComplaintModel.fromComplaintJson(Map<String, dynamic> json) {
<<<<<<< HEAD
    final dynamic imageUrlsRaw = json['image_urls'];
    final List<String> imageUrls = imageUrlsRaw is List
        ? imageUrlsRaw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList()
        : const <String>[];

    final String? primaryImageUrl =
        json['primary_image_url']?.toString() ??
        (imageUrls.isNotEmpty ? imageUrls.first : null);

    // Parse location data from response
    AppLocation? location;
    if (json['location'] is Map<String, dynamic>) {
      location = AppLocation.fromJson(json['location']);
    }

=======
>>>>>>> origin/main
    return ComplaintModel(
      complaintId: (json['complaint_id'] ?? '').toString(),
      citizenId: json['citizen_id']?.toString(),
      locationId: json['location_id']?.toString(),
      issueType: (json['issue_type'] ?? 'other').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'created').toString(),
<<<<<<< HEAD
      primaryImageUrl: primaryImageUrl,
      location: location,
      myVerification: json['my_verification'] as bool?,
      myFeedbackType: json['my_feedback_type']?.toString(),
      verificationCount: (json['verification_count'] as num?)?.toInt() ?? 0,
      notFixedCount: (json['not_fixed_count'] as num?)?.toInt() ?? 0,
=======
      primaryImageUrl: json['primary_image_url']?.toString(),
>>>>>>> origin/main
    );
  }

  factory ComplaintModel.fromNearbyJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();

    return ComplaintModel(
      complaintId: (json['complaint_id'] ?? '').toString(),
      issueType: (json['issue_type'] ?? 'other').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'created').toString(),
      location: latitude != null && longitude != null
          ? AppLocation(
              latitude: latitude,
              longitude: longitude,
              address: json['address']?.toString(),
            )
          : null,
      distanceMeters:
          (json['distance_m'] as num?)?.toDouble() ??
              (json['distance'] as num?)?.toDouble(),
<<<<<<< HEAD
      myVerification: null,
      myFeedbackType: null,
=======
>>>>>>> origin/main
    );
  }
}

const Map<String, String> _issueTypeLabels = {
  'road_damage': 'Road Damage',
  'streetlight': 'Street Light',
  'garbage': 'Garbage',
  'water': 'Flooding / Water',
  'other': 'Other',
};

const Map<String, String> _issueTypeEmoji = {
  'road_damage': '🚧',
  'streetlight': '💡',
  'garbage': '🗑️',
  'water': '🌊',
  'other': '📌',
};
