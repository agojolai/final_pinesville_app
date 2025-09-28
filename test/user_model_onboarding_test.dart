import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/src/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel with Onboarding Status', () {
    late UserModel testUser;
    
    setUp(() {
      testUser = UserModel(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+1234567890',
        profilePicture: 'profile.jpg',
        propertyName: 'Test Property',
        propertyId: 'prop-123',
        unitId: 'unit-456',
        unitType: 'apartment',
        moveInDate: DateTime(2023, 1, 1),
        leaseEndDate: DateTime(2024, 1, 1),
        rentAmount: 1500.0,
        status: 'active',
        createdAt: DateTime(2023, 1, 1),
        onboardingCompleted: false,
      );
    });

    test('should create UserModel with onboarding status', () {
      expect(testUser.onboardingCompleted, false);
      expect(testUser.id, 'test-id');
      expect(testUser.email, 'john.doe@example.com');
    });

    test('should create empty UserModel with default onboarding status', () {
      final emptyUser = UserModel.empty();
      expect(emptyUser.onboardingCompleted, false);
      expect(emptyUser.firstName, '');
      expect(emptyUser.status, 'pending');
    });

    test('should serialize to JSON with onboarding status', () {
      final json = testUser.toJson();
      
      expect(json['account']['onboardingCompleted'], false);
      expect(json['profile']['firstName'], 'John');
      expect(json['profile']['email'], 'john.doe@example.com');
      expect(json['property']['unitId'], 'unit-456');
      expect(json['account']['status'], 'active');
    });

    test('should deserialize from Firestore document with onboarding status', () {
      // Mock Firestore document data
      final Map<String, dynamic> firestoreData = {
        'profile': {
          'firstName': 'Jane',
          'lastName': 'Smith',
          'email': 'jane.smith@example.com',
          'phoneNumber': '+0987654321',
          'profilePicture': 'jane.jpg',
        },
        'property': {
          'propertyName': 'Jane Property',
          'propertyId': 'prop-456',
          'unitId': 'unit-789',
          'unitType': 'condo',
          'moveInDate': '2023-06-01T00:00:00.000Z',
          'leaseEndDate': '2024-06-01T00:00:00.000Z',
          'rentAmount': 2000.0,
        },
        'account': {
          'status': 'pending',
          'createdAt': '2023-06-01T00:00:00.000Z',
          'onboardingCompleted': true,
        }
      };

      // Create a mock DocumentSnapshot
      final mockDoc = MockDocumentSnapshot();
      when(() => mockDoc.id).thenReturn('doc-123');
      when(() => mockDoc.data()).thenReturn(firestoreData);

      final user = UserModel.fromSnapshot(mockDoc);

      expect(user.id, 'doc-123');
      expect(user.firstName, 'Jane');
      expect(user.lastName, 'Smith');
      expect(user.email, 'jane.smith@example.com');
      expect(user.onboardingCompleted, true);
      expect(user.status, 'pending');
    });

    test('should handle missing onboarding status in Firestore data', () {
      // Mock Firestore document without onboarding status
      final Map<String, dynamic> firestoreData = {
        'profile': {
          'firstName': 'Bob',
          'lastName': 'Johnson',
          'email': 'bob@example.com',
          'phoneNumber': '+1111111111',
          'profilePicture': '',
        },
        'property': {
          'propertyName': 'Bob Property',
          'propertyId': '',
          'unitId': 'unit-111',
          'unitType': '',
          'moveInDate': null,
          'leaseEndDate': null,
          'rentAmount': 0,
        },
        'account': {
          'status': 'active',
          'createdAt': '2023-01-01T00:00:00.000Z',
          // onboardingCompleted is missing
        }
      };

      final mockDoc = MockDocumentSnapshot();
      when(() => mockDoc.id).thenReturn('doc-456');
      when(() => mockDoc.data()).thenReturn(firestoreData);

      final user = UserModel.fromSnapshot(mockDoc);

      // Should default to false when onboardingCompleted is missing
      expect(user.onboardingCompleted, false);
      expect(user.firstName, 'Bob');
    });

    test('should create copy with updated onboarding status', () {
      final updatedUser = testUser.copyWith(onboardingCompleted: true);
      
      expect(updatedUser.onboardingCompleted, true);
      expect(updatedUser.firstName, testUser.firstName);
      expect(updatedUser.email, testUser.email);
      expect(updatedUser.id, testUser.id);
    });

    test('should create copy with multiple updated fields including onboarding', () {
      final updatedUser = testUser.copyWith(
        firstName: 'Updated John',
        onboardingCompleted: true,
        status: 'verified',
      );
      
      expect(updatedUser.firstName, 'Updated John');
      expect(updatedUser.onboardingCompleted, true);
      expect(updatedUser.status, 'verified');
      expect(updatedUser.lastName, testUser.lastName); // Unchanged
      expect(updatedUser.email, testUser.email); // Unchanged
    });

    test('should implement equality correctly with onboarding status', () {
      final sameUser = UserModel(
        id: testUser.id,
        firstName: testUser.firstName,
        lastName: testUser.lastName,
        email: testUser.email,
        phoneNumber: testUser.phoneNumber,
        profilePicture: testUser.profilePicture,
        propertyName: testUser.propertyName,
        propertyId: testUser.propertyId,
        unitId: testUser.unitId,
        unitType: testUser.unitType,
        moveInDate: testUser.moveInDate,
        leaseEndDate: testUser.leaseEndDate,
        rentAmount: testUser.rentAmount,
        status: testUser.status,
        createdAt: testUser.createdAt,
        onboardingCompleted: testUser.onboardingCompleted,
      );

      final differentUser = testUser.copyWith(onboardingCompleted: true);

      expect(testUser == sameUser, true);
      expect(testUser == differentUser, false);
      expect(testUser.hashCode == sameUser.hashCode, true);
      expect(testUser.hashCode == differentUser.hashCode, false);
    });

    test('should include onboarding status in toString', () {
      final stringRepresentation = testUser.toString();
      
      expect(stringRepresentation.contains('onboardingCompleted: false'), true);
      expect(stringRepresentation.contains('John'), true);
      expect(stringRepresentation.contains('john.doe@example.com'), true);
    });
  });
}

// Mock class for DocumentSnapshot since we can't easily create real instances in tests
class MockDocumentSnapshot {
  String? _id;
  Map<String, dynamic>? _data;

  String get id => _id ?? '';
  Map<String, dynamic>? data() => _data;

  MockDocumentSnapshot();
}

// Extension to add when functionality for simple mocking
extension MockDocumentSnapshotExtension on MockDocumentSnapshot {
  void when<T>(T Function() fn) {
    // Simple implementation for our test needs
    final result = fn();
    if (fn.toString().contains('id')) {
      _id = result as String;
    } else if (fn.toString().contains('data')) {
      _data = result as Map<String, dynamic>?;
    }
  }
}

void when<T>(T Function() fn) => fn();