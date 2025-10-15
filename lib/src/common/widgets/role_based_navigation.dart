import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../core/utils/app_logger.dart';
import 'main_navigation.dart';

/// Role-based navigation wrapper that determines which shell to show
/// based on the authenticated user's role (tenant or admin)
class RoleBasedNavigation extends ConsumerWidget {
  const RoleBasedNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.debug('🔄 RoleBasedNavigation.build() called - Widget is rebuilding');
    
    final userProfile = ref.watch(userProfileProvider);
    
    return userProfile.when(
      data: (user) {
        AppLogger.debug('🎭 ROLE-BASED NAVIGATION: Determining UI based on user role');
        AppLogger.debug('   ├─ User: ${user.fullName}');
        AppLogger.debug('   ├─ Role: ${user.role.name}');
        AppLogger.debug('   └─ Navigation: ${user.role == UserRole.admin ? "AdminShell" : "MainNavigation (Tenant)"}');
        
        // Route based on user role
        switch (user.role) {
          case UserRole.admin:
            AppLogger.debug('   🎯 Returning AdminShell widget');
            return AdminShell(key: ValueKey('admin_${user.id}'));
          case UserRole.tenant:
            AppLogger.debug('   🎯 Returning MainNavigation widget');
            return MainNavigation(key: ValueKey('tenant_${user.id}'));
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