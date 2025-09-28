import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import '../../auth/data/models/user_model.dart';
import '../../../core/repositories/user_repository.dart';

/// Repository to handle onboarding completion status with Firestore integration
class OnboardingRepository {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  
  final GetStorage _storage = GetStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository.instance;
  
  /// Check if user has completed onboarding
  /// First checks Firestore (if authenticated), falls back to local storage
  bool get isOnboardingCompleted {
    // For unauthenticated users, use local storage
    if (_auth.currentUser == null) {
      return _storage.read(_onboardingCompletedKey) ?? false;
    }
    
    // For authenticated users, we'll need to use async method
    // This getter maintains backward compatibility for sync access
    return _storage.read(_onboardingCompletedKey) ?? false;
  }
  
  /// Check if user has completed onboarding (async version with Firestore)
  Future<bool> getOnboardingStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // Unauthenticated user - use local storage only
        return _storage.read(_onboardingCompletedKey) ?? false;
      }
      
      // Try to get from Firestore first
      final userDoc = await _firestore
          .collection('Users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final account = userData['account'] as Map<String, dynamic>? ?? {};
          final firestoreStatus = account['onboardingCompleted'] as bool? ?? false;
          
          // Sync local storage with Firestore
          await _storage.write(_onboardingCompletedKey, firestoreStatus);
          
          return firestoreStatus;
        }
      }
      
      // Fallback to local storage
      return _storage.read(_onboardingCompletedKey) ?? false;
    } catch (e) {
      print('Error getting onboarding status from Firestore: $e');
      // Fallback to local storage on error
      return _storage.read(_onboardingCompletedKey) ?? false;
    }
  }
  
  /// Mark onboarding as completed
  /// Updates both local storage and Firestore (if authenticated)
  Future<void> markOnboardingCompleted() async {
    try {
      // Always update local storage
      await _storage.write(_onboardingCompletedKey, true);
      
      // Update Firestore if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        await _updateFirestoreOnboardingStatus(user.uid, true);
      }
    } catch (e) {
      print('Error marking onboarding as completed: $e');
      // Even if Firestore fails, local storage is updated
      throw Exception('Failed to mark onboarding as completed: $e');
    }
  }
  
  /// Reset onboarding status (useful for testing)
  /// Updates both local storage and Firestore (if authenticated)
  Future<void> resetOnboarding() async {
    try {
      // Always update local storage
      await _storage.remove(_onboardingCompletedKey);
      
      // Update Firestore if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        await _updateFirestoreOnboardingStatus(user.uid, false);
      }
    } catch (e) {
      print('Error resetting onboarding: $e');
      // Even if Firestore fails, local storage is updated
      throw Exception('Failed to reset onboarding: $e');
    }
  }
  
  /// Sync onboarding status from Firestore to local storage
  /// Useful when user logs in to sync their cloud status
  Future<void> syncFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final userDoc = await _firestore
          .collection('Users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final account = userData['account'] as Map<String, dynamic>? ?? {};
          final firestoreStatus = account['onboardingCompleted'] as bool? ?? false;
          
          // Update local storage to match Firestore
          await _storage.write(_onboardingCompletedKey, firestoreStatus);
        }
      }
    } catch (e) {
      print('Error syncing onboarding status from Firestore: $e');
    }
  }
  
  /// Update onboarding status in Firestore
  Future<void> _updateFirestoreOnboardingStatus(String userId, bool completed) async {
    try {
      await _firestore
          .collection('Users')
          .doc(userId)
          .update({
        'account.onboardingCompleted': completed,
      });
    } catch (e) {
      print('Error updating onboarding status in Firestore: $e');
      throw e;
    }
  }
  
  /// ADMIN UTILITIES
  
  /// Get all users with their onboarding status (Admin only)
  /// This provides a complete view for admin testing
  Stream<List<Map<String, dynamic>>> getAllUsersOnboardingStatus() {
    return _firestore
        .collection('Users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final profile = data['profile'] as Map<String, dynamic>? ?? {};
              final account = data['account'] as Map<String, dynamic>? ?? {};
              
              return {
                'userId': doc.id,
                'email': profile['email'] ?? 'Unknown',
                'fullName': '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim(),
                'onboardingCompleted': account['onboardingCompleted'] ?? false,
                'status': account['status'] ?? 'pending',
                'createdAt': account['createdAt'],
              };
            }).toList());
  }
  
  /// Reset onboarding for a specific user (Admin only)
  Future<void> adminResetOnboardingForUser(String userId) async {
    try {
      await _firestore
          .collection('Users')
          .doc(userId)
          .update({
        'account.onboardingCompleted': false,
      });
    } catch (e) {
      print('Error resetting onboarding for user $userId: $e');
      throw Exception('Failed to reset onboarding for user: $e');
    }
  }
  
  /// Mark onboarding as completed for a specific user (Admin only)
  Future<void> adminMarkOnboardingCompletedForUser(String userId) async {
    try {
      await _firestore
          .collection('Users')
          .doc(userId)
          .update({
        'account.onboardingCompleted': true,
      });
    } catch (e) {
      print('Error marking onboarding completed for user $userId: $e');
      throw Exception('Failed to mark onboarding completed for user: $e');
    }
  }
  
  /// Get onboarding statistics for admin dashboard
  Future<Map<String, int>> getOnboardingStatistics() async {
    try {
      final querySnapshot = await _firestore.collection('Users').get();
      
      int totalUsers = 0;
      int completedOnboarding = 0;
      int pendingOnboarding = 0;
      
      for (final doc in querySnapshot.docs) {
        totalUsers++;
        final data = doc.data();
        final account = data['account'] as Map<String, dynamic>? ?? {};
        final onboardingCompleted = account['onboardingCompleted'] as bool? ?? false;
        
        if (onboardingCompleted) {
          completedOnboarding++;
        } else {
          pendingOnboarding++;
        }
      }
      
      return {
        'totalUsers': totalUsers,
        'completedOnboarding': completedOnboarding,
        'pendingOnboarding': pendingOnboarding,
      };
    } catch (e) {
      print('Error getting onboarding statistics: $e');
      return {
        'totalUsers': 0,
        'completedOnboarding': 0,
        'pendingOnboarding': 0,
      };
    }
  }
}