import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/admin/presentation/admin_shell.dart';
import 'main_navigation.dart';

/// Role-based navigation wrapper that determines which shell to show
/// based on the authenticated user's role (tenant or admin)
class RoleBasedNavigation extends ConsumerWidget {
  const RoleBasedNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    
    return userProfile.when(
      data: (user) {
        // Route based on user role
        switch (user.role) {
          case UserRole.admin:
            return const AdminShell();
          case UserRole.tenant:
            return const MainNavigation();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading user profile...',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) {
        // On error, default to tenant interface
        debugPrint('Error loading user profile for role routing: $error');
        return const MainNavigation();
      },
    );
  }
}