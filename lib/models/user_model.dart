class UserModel {
  final String id;
  final String name;
  final String email;
  final String status;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      status: json['status'] ?? 'offline',
      avatarUrl: json['avatarUrl'],
    );
  }
}