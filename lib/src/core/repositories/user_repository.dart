import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/data/models/occupant_model.dart';
import '../exceptions/firebase_exceptions.dart' as custom_firebase;
import '../exceptions/format_exceptions.dart' as custom_format;
import '../exceptions/platform_exceptions.dart' as custom_platform;
import 'auth_repository.dart';

class UserRepository {
  static UserRepository? _instance;
  static UserRepository get instance => _instance ??= UserRepository._();
  
  UserRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;


  // Function to save user data to firestore
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _db.collection('Users')
          .doc(user.id)
          .set(user.toJson());
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error saving user record: $e');
    }
  }

  // Function to fetch user details based on user ID
  Future<UserModel> fetchUserDetails() async {
    try {
      final documentSnapshot = await _db
          .collection('Users')
          .doc(AuthRepository.instance.authUser?.uid)
          .get();
      if (documentSnapshot.exists) {
        return UserModel.fromSnapshot(documentSnapshot);
      } else {
        return UserModel.empty();
      }
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching user details: $e');
    }
  }

  // Function to fetch user details by specific user ID
  Future<UserModel> fetchUserDetailsById(String userId) async {
    try {
      final documentSnapshot = await _db
          .collection('Users')
          .doc(userId)
          .get();
      if (documentSnapshot.exists) {
        return UserModel.fromSnapshot(documentSnapshot);
      } else {
        return UserModel.empty();
      }
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching user details: $e');
    }
  }

  // Function to update user data in firestore
  Future<void> updateUserDetails(UserModel updatedUser) async {
    try {
      await _db
          .collection('Users')
          .doc(updatedUser.id)
          .update(updatedUser.toJson());
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error updating user details: $e');
    }
  }

  // Update any field in specific users collection
  Future<void> updateSingleField(Map<String, dynamic> json) async {
    try {
      await _db
          .collection('Users')
          .doc(AuthRepository.instance.authUser?.uid)
          .update(json);
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error updating user field: $e');
    }
  }

  // Function to remove user data from firestore
  Future<void> removeUserRecord(String userId) async {
    try {
      await _db
          .collection('Users')
          .doc(userId)
          .delete();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error removing user record: $e');
    }
  }

  // Function to upload photos
  Future<String> uploadImage(String path, XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref(path).child(image.name);
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Function to check if user exists and get their status
  Future<String?> checkUserStatus(String email) async {
    try {
      // Check in Users collection first (approved users)
      final usersQuery = await _db
          .collection('Users')
          .where('profile.email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (usersQuery.docs.isNotEmpty) {
        final userData = usersQuery.docs.first.data();
        final account = userData['account'] ?? {};
        return account['status'] ?? 'active'; // Default to active if no status field
      }
      
      // If not in Users, check pendingTenants collection (legacy support)
      final pendingQuery = await _db
          .collection('pendingTenants')
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();
          
      if (pendingQuery.docs.isNotEmpty) {
        return 'pending';
      }
      
      // User not found in either collection
      return null;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error checking user status: $e');
    }
  }

  // Helper method to create UserModel from registration data
  // OPTIMIZED: Now accepts propertyId directly to avoid redundant query
  Future<UserModel> createUserFromRegistration({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String propertyName,
    required String propertyId, // NEW: Pass propertyId directly
    required String phoneNumber,
    required String unitNumber,
    required DateTime moveInDate,
    UserRole role = UserRole.tenant,
    String profilePicture = '',
  }) async {
    String unitType = '';
    double rentAmount = 0.0;

    try {
      // Only fetch unit details (property already known)
      if (propertyId.isNotEmpty) {
        final unitSnapshot = await _db
            .collection('Property')
            .doc(propertyId)
            .collection('Units')
            .where('unitNumber', isEqualTo: unitNumber)
            .limit(1)
            .get();

        if (unitSnapshot.docs.isNotEmpty) {
          final unitData = unitSnapshot.docs.first.data();
          final details = unitData['Details'] ?? {};
          unitType = details['unitType'] ?? '';
          rentAmount = (details['monthlyRent'] ?? 0).toDouble();
        }
      }
    } catch (e) {
      // Log error but continue with empty values
      print('Error fetching unit details: $e');
    }

    return UserModel(
      id: uid,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      profilePicture: profilePicture,
      propertyName: propertyName,
      propertyId: propertyId,
      unitId: unitNumber,
      unitType: unitType,
      moveInDate: moveInDate,
      leaseEndDate: null,
      rentAmount: rentAmount,
      status: "pending",
      role: role,
      createdAt: DateTime.now(),
    );
  }

  // Update specific user profile fields (not overwrite everything)
  Future<void> updateUserProfileField(Map<String, dynamic> fields) async {
    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Construct the nested field updates for the profile structure
      Map<String, dynamic> updateData = {};
      
      fields.forEach((key, value) {
        switch (key) {
          case 'firstName':
            updateData['profile.firstName'] = value;
            break;
          case 'lastName':
            updateData['profile.lastName'] = value;
            break;
          case 'phoneNumber':
            updateData['profile.phoneNumber'] = value;
            break;
          case 'profilePicture':
            updateData['profile.profilePicture'] = value;
            break;
          case 'email':
            updateData['profile.email'] = value;
            break;
          default:
            // For any other fields, assume they're direct profile fields
            updateData['profile.$key'] = value;
        }
      });

      await _db
          .collection('Users')
          .doc(userId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error updating user profile field: $e');
    }
  }

  // Update profile picture specifically
  Future<void> updateProfilePicture(String imageUrl) async {
    await updateUserProfileField({'profilePicture': imageUrl});
  }

  // OCCUPANTS SUBCOLLECTION METHODS

  // Add a new occupant to the user's subcollection
  Future<void> addOccupant(OccupantModel occupant) async {
    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _db
          .collection('Users')
          .doc(userId)
          .collection('occupants')
          .add(occupant.toJson());
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error adding occupant: $e');
    }
  }

  // Update an existing occupant
  Future<void> updateOccupant(String occupantId, OccupantModel occupant) async {
    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _db
          .collection('Users')
          .doc(userId)
          .collection('occupants')
          .doc(occupantId)
          .update(occupant.toJson());
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error updating occupant: $e');
    }
  }

  // Delete an occupant
  Future<void> deleteOccupant(String occupantId) async {
    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _db
          .collection('Users')
          .doc(userId)
          .collection('occupants')
          .doc(occupantId)
          .delete();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error deleting occupant: $e');
    }
  }

  // Fetch all occupants for the current user
  Future<List<OccupantModel>> fetchOccupants() async {
    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _db
          .collection('Users')
          .doc(userId)
          .collection('occupants')
          .get();

      return querySnapshot.docs
          .map((doc) => OccupantModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching occupants: $e');
    }
  }

  // Stream occupants for real-time updates
  Stream<List<OccupantModel>> streamOccupants() {
    final userId = AuthRepository.instance.authUser?.uid;
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    return _db
        .collection('Users')
        .doc(userId)
        .collection('occupants')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OccupantModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}

