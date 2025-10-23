import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateModel {
  final String id;
  final String subject;
  final String message;
  final List<String> recipients;
  final DateTime? timestamp;

  TemplateModel({
    required this.id,
    required this.subject,
    required this.message,
    required this.recipients,
    this.timestamp,
  });

  factory TemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TemplateModel(
      id: doc.id,
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      recipients: (data['recipients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'message': message,
      'recipients': recipients,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
