class UserModel {
  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
  });

  final String userId;
  final String name;
  final String email;
  final String role;
  final String? phoneNumber;

  factory UserModel.fromSignupJson(Map<String, dynamic> json) {
    return UserModel(
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'citizen').toString(),
      phoneNumber: json['phone_number']?.toString(),
    );
  }

  factory UserModel.fromSession(Map<String, String?> data) {
    return UserModel(
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'citizen',
<<<<<<< HEAD
      phoneNumber: data['phone'],
=======
>>>>>>> origin/main
    );
  }
}
