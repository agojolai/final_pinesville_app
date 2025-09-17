import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/network_service.dart';
import '../../../core/snackbars/loaders.dart';
import '../../../core/repositories/user_repository.dart';
import '../providers/auth_provider.dart';

/// Register Controller State
class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }
}

/// Register Controller - Handles all registration business logic
class RegisterController extends StateNotifier<RegisterState> {
  final Ref ref;

  RegisterController(this.ref) : super(const RegisterState());

  /// Toggle password visibility
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    state =
        state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword);
  }

  /// Validate registration form data
  bool validateRegistrationData({
    required GlobalKey<FormState> formKey,
    required String? selectedProperty,
    required String? selectedUnit,
    required DateTime? selectedMoveInDate,
    required BuildContext context,
  }) {
    // Validate form fields
    if (!formKey.currentState!.validate()) {
      return false;
    }

    // Validate property selection
    if (selectedProperty == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Property Required',
        message: 'Please select a property',
      );
      return false;
    }

    // Validate unit selection
    if (selectedUnit == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Unit Required',
        message: 'Please select a unit number',
      );
      return false;
    }

    // Validate move-in date selection
    if (selectedMoveInDate == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Move-in Date Required',
        message: 'Please select your move-in date',
      );
      return false;
    }

    return true;
  }

  /// Handle user registration
  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String propertyName,
    required String unitNumber,
    required DateTime moveInDate,
    required BuildContext context,
  }) async {
    try {
      // Clear any previous error and set loading state
      state = state.copyWith(errorMessage: null, isLoading: true);

      // Get NetworkService instance
      final networkService = ref.read(networkServiceProvider);

      // Use NetworkService to execute registration with automatic network handling
      final result = await networkService.executeWithNetworkHandling(
        context,
        () async {
          // Step 1: Create Firebase Auth account
          final authNotifier = ref.read(authStateProvider.notifier);
          final userCredential =
              await authNotifier.signUp(email.trim(), password.trim());

          // Step 2: Store additional user data in Firestore
          if (userCredential?.user != null) {
            final newUser =
                UserRepository.instance.createUserFromRegistration(
              uid: userCredential!.user!.uid,
              firstName: firstName,
              lastName: lastName,
              email: email,
              phoneNumber: phoneNumber,
              propertyName: propertyName,
              unitNumber: unitNumber,
              moveInDate: moveInDate,
  
            );

            await UserRepository.instance.saveUserRecord(newUser);
          }

          return true; // Return success indicator
        },
        noConnectionMessage:
            'Internet connection required for account creation.',
      );

      state = state.copyWith(isLoading: false);

      // Check if registration was successful
      if (result == true && context.mounted) {
        // Show success message
        Loaders.successSnackBar(
          context,
          title: 'Account Created!',
          message: 'Your account has been created successfully',
        );

        // Navigate back to login
        Navigator.of(context).pop();
      }
    } catch (error) {
      // Handle any errors not caught by NetworkService
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );

      if (context.mounted) {
        final networkService = ref.read(networkServiceProvider);
        networkService.showErrorWithNetworkHandling(context, error);
      }
    }
  }

  /// Show date picker for move-in date
  Future<DateTime?> selectMoveInDate(
      BuildContext context, DateTime? currentDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2020), // Allow dates from 2020 onwards
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    return picked;
  }

  /// Validate confirm password matches password
  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Dismiss keyboard
  void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Navigate to login screen
  void navigateToLogin(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Register Controller Provider
final registerControllerProvider =
    StateNotifierProvider<RegisterController, RegisterState>((ref) {
  return RegisterController(ref);
});
