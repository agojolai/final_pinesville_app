import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/tenant_chat_repository.dart';

export '../data/tenant_chat_repository.dart' show tenantChatRepositoryProvider;

/// Provider that watches auth state and updates when user changes
final tenantMessagesStreamProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  // Watch the current user - this will invalidate the provider when auth state changes
  final currentUser = FirebaseAuth.instance.currentUser;
  
  // If no user, return empty stream
  if (currentUser == null) {
    return const Stream.empty();
  }
  
  final repo = ref.watch(tenantChatRepositoryProvider);
  return repo.getMessagesStream();
});
