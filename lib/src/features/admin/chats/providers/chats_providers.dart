import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/chats_repository.dart';

// Re-export repository provider for convenience
export '../data/chats_repository.dart' show chatsRepositoryProvider;

// Stream provider for properties list
final propertiesStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance.collection('Property').snapshots();
});

// Stream provider for users list (regular users only)
final usersStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  final repo = ref.watch(chatsRepositoryProvider);
  return repo.getUsersStream();
});

// Stream provider for admins list
final adminsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  final repo = ref.watch(chatsRepositoryProvider);
  return repo.getAdminsStream();
});

// Stream provider for chat messages (family for dynamic chatId)
final messagesStreamProvider =
    StreamProvider.family<QuerySnapshot, String>((ref, chatId) {
  final repo = ref.watch(chatsRepositoryProvider);
  return repo.getMessagesStream(chatId);
});

// Future provider for admin info (family for dynamic adminId)
final adminInfoProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, adminId) async {
  final repo = ref.watch(chatsRepositoryProvider);
  return await repo.getAdminInfo(adminId);
});

// Future provider for user info (family for dynamic userId)
final userInfoProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final repo = ref.watch(chatsRepositoryProvider);
  return await repo.getUserInfo(userId);
});
