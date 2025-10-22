import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/admin_model.dart';
import '../../../core/utils/app_logger.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Provider for current admin's profile (real-time updates)
final currentAdminProvider = StreamProvider<AdminModel?>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  final userId = repository.auth.currentUser?.uid;
  
  if (userId == null) {
    AppLogger.debug('currentAdminProvider: No authenticated user');
    return Stream.value(null);
  }
  
  AppLogger.debug('currentAdminProvider: Watching admin profile for userId: $userId');
  return repository.getCurrentAdminStream(userId);
});

class AdminRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  AdminRepository({
    required this.firestore,
    required this.auth,
  });

  /// Get current admin as a stream (real-time updates)
  Stream<AdminModel?> getCurrentAdminStream(String userId) {
    return firestore
        .collection('admin')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            AppLogger.warning('No admin found for userId: $userId');
            return null;
          }
          return AdminModel.fromSnapshot(snapshot.docs.first);
        });
  }

  /// Get current admin as a one-time fetch
  Future<AdminModel?> getCurrentAdmin(String userId) async {
    try {
      final snapshot = await firestore
          .collection('admin')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        AppLogger.warning('No admin found for userId: $userId');
        return null;
      }
      
      return AdminModel.fromSnapshot(snapshot.docs.first);
    } catch (e) {
      AppLogger.error('Error fetching admin profile', e);
      return null;
    }
  }

  /// Update admin profile
  Future<void> updateAdminProfile({
    required String adminId,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (firstName != null) {
        updates['profile.firstName'] = firstName;
      }
      if (lastName != null) {
        updates['profile.lastName'] = lastName;
      }
      
      await firestore.collection('admin').doc(adminId).update(updates);
      AppLogger.info('Admin profile updated successfully');
    } catch (e) {
      AppLogger.error('Error updating admin profile', e);
      rethrow;
    }
  }
}
