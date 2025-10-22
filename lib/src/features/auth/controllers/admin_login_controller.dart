import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/network_service.dart';
import '../../../core/snackbars/loaders.dart';
import '../../admin/presentation/admin_navigation.dart';
import '../../../core/utils/app_logger.dart';

class AdminLoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool obscurePassword;

  const AdminLoginState({
    this.isLoading = false,
    this.errorMessage,
    this.obscurePassword = true,
  });

  AdminLoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? obscurePassword,
  }) {
    return AdminLoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

class AdminLoginController extends StateNotifier<AdminLoginState> {
  final Ref ref;
  
  AdminLoginController(this.ref) : super(const AdminLoginState());

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> loginAsAdmin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      state = state.copyWith(errorMessage: null, isLoading: true);
      AppLogger.debug('ADMIN LOGIN ATTEMPT: $email');

      final networkService = ref.read(networkServiceProvider);

      final result = await networkService.executeWithNetworkHandling(
        context,
        () async {
          // Query the admin collection to verify credentials
          final adminSnapshot = await FirebaseFirestore.instance
              .collection('admin')
              .where('email', isEqualTo: email.trim())
              .limit(1)
              .get();
          
          if (adminSnapshot.docs.isEmpty) {
            AppLogger.error('ADMIN LOGIN FAILED: Admin not found in admin collection');
            throw Exception('Invalid admin credentials');
          }
          
          // Get the admin document
          final adminDoc = adminSnapshot.docs.first;
          final adminData = adminDoc.data();
          final storedPassword = adminData['password'] as String?;
          
          if (storedPassword == null || storedPassword != password.trim()) {
            AppLogger.error('ADMIN LOGIN FAILED: Invalid password');
            throw Exception('Invalid admin credentials');
          }
          
          AppLogger.debug('ADMIN LOGIN SUCCESSFUL: Credentials verified from admin collection');
          return true;
        },
        noConnectionMessage: 'Please check your internet connection to sign in as admin.',
      );

      state = state.copyWith(isLoading: false);

      if (result == true && context.mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Admin Access Granted',
          message: 'Welcome to the Admin Dashboard',
        );

        // Navigate directly to admin shell
        // Use pushAndRemoveUntil to clear navigation stack and prevent back navigation
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminNavigation()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (error) {
      AppLogger.error('ADMIN LOGIN ERROR: $error');
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

  bool validateForm(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

final adminLoginControllerProvider = StateNotifierProvider<AdminLoginController, AdminLoginState>((ref) {
  return AdminLoginController(ref);
});

