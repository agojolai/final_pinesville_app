import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/network_service.dart';
import '../../../core/snackbars/loaders.dart';
import '../providers/auth_provider.dart';
import '../../../common/widgets/main_navigation.dart';
import '../presentation/register_screen.dart';
import '../../profile/presentation/change_password_screen.dart';

/// Login Controller State
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool obscurePassword;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.obscurePassword = true,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? obscurePassword,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

/// Login Controller - Handles all login business logic
class LoginController extends StateNotifier<LoginState> {
  final Ref ref;
  
  LoginController(this.ref) : super(const LoginState());

  /// Toggle password visibility
  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// Handle login authentication
  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Clear any previous error and set loading state
      state = state.copyWith(errorMessage: null, isLoading: true);

      // Get NetworkService instance
      final networkService = ref.read(networkServiceProvider);

      // Use NetworkService to execute login with automatic network handling
      final result = await networkService.executeWithNetworkHandling(
        context,
        () async {

          //TODO: CHECK IF THE EMAIL IS IN Pending Tenants database 
          // if it is on pending tenants, then show error message "application under review" and do not login
          // Use existing auth provider for authentication
          final authNotifier = ref.read(authStateProvider.notifier);
          await authNotifier.signIn(email.trim(), password.trim());
          return true; // Return success indicator
        },
        noConnectionMessage: 'Please check your internet connection to sign in.',
      );

      state = state.copyWith(isLoading: false);

      // Check if login was successful
      if (result == true && context.mounted) {
        // Show success messagel
        Loaders.successSnackBar(
          context,
          title: 'Welcome Back!',
          message: 'Successfully logged into your account',
        );

        // Navigate to main navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
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
  }  /// Navigate to register screen
  void navigateToRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  /// Navigate to forgot password screen
  void navigateToForgotPassword(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  /// Validate form and return true if valid
  bool validateForm(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  /// Dismiss keyboard
  void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/// Login Controller Provider
final loginControllerProvider = StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref);
});