import 'package:cloud_firestore/cloud_firestore.dart';

class OccupantModel {
  final String? id;
  final String occupantName;
  final String occupantPhone;

  const OccupantModel({
    this.id,
    required this.occupantName,
    required this.occupantPhone,
  });

  // Static function to create an empty occupant model
  static OccupantModel empty() => const OccupantModel(
        id: "",
        occupantName: "",
        occupantPhone: "",
      );

  // Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      'occupantName': occupantName,
      'occupantPhone': occupantPhone,
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
    );
  }

  // Copy with method for immutable updates
  OccupantModel copyWith({
    String? id,
    String? occupantName,
    String? occupantPhone,
  }) {
    return OccupantModel(
      id: id ?? this.id,
      occupantName: occupantName ?? this.occupantName,
      occupantPhone: occupantPhone ?? this.occupantPhone,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OccupantModel &&
        other.id == id &&
        other.occupantName == occupantName &&
        other.occupantPhone == occupantPhone;
  }

  @override
  int get hashCode => id.hashCode ^ occupantName.hashCode ^ occupantPhone.hashCode;

  @override
  String toString() => 'OccupantModel(id: $id, occupantName: $occupantName, occupantPhone: $occupantPhone)';
}