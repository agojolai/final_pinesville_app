import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/auth/data/models/user_model.dart';
import 'package:untitled/src/features/auth/data/models/occupant_model.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel with proper nested structure', () {
      final user = UserModel(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+1234567890',
        profilePicture: 'https://example.com/profile.jpg',
        propertyName: 'Test Property',
        propertyId: 'prop-123',
        unitId: 'unit-456',
        unitType: 'Studio',
        moveInDate: DateTime(2024, 1, 15),
        leaseEndDate: DateTime(2024, 12, 31),
        rentAmount: 1200.0,
        status: 'active',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user.id, 'test-id');
      expect(user.fullName, 'John Doe');
      expect(user.email, 'john.doe@example.com');
      expect(user.phoneNumber, '+1234567890');
      expect(user.status, 'active');
    });

    test('should convert UserModel to JSON with nested structure', () {
      final user = UserModel(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+1234567890',
        profilePicture: 'https://example.com/profile.jpg',
        propertyName: 'Test Property',
        propertyId: 'prop-123',
        unitId: 'unit-456',
        unitType: 'Studio',
        moveInDate: DateTime(2024, 1, 15),
        leaseEndDate: DateTime(2024, 12, 31),
        rentAmount: 1200.0,
        status: 'active',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = user.toJson();

      expect(json['profile']['firstName'], 'John');
      expect(json['profile']['lastName'], 'Doe');
      expect(json['profile']['email'], 'john.doe@example.com');
      expect(json['profile']['phoneNumber'], '+1234567890');
      expect(json['property']['propertyName'], 'Test Property');
      expect(json['property']['unitId'], 'unit-456');
      expect(json['account']['status'], 'active');
    });

    test('should create empty UserModel', () {
      final emptyUser = UserModel.empty();

      expect(emptyUser.id, '');
      expect(emptyUser.firstName, '');
      expect(emptyUser.lastName, '');
      expect(emptyUser.email, '');
      expect(emptyUser.fullName, ' ');
      expect(emptyUser.status, 'pending');
    });
  });

  group('OccupantModel', () {
    test('should create OccupantModel with required fields', () {
      final occupant = OccupantModel(
        id: 'occ-123',
        occupantName: 'Jane Smith',
        occupantPhone: '+0987654321',
      );

      expect(occupant.id, 'occ-123');
      expect(occupant.occupantName, 'Jane Smith');
      expect(occupant.occupantPhone, '+0987654321');
    });

    test('should convert OccupantModel to JSON', () {
      final occupant = OccupantModel(
        id: 'occ-123',
        occupantName: 'Jane Smith',
        occupantPhone: '+0987654321',
      );

      final json = occupant.toJson();

      expect(json['occupantName'], 'Jane Smith');
      expect(json['occupantPhone'], '+0987654321');
      // ID should not be included in toJson as it's managed by Firestore
      expect(json.containsKey('id'), false);
    });

    test('should create empty OccupantModel', () {
      final emptyOccupant = OccupantModel.empty();

      expect(emptyOccupant.id, '');
      expect(emptyOccupant.occupantName, '');
      expect(emptyOccupant.occupantPhone, '');
    });

    test('should create OccupantModel from Map', () {
      final data = {
        'occupantName': 'Bob Wilson',
        'occupantPhone': '+1122334455',
      };

      final occupant = OccupantModel.fromMap(data, 'occ-456');

      expect(occupant.id, 'occ-456');
      expect(occupant.occupantName, 'Bob Wilson');
      expect(occupant.occupantPhone, '+1122334455');
    });

    test('should support copyWith for immutable updates', () {
      final original = OccupantModel(
        id: 'occ-123',
        occupantName: 'Jane Smith',
        occupantPhone: '+0987654321',
      );

      final updated = original.copyWith(
        occupantPhone: '+1111111111',
      );

      expect(updated.id, 'occ-123');
      expect(updated.occupantName, 'Jane Smith');
      expect(updated.occupantPhone, '+1111111111');

      // Original should remain unchanged
      expect(original.occupantPhone, '+0987654321');
    });

    test('should have equality support', () {
      final occupant1 = OccupantModel(
        id: 'occ-123',
        occupantName: 'Jane Smith',
        occupantPhone: '+0987654321',
      );

      final occupant2 = OccupantModel(
        id: 'occ-123',
        occupantName: 'Jane Smith',
        occupantPhone: '+0987654321',
      );

      final occupant3 = OccupantModel(
        id: 'occ-456',
        occupantName: 'Jane Smith',
        occupantPhone: '+0987654321',
      );

      expect(occupant1 == occupant2, true);
      expect(occupant1 == occupant3, false);
      expect(occupant1.hashCode == occupant2.hashCode, true);
    });
  });
}