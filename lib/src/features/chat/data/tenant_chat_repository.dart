import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';

final tenantChatRepositoryProvider = Provider<TenantChatRepository>((ref) {
  return TenantChatRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    storage: FirebaseStorage.instance,
  );
});

class TenantChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseStorage storage;

  TenantChatRepository({
    required this.firestore,
    required this.auth,
    required this.storage,
  });

  String? get currentUserId => auth.currentUser?.uid;

  Stream<QuerySnapshot> getMessagesStream() {
    if (currentUserId == null) {
      AppLogger.warning('No authenticated user found');
      return const Stream.empty();
    }
    
    final chatId = 'chat_$currentUserId';
    AppLogger.debug('Getting messages stream for tenant chatId: $chatId');
    
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage({
    required String text,
    String? imageUrl,
    String? videoUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final chatId = 'chat_$currentUserId';
    final chatRef = firestore.collection('chats').doc(chatId);
    
    final userDoc = await firestore.collection('Users').doc(currentUserId).get();
    final userData = userDoc.data();
    final profile = userData?['profile'] as Map<String, dynamic>? ?? {};
    final firstName = profile['firstName'] as String? ?? '';
    final lastName = profile['lastName'] as String? ?? '';
    final senderName = '$firstName $lastName'.trim();
    
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      String lastMessageText = text.isNotEmpty ? text : (videoUrl != null ? 'Video' : 'Image');
      await chatRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [currentUserId, 'admin'],
        'lastMessage': lastMessageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      AppLogger.debug('Created new chat document for tenant: $chatId');
    }
    
    await chatRef.collection('messages').add({
      'text': text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'senderId': currentUserId,
      'senderName': senderName,
      'senderType': 'tenant',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    String lastMessageText = text.isNotEmpty ? text : (videoUrl != null ? 'Video' : 'Image');
    await chatRef.update({
      'lastMessage': lastMessageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    AppLogger.debug('Message sent successfully from tenant to admin');
  }

  Future<String> uploadImage(File imageFile) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = storage.ref().child('chats/$currentUserId/$fileName');
    
    AppLogger.debug('Uploading image to: chats/$currentUserId/$fileName');
    
    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    AppLogger.debug('Image uploaded successfully: $downloadUrl');
    return downloadUrl;
  }

  Future<String> uploadVideo(File videoFile) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = storage.ref().child('chats/$currentUserId/$fileName');
    
    AppLogger.debug('Uploading video to: chats/$currentUserId/$fileName');
    
    final uploadTask = ref.putFile(videoFile);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    
    AppLogger.debug('Video uploaded successfully: $downloadUrl');
    return downloadUrl;
  }
}
