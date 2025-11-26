import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final List<String> recipients;
  final DateTime timestamp;
  final String? status;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.recipients,
    required this.timestamp,
    this.status,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      recipients: (data['recipients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'recipients': recipients,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status ?? 'sent',
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? message,
    List<String>? recipients,
    DateTime? timestamp,
    String? status,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      recipients: recipients ?? this.recipients,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
