import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get_storage/get_storage.dart';
import '../../../core/exceptions/firebase_auth_exceptions.dart' as custom_auth;
import '../../../core/exceptions/firebase_exceptions.dart' as custom_firebase;
import '../../../core/exceptions/format_exceptions.dart' as custom_format;
import '../../../core/exceptions/platform_exceptions.dart' as custom_platform;

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
      print('AuthRepository: Firebase Auth initialized successfully');
      print('AuthRepository: Current user: ${auth.currentUser?.email ?? 'No user'}');
    } catch (e) {
      print('AuthRepository: Error accessing Firebase Auth: $e');
    }
    
  }


  /*-----------------------DUMMY APPROVE TENANT------------------------*/
  Future<void> approvePendingUser(String email) async {
    try {
      // 1. Find the user in the pendingTenants collection
      final pendingSnapshot = await firebaseStore
          .collection('pendingTenants')
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();

      if (pendingSnapshot.docs.isEmpty) {
        print("❌ User not found in pending tenants.");
        return;
      }

      final pendingDoc = pendingSnapshot.docs.first;
      final userData = pendingDoc.data();

      // 2. Extract the UID from the document ID (assuming it's the UID)
      final uid = pendingDoc.id;

      // 3. Copy the data to the Users collection using UID as doc ID
      await firebaseStore.collection('Users').doc(uid).set({
        ...userData
       // 'id': uid, // Ensure 'id' field exists in user model
      });

      // 4. Delete from pendingTenants
      await firebaseStore.collection('pendingTenants').doc(uid).delete();

      // 5. Simulate sending a confirmation email
      print('✅ User approved and moved to Users collection.');
      print('📧 Simulated email sent to: $email');
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on custom_platform.PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code.toString()).message;
    } catch (e) {
      print("Error approving user: $e");
    }
  }


/*-----------------------Email and Password Sign In------------------------*/

//Email auth LogIN
  Future<firebase_auth.UserCredential> logInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
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

//Email auth SignUp
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
      await _auth.signOut();
      // TODO: Navigate to LoginScreen using Navigator instead of Get
      // Navigator.of(context).pushAndRemoveUntil(
      //   MaterialPageRoute(builder: (context) => const LoginScreen()),
      //   (route) => false,
      // );
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
}
