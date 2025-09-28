import 'package:cloud_firestore/cloud_firestore.dart';

enum OccupantStatus {
  active,
  pending,
  deleted;

  String get value {
    switch (this) {
      case OccupantStatus.active:
        return 'ACTIVE';
      case OccupantStatus.pending:
        return 'PENDING';
      case OccupantStatus.deleted:
        return 'DELETED';
    }
  }

  static OccupantStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return OccupantStatus.active;
      case 'PENDING':
        return OccupantStatus.pending;
      case 'DELETED':
        return OccupantStatus.deleted;
      default:
        return OccupantStatus.active; // Default to active for backward compatibility
    }
  }
}

class OccupantModel {
  final String? id;
  final String occupantName;
  final String occupantPhone;
  final OccupantStatus status;

  const OccupantModel({
    this.id,
    required this.occupantName,
    required this.occupantPhone,
    this.status = OccupantStatus.active,
  });

  // Static function to create an empty occupant model
  static OccupantModel empty() => const OccupantModel(
        id: "",
        occupantName: "",
        occupantPhone: "",
        status: OccupantStatus.active,
      );

  // Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      'occupantName': occupantName,
      'occupantPhone': occupantPhone,
      'status': status.value,
    };
  }

  // Factory method to create an OccupantModel from a Firebase document snapshot
  factory OccupantModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return OccupantModel(
        id: document.id,
        occupantName: data['occupantName'] ?? "",
        occupantPhone: data['occupantPhone'] ?? "",
        status: OccupantStatus.fromString(data['status'] ?? 'ACTIVE'),
      );
    } else {
      return OccupantModel.empty();
    }
  }

  // Create OccupantModel from Map (for subcollection queries)
  factory OccupantModel.fromMap(Map<String, dynamic> data, String id) {
    return OccupantModel(
      id: id,
      occupantName: data['occupantName'] ?? "",
      occupantPhone: data['occupantPhone'] ?? "",
      status: OccupantStatus.fromString(data['status'] ?? 'ACTIVE'),
    );
  }

  // Copy with method for immutable updates
  OccupantModel copyWith({
    String? id,
    String? occupantName,
    String? occupantPhone,
    OccupantStatus? status,
  }) {
    return OccupantModel(
      id: id ?? this.id,
      occupantName: occupantName ?? this.occupantName,
      occupantPhone: occupantPhone ?? this.occupantPhone,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OccupantModel &&
        other.id == id &&
        other.occupantName == occupantName &&
        other.occupantPhone == occupantPhone &&
        other.status == status;
  }

  @override
  int get hashCode => id.hashCode ^ occupantName.hashCode ^ occupantPhone.hashCode ^ status.hashCode;

  @override
  String toString() => 'OccupantModel(id: $id, occupantName: $occupantName, occupantPhone: $occupantPhone, status: $status)';
}