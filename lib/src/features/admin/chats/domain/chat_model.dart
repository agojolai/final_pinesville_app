import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String? imageUrl;
  final String? videoUrl;
  final String senderId;
  final DateTime timestamp;
  final String? senderName; // Admin's name for multi-admin support
  final String senderType; // 'admin' or 'user'

  ChatMessage({
    required this.id,
    required this.text,
    this.imageUrl,
    this.videoUrl,
    required this.senderId,
    required this.timestamp,
    this.senderName,
    this.senderType = 'user',
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      senderId: data['senderId'] ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      senderName: data['senderName'],
      senderType: data['senderType'] ?? 'user',
    );
  }
}
