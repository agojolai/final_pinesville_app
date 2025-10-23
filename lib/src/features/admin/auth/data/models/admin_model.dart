import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String adminId;
  final String userId; // Firebase Auth UID
  final String email;
  final AdminProfile profile;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AdminModel({
    required this.adminId,
    required this.userId,
    required this.email,
    required this.profile,
    required this.createdAt,
    this.updatedAt,
  });

  // Get full name
  String get fullName => '${profile.firstName} ${profile.lastName}'.trim();

  // Get display name (full name or email if name is empty)
  String get displayName => fullName.isEmpty ? email : fullName;

  factory AdminModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel.fromJson(data, doc.id);
  }

  factory AdminModel.fromJson(Map<String, dynamic> json, String docId) {
    return AdminModel(
      adminId: docId,
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profile: AdminProfile.fromJson(json['profile'] as Map<String, dynamic>? ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'profile': profile.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  AdminModel copyWith({
    String? adminId,
    String? userId,
    String? email,
    AdminProfile? profile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminModel(
      adminId: adminId ?? this.adminId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AdminProfile {
  final String firstName;
  final String lastName;

  AdminProfile({
    required this.firstName,
    required this.lastName,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  AdminProfile copyWith({
    String? firstName,
    String? lastName,
  }) {
    return AdminProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}
