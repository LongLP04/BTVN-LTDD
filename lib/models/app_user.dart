class AppUser {
  final String id;
  final String userName;
  final String role;
  final String? email;

  const AppUser({
    required this.id,
    required this.userName,
    required this.role,
    this.email,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final username = json['userName'] ?? json['username'] ?? '';
    final roleValue = json['role'] ?? json['roleName'] ?? 'User';

    return AppUser(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      userName: username,
      role: roleValue.toString(),
      email: json['email'] ?? json['emailAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'role': role,
      if (email != null) 'email': email,
    };
  }
}
