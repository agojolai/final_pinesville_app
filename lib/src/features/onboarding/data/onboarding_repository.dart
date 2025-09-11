import 'package:get_storage/get_storage.dart';

/// Repository to handle onboarding completion status
class OnboardingRepository {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  
  final GetStorage _storage = GetStorage();
  
  /// Check if user has completed onboarding
  bool get isOnboardingCompleted {
    return _storage.read(_onboardingCompletedKey) ?? false;
  }
  
  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    await _storage.write(_onboardingCompletedKey, true);
  }
  
  /// Reset onboarding status (useful for testing)
  Future<void> resetOnboarding() async {
    await _storage.remove(_onboardingCompletedKey);
  }
}