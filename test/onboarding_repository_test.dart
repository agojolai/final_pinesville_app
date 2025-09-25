import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled/src/features/onboarding/data/onboarding_repository.dart';

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
}