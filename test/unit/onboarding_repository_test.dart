import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled/src/features/onboarding/data/onboarding_repository.dart';

const MethodChannel _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingRepository', () {
    late OnboardingRepository repository;
    late Directory tempDirectory;

    setUpAll(() async {
      tempDirectory = await Directory.systemTemp.createTemp('onboarding_repo_test_');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDirectory.path;
        }
        return null;
      });

      // Initialize GetStorage for testing using the mocked path provider
      await GetStorage.init();
    });

    tearDownAll(() async {
      await GetStorage().erase();

      try {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      } catch (_) {
        // Ignore deletion failures on platforms that keep file handles open.
      }
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