import 'dart:convert';

class User {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String role;
  final String status;

  User({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.email,
    required this.role,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      role: json['role'] ?? 'customer',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'status': status,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory User.fromJsonString(String jsonString) {
    return User.fromJson(jsonDecode(jsonString));
  }

  User copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? role,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, role: $role)';
  }
}

