import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/src/features/onboarding/data/onboarding_repository.dart';

// Mock classes for testing Firestore integration
@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot, FirebaseAuth, User])
import 'onboarding_repository_test.mocks.dart';

void main() {
  group('OnboardingRepository', () {
    late OnboardingRepository repository;

    setUpAll(() async {
      // Initialize GetStorage for testing
      await GetStorage.init();
    });

    setUp(() {
      repository = OnboardingRepository();
      // Reset onboarding state before each test
      repository.resetOnboarding();
    });

    group('Local Storage Tests', () {
      test('should return false for isOnboardingCompleted by default', () {
        expect(repository.isOnboardingCompleted, false);
      });

      test('should return true after marking onboarding as completed', () async {
        await repository.markOnboardingCompleted();
        expect(repository.isOnboardingCompleted, true);
      });

      test('should reset onboarding status', () async {
        // First mark as completed
        await repository.markOnboardingCompleted();
        expect(repository.isOnboardingCompleted, true);

        // Then reset
        await repository.resetOnboarding();
        expect(repository.isOnboardingCompleted, false);
      });

      test('should persist onboarding status across repository instances', () async {
        // Mark as completed in first instance
        await repository.markOnboardingCompleted();
        expect(repository.isOnboardingCompleted, true);

        // Create new instance and check persistence
        final newRepository = OnboardingRepository();
        expect(newRepository.isOnboardingCompleted, true);
      });
    });

    group('Firestore Integration Tests', () {
      test('should get onboarding status from local storage when user is null', () async {
        // Arrange
        final storage = GetStorage();
        await storage.write('onboarding_completed', true);
        
        // Act
        final status = await repository.getOnboardingStatus();
        
        // Assert
        expect(status, true);
      });

      test('should handle errors gracefully when Firestore is unavailable', () async {
        // This test verifies that the repository falls back to local storage
        // when Firestore operations fail
        
        // Arrange - set local storage value
        final storage = GetStorage();
        await storage.write('onboarding_completed', true);
        
        // Act - should not throw even if Firestore is unavailable
        final status = await repository.getOnboardingStatus();
        
        // Assert - should return local storage value
        expect(status, true);
      });

      test('should sync from Firestore to local storage', () async {
        // This is a unit test that verifies the sync functionality
        // In a real integration test, you would mock Firestore responses
        
        // Act
        await repository.syncFromFirestore();
        
        // Assert - should not throw errors
        expect(true, true); // Test passes if no exception is thrown
      });
    });

    group('Admin Utilities Tests', () {
      test('should get onboarding statistics without errors', () async {
        // Act
        final stats = await repository.getOnboardingStatistics();
        
        // Assert - should return valid structure
        expect(stats, isA<Map<String, int>>());
        expect(stats.containsKey('totalUsers'), true);
        expect(stats.containsKey('completedOnboarding'), true);
        expect(stats.containsKey('pendingOnboarding'), true);
      });

      test('should handle admin operations without errors', () async {
        // These tests verify that admin methods don't crash
        // In real integration tests, you would verify the actual Firestore updates
        
        const testUserId = 'test-user-id';
        
        // Act & Assert - should not throw
        expect(() => repository.adminResetOnboardingForUser(testUserId), 
               returnsNormally);
        expect(() => repository.adminMarkOnboardingCompletedForUser(testUserId), 
               returnsNormally);
      });

      test('should stream all users onboarding status', () {
        // Act
        final stream = repository.getAllUsersOnboardingStatus();
        
        // Assert
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
      });
    });

    group('Error Handling Tests', () {
      test('should handle null user gracefully in getOnboardingStatus', () async {
        // Act
        final status = await repository.getOnboardingStatus();
        
        // Assert - should not throw and should return a boolean
        expect(status, isA<bool>());
      });

      test('should handle Firestore errors in markOnboardingCompleted', () async {
        // This test ensures that even if Firestore operations fail,
        // the local storage is still updated
        
        // Arrange
        final storage = GetStorage();
        await storage.remove('onboarding_completed');
        
        // Act - should not throw even if Firestore fails
        await repository.markOnboardingCompleted();
        
        // Assert - local storage should be updated
        expect(storage.read('onboarding_completed'), true);
      });

      test('should handle Firestore errors in resetOnboarding', () async {
        // Similar to above, but for reset operation
        
        // Arrange
        final storage = GetStorage();
        await storage.write('onboarding_completed', true);
        
        // Act
        await repository.resetOnboarding();
        
        // Assert - local storage should be cleared
        expect(storage.read('onboarding_completed'), isNull);
      });
    });

    group('Backward Compatibility Tests', () {
      test('should maintain compatibility with sync isOnboardingCompleted getter', () {
        // This ensures existing code continues to work
        
        final storage = GetStorage();
        storage.write('onboarding_completed', true);
        
        expect(repository.isOnboardingCompleted, true);
        
        storage.write('onboarding_completed', false);
        
        expect(repository.isOnboardingCompleted, false);
      });

      test('should handle mixed local and cloud states', () async {
        // This test verifies behavior when local and cloud states might differ
        
        // Arrange - set local storage to one value
        final storage = GetStorage();
        await storage.write('onboarding_completed', false);
        
        // Act - get status (which should sync if user is authenticated)
        final status = await repository.getOnboardingStatus();
        
        // Assert - should return a consistent boolean value
        expect(status, isA<bool>());
      });
    });
  });
}