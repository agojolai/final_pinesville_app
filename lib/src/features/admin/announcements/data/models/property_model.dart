import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String id;
  final String name;

  PropertyModel({
    required this.id,
    required this.name,
  });

  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyModel(
      id: doc.id,
      name: data['name'] ?? data['propertyName'] ?? '',
    );
  }
}
