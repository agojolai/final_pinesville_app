import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/notification_service.dart';

final chatsRepositoryProvider = Provider<ChatsRepository>((ref) {
  return ChatsRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    storage: FirebaseStorage.instance,
  );
});

class ChatsRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseStorage storage;

  ChatsRepository({
    required this.firestore,
    required this.auth,
    required this.storage,
  });

  Stream<QuerySnapshot> getUsersStream() {
    // Only return regular users, not admins
    return firestore.collection('Users').snapshots();
  }

  // Get all admins from the admin collection
  Stream<QuerySnapshot> getAdminsStream() {
    return firestore.collection('admin').snapshots();
  }

  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    AppLogger.debug('Getting messages stream for chatId: $chatId');
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Changed to ascending order
        .snapshots();
  }

  Future<DocumentSnapshot> getChatDoc(String chatId) {
    return firestore.collection('chats').doc(chatId).get();
  }

  Future<void> createChatIfNotExists(
      String chatId, String senderId, String? receiverId) async {
    final chatRef = firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [senderId, receiverId],
      });
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
    String? videoUrl,
    required String senderId,
    String? senderName,
    String senderType = 'user',
  }) async {
    final chatRef = firestore.collection('chats').doc(chatId);
    
    // Create chat document if it doesn't exist
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      String lastMessageText = text.isNotEmpty ? text : (videoUrl != null ? 'Video' : 'Image');
      await chatRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [senderId, chatId], // chatId is the userId in this case
        'lastMessage': lastMessageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      AppLogger.debug('Created new chat document for chatId: $chatId');
    }
    
    // Add the message to the messages subcollection
    await chatRef.collection('messages').add({
      'text': text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Update last message info in chat document
    String lastMessageText = text.isNotEmpty ? text : (videoUrl != null ? 'Video' : 'Image');
    await chatRef.update({
      'lastMessage': lastMessageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    
    // Send notification if sender is admin
    if (senderType == 'admin') {
      try {
        // Extract userId from chatId (format: chat_userId)
        final userId = chatId.replaceFirst('chat_', '');
        await NotificationService.notifyNewAdminMessage(userId: userId);
        AppLogger.info('Chat notification sent to user: $userId');
      } catch (e) {
        AppLogger.error('Failed to send chat notification: $e', e);
      }
    }
    
    AppLogger.debug('Message sent to chatId: $chatId');
  }

  // Get admin user information from the admin collection
  Future<Map<String, dynamic>?> getAdminInfo(String adminId) async {
    try {
      AppLogger.debug('Fetching admin info for adminId: $adminId');
      
      // Try fetching from admin collection first
      // Admin structure: { email, profile: { firstName, lastName } }
      final adminDoc = await firestore.collection('admin').doc(adminId).get();
      if (adminDoc.exists) {
        final data = adminDoc.data();
        final profile = data?['profile'] as Map<String, dynamic>? ?? {};
        final adminInfo = {
          'name': '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim(),
          'email': data?['email'] ?? '',
          'role': 'admin',
        };
        AppLogger.debug('Admin info found: ${adminInfo['name']}');
        return adminInfo;
      }

      AppLogger.warning('Admin not found with id: $adminId');
      return null;
    } catch (e) {
      AppLogger.error('Error fetching admin info: $e');
      return null;
    }
  }

  // Get user information (for displaying in chat)
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      AppLogger.debug('Fetching user info for userId: $userId');
      
      final doc = await firestore.collection('Users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        final profile = data?['profile'] as Map<String, dynamic>? ?? {};
        final property = data?['property'] as Map<String, dynamic>? ?? {};
        final userInfo = {
          'name': '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim(),
          'email': profile['email'] ?? '',
          'phoneNumber': profile['phoneNumber'] ?? '',
          'profilePicture': profile['profilePicture'] ?? '',
          'unitId': property['unitId'] ?? '',
          'propertyName': property['propertyName'] ?? '',
          'moveInDate': property['moveInDate'],
          'role': 'user',
        };
        AppLogger.debug('User info found: ${userInfo['name']}');
        return userInfo;
      }
      
      AppLogger.warning('User not found with id: $userId');
      return null;
    } catch (e) {
      AppLogger.error('Error fetching user info: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      AppLogger.debug('Uploading image for chat with user: $userId');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_${userId}_$timestamp.jpg';
      final ref = storage.ref().child('chats').child(userId).child(fileName);
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      AppLogger.debug('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Error uploading image: $e');
      rethrow;
    }
  }

  // Upload video to Firebase Storage
  Future<String> uploadVideo(File videoFile, String userId) async {
    try {
      AppLogger.debug('Uploading video for chat with user: $userId');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_${userId}_$timestamp.mp4';
      final ref = storage.ref().child('chats').child(userId).child(fileName);
      
      final uploadTask = await ref.putFile(videoFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      AppLogger.debug('Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Error uploading video: $e');
      rethrow;
    }
  }
}
