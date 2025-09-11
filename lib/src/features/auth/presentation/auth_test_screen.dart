import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../auth/providers/auth_provider.dart';
import 'login_screen.dart';

class AuthTestScreen extends ConsumerWidget {
  const AuthTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Firebase Auth Test',
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(authStateProvider.notifier).signOut();
            },
            icon: Icon(
              Iconsax.logout,
              color: context.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auth Status Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppConstants.spacingMD),
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(
                    color: context.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Status',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingSM),
                    Row(
                      children: [
                        Icon(
                          authState.status == AuthStatus.authenticated
                              ? Iconsax.tick_circle
                              : Iconsax.close_circle,
                          color: authState.status == AuthStatus.authenticated
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: AppConstants.spacingSM),
                        Text(
                          'Status: ${authState.status.name}',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    if (authState.errorMessage != null) ...[
                      SizedBox(height: AppConstants.spacingSM),
                      Container(
                        padding: EdgeInsets.all(AppConstants.spacingSM),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                        ),
                        child: Text(
                          'Error: ${authState.errorMessage}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(height: AppConstants.spacingLG),
              
              // User Info Card
              currentUser.when(
                data: (user) {
                  if (user == null) {
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppConstants.spacingMD),
                      decoration: BoxDecoration(
                        color: context.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      ),
                      child: Text(
                        'No user logged in',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onErrorContainer,
                        ),
                      ),
                    );
                  }
                  
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppConstants.spacingMD),
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      border: Border.all(
                        color: context.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Information',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppConstants.spacingSM),
                        _InfoRow(
                          label: 'Email',
                          value: user.email ?? 'No email',
                          context: context,
                        ),
                        _InfoRow(
                          label: 'UID',
                          value: user.uid,
                          context: context,
                        ),
                        _InfoRow(
                          label: 'Email Verified',
                          value: user.emailVerified ? 'Yes' : 'No',
                          context: context,
                        ),
                        _InfoRow(
                          label: 'Created',
                          value: user.metadata.creationTime?.toString() ?? 'Unknown',
                          context: context,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppConstants.spacingMD),
                  decoration: BoxDecoration(
                    color: context.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  child: Text(
                    'Error loading user: $error',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: AppConstants.spacingLG),
              
              // Test Actions
              Text(
                'Test Actions',
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppConstants.spacingMD),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: authState.status == AuthStatus.loading ? null : () {
                        ref.read(authStateProvider.notifier).signOut();
                      },
                      icon: const Icon(Iconsax.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorScheme.error,
                        foregroundColor: context.colorScheme.onError,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: AppConstants.spacingMD),
              
              // Navigation back to login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Iconsax.login),
                  label: const Text('Back to Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: context.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSecondaryContainer.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
