class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.district,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? district;

  Map<String, dynamic> toApiJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'district': district,
    };
  }

  factory AppLocation.fromJson(Map<String, dynamic> json) {
    return AppLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
    );
  }
}
