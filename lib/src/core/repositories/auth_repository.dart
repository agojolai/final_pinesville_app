import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import '../exceptions/firebase_auth_exceptions.dart' as custom_auth;
import '../exceptions/firebase_exceptions.dart' as custom_firebase;
import '../exceptions/format_exceptions.dart' as custom_format;
import '../exceptions/platform_exceptions.dart' as custom_platform;
import '../../features/auth/data/models/user_model.dart';
import '../utils/app_logger.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.instance;
});

class AuthRepository {
  static AuthRepository? _instance;
  static AuthRepository get instance => _instance ??= AuthRepository._();
  
  AuthRepository._();

  //variables
  final deviceStorage = GetStorage();
  firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;
  FirebaseFirestore get firebaseStore => FirebaseFirestore.instance;

  //get authenticated user data
  firebase_auth.User? get authUser => _auth.currentUser;

  // Initialize method to replace onReady
  void initialize() {
    try {
      // Test Firebase Auth access
      final auth = _auth;
      AppLogger.info('AuthRepository: Firebase Auth initialized successfully');
      AppLogger.debug('AuthRepository: Current user: ${auth.currentUser?.email ?? 'No user'}');
    } catch (e) {
      AppLogger.error('AuthRepository: Error accessing Firebase Auth', e);
    }
    
  }

  /*-----------------------APPROVE PENDING USER------------------------*/
  /// Changes a user's account status from pending to active
  Future<void> approvePendingUser(String email) async {
    try {
      // Validate email format first to avoid unnecessary Firebase calls
      if (email.isEmpty || !email.contains('@')) {
        throw 'Invalid email address provided.';
      }

      // Find the user in the Users collection by email
      final userSnapshot = await firebaseStore
          .collection('Users')
          .where('profile.email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw 'User not found with the provided email address.';
      }

      final userDoc = userSnapshot.docs.first;
      final userData = userDoc.data();
      final currentStatus = userData['account']?['status'];

      // Check current status
      if (currentStatus != 'pending') {
        throw 'User account is not in pending status. Current status: $currentStatus';
      }

      // Update the user's account status to active with timestamp
      await firebaseStore.collection('Users').doc(userDoc.id).update({
        'account.status': 'active',
        'account.approvedAt': DateTime.now().toIso8601String(),
        'account.updatedAt': DateTime.now().toIso8601String(),
      });
      
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on custom_platform.PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      if (e.toString().contains('User not found') ||
          e.toString().contains('not in pending status') ||
          e.toString().contains('Invalid email')) {
        rethrow; // Re-throw our custom messages
      }
      throw 'Failed to approve user. Please try again.';
    }
  }


  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await firebaseStore
          .collection('Users')
          .get();

      return snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      throw 'Failed to fetch all users. Please try again.';
    }
  }

//TODO: USE A PUSH APP NOTIFIACTION IN REJECTION OR APPROVAL
//TODO: find a way to use the fromsnapshot method in the user model
  /*-----------------------GET PENDING USERS------------------------*/
  /// Retrieves all users with pending status for administrative approval
  Future<List<UserModel>> getPendingUsers() async {
    try {
      final snapshot = await firebaseStore
          .collection('Users')
          .where('account.status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      throw 'Failed to fetch pending users. Please try again.';
    }
  }





  /*-----------------------REJECT/SUSPEND USER------------------------*/
  /// Changes a user's account status to suspended or terminated
  Future<void> updateUserStatus(String email, String newStatus, {String? reason}) async {
    try {
      // Validate inputs
      if (email.isEmpty || !email.contains('@')) {
        throw 'Invalid email address provided.';
      }
      
      if (!['suspended', 'terminated', 'active', 'rejected'].contains(newStatus)) {
        throw 'Invalid status. Must be one of: suspended, terminated, active, rejected';
      }

      // Find the user in the Users collection by email
      final userSnapshot = await firebaseStore
          .collection('Users')
          .where('profile.email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw 'User not found with the provided email address.';
      }

      final userDoc = userSnapshot.docs.first;
      final updateData = {
        'account.status': newStatus,
        'account.updatedAt': DateTime.now().toIso8601String(),
      };

      // Add reason if provided
      if (reason != null && reason.isNotEmpty) {
        updateData['account.statusReason'] = reason;
      }

      // Add specific timestamp based on status
      if (newStatus == 'suspended') {
        updateData['account.suspendedAt'] = DateTime.now().toIso8601String();
      } else if (newStatus == 'terminated') {
        updateData['account.terminatedAt'] = DateTime.now().toIso8601String();
      } else if (newStatus == 'active') {
        updateData['account.approvedAt'] = DateTime.now().toIso8601String();
      } else if (newStatus == 'rejected') {
        updateData['account.rejectedAt'] = DateTime.now().toIso8601String();
      }

      // Update the user's account status
      await firebaseStore.collection('Users').doc(userDoc.id).update(updateData);
      
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on custom_platform.PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      if (e.toString().contains('User not found') ||
          e.toString().contains('Invalid status') ||
          e.toString().contains('Invalid email')) {
        rethrow; // Re-throw our custom messages
      }
      throw 'Failed to update user status. Please try again.';
    }
  }


/*-----------------------Email and Password Sign In------------------------*/

//Email auth LogIN with user status validation
  Future<firebase_auth.UserCredential> logInWithEmailAndPassword(
      String email, String password) async {
    try {
      AppLogger.debug('🔐 LOGIN ATTEMPT: $email');
      
      // First authenticate with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      AppLogger.debug('✅ Firebase Auth successful for: ${userCredential.user!.uid}');
      
      // Check user status in Firestore
      final userDoc = await firebaseStore
          .collection('Users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (!userDoc.exists) {
        AppLogger.error('❌ LOGIN FAILED: User not found in Firestore');
        // User doesn't exist in Users collection - sign out and throw error
        await _auth.signOut();
        throw 'Invalid email or password. Please check your credentials.';
      }
      
      // Get user data
      final userData = userDoc.data()!;
      final userStatus = userData['account']?['status'] ?? 'pending';
      final userRole = userData['profile']?['role'] ?? 'tenant';
      
      AppLogger.debug('📋 User found in Firestore:');
      AppLogger.debug('   ├─ Status: $userStatus');
      AppLogger.debug('   └─ Role: $userRole');
      
      if (userStatus == 'pending') {
        AppLogger.debug('⏳ LOGIN BLOCKED: Account pending approval');
        // User account is still pending approval - sign out and throw specific error
        await _auth.signOut();
        throw 'Your application is still pending approval. Please wait for administrator confirmation.';
      }
      
      if (userStatus == 'suspended' || userStatus == 'terminated') {
        AppLogger.debug('🚫 LOGIN BLOCKED: Account $userStatus');
        // User account is suspended or terminated - sign out and throw error
        await _auth.signOut();
        throw 'Your account has been ${userStatus}. Please contact support for assistance.';
      }
      
      AppLogger.debug('✅ LOGIN SUCCESSFUL: User authenticated and authorized');
      AppLogger.debug('   └─ Auth state change will trigger provider updates');
      
      // User is active - return the credentials
      return userCredential;
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Invalid email or password. Please check your credentials.';
      }
      throw custom_auth.FirebaseAuthException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on custom_platform.PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      if (e.toString().contains('pending approval') || 
          e.toString().contains('suspended') || 
          e.toString().contains('terminated') ||
          e.toString().contains('Invalid email or password')) {
        rethrow; // Re-throw our custom messages
      }
      throw 'Something went wrong. Please try again';
    }
  }

  /// Admin login with Firebase Auth and admin collection verification
  Future<firebase_auth.UserCredential> logInAsAdmin(
      String email, String password) async {
    try {
      AppLogger.debug('🔐 ADMIN LOGIN ATTEMPT: $email');
      
      // First authenticate with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      final userId = userCredential.user!.uid;
      AppLogger.debug('✅ Firebase Auth successful');
      AppLogger.debug('   ├─ User ID: $userId');
      AppLogger.debug('   └─ Email: ${userCredential.user!.email}');
      
      // Check if user exists in admin collection
      AppLogger.debug('🔍 Querying admin collection...');
      AppLogger.debug('   ├─ Collection: admin');
      AppLogger.debug('   ├─ Query field: userId');
      AppLogger.debug('   └─ Looking for: $userId');
      
      final adminQuery = await firebaseStore
          .collection('admin')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      AppLogger.debug('📊 Query results:');
      AppLogger.debug('   ├─ Documents found: ${adminQuery.docs.length}');
      AppLogger.debug('   └─ Query completed successfully: ${!adminQuery.metadata.isFromCache}');
      
      if (adminQuery.docs.isEmpty) {
        // Let's check if there are ANY documents in admin collection
        AppLogger.debug('🔍 Checking all documents in admin collection...');
        final allAdmins = await firebaseStore.collection('admin').get();
        AppLogger.debug('   └─ Total admin documents: ${allAdmins.docs.length}');
        
        if (allAdmins.docs.isNotEmpty) {
          AppLogger.debug('📋 Existing admin documents:');
          for (var doc in allAdmins.docs) {
            final data = doc.data();
            AppLogger.debug('   ├─ Doc ID: ${doc.id}');
            AppLogger.debug('   │  ├─ Email: ${data['email']}');
            AppLogger.debug('   │  ├─ Has userId field: ${data.containsKey('userId')}');
            AppLogger.debug('   │  └─ userId value: ${data['userId'] ?? 'NULL'}');
          }
        }
        
        AppLogger.error('❌ ADMIN LOGIN FAILED: User not found in admin collection');
        AppLogger.error('   ├─ Firebase Auth UID: $userId');
        AppLogger.error('   └─ No matching userId in admin collection');
        // User is not an admin - sign out and throw error
        await _auth.signOut();
        throw 'Invalid admin credentials. This account is not authorized for admin access.';
      }
      
      // Get admin data
      final adminDoc = adminQuery.docs.first;
      final adminData = adminDoc.data();
      final adminEmail = adminData['email'] as String?;
      
      AppLogger.debug('📋 Admin found in admin collection:');
      AppLogger.debug('   ├─ Email: $adminEmail');
      AppLogger.debug('   ├─ Admin ID: ${adminDoc.id}');
      AppLogger.debug('   └─ User ID: ${userCredential.user!.uid}');
      
      AppLogger.debug('✅ ADMIN LOGIN SUCCESSFUL: User authenticated and authorized');
      
      // Return the credentials
      return userCredential;
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Invalid admin credentials. Please check your email and password.';
      }
      throw custom_auth.FirebaseAuthException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on custom_platform.PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      if (e.toString().contains('Invalid admin credentials') || 
          e.toString().contains('not authorized')) {
        rethrow; // Re-throw our custom messages
      }
      throw 'Something went wrong. Please try again';
    }
  }

//put email in firebase auth
  Future<firebase_auth.UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw custom_auth.FirebaseAuthException(e.code).message;

    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();

    } on custom_platform.PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;

    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

// Forget Password
  Future<void> forgetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw custom_auth.FirebaseAuthException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on custom_platform.PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

//log out
  Future<void> logout() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        AppLogger.debug('🚪 LOGOUT: Logging out user');
        AppLogger.debug('   ├─ UID: ${currentUser.uid}');
        AppLogger.debug('   └─ Email: ${currentUser.email}');
      }
      
      await _auth.signOut();
      
      AppLogger.debug('✅ LOGOUT: User successfully logged out');
      AppLogger.debug('   └─ Auth state will now trigger provider updates');
      
      // Note: Riverpod provider invalidation should be handled at the app level
      // by listening to auth state changes in main.dart or app.dart
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('❌ LOGOUT ERROR: ${e.message}');
      throw custom_auth.FirebaseAuthException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on custom_platform.PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      AppLogger.error('❌ LOGOUT ERROR: $e');
      throw 'Something went wrong. Please try again';
    }
  }
}
