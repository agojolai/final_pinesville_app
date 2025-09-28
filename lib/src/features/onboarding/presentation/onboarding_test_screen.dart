import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../data/onboarding_repository.dart';
import 'onboarding_screen.dart';
import 'admin_onboarding_screen.dart';

class OnboardingTestScreen extends StatefulWidget {
  const OnboardingTestScreen({super.key});

  @override
  State<OnboardingTestScreen> createState() => _OnboardingTestScreenState();
}

class _OnboardingTestScreenState extends State<OnboardingTestScreen> {
  final OnboardingRepository _repository = OnboardingRepository();
  bool _isCompleted = false;
  bool _isLoadingStatus = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoadingStatus = true;
    });

    try {
      // Use the new async method for more accurate status
      final status = await _repository.getOnboardingStatus();
      setState(() {
        _isCompleted = status;
      });
    } catch (e) {
      // Fallback to sync method
      setState(() {
        _isCompleted = _repository.isOnboardingCompleted;
      });
    } finally {
      setState(() {
        _isLoadingStatus = false;
      });
    }
  }

  Future<void> _resetOnboarding() async {
    HapticFeedback.mediumImpact();
    
    try {
      await _repository.resetOnboarding();
      await _checkStatus();
      
      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Reset Complete',
          message: 'Onboarding has been reset in both local storage and Firestore.',
        );
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Reset Failed',
          message: 'Failed to reset onboarding: $e',
        );
      }
    }
  }

  Future<void> _markCompleted() async {
    HapticFeedback.lightImpact();
    
    try {
      await _repository.markOnboardingCompleted();
      await _checkStatus();
      
      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Marked Complete',
          message: 'Onboarding is now marked as completed in both local storage and Firestore.',
        );
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Update Failed',
          message: 'Failed to mark onboarding as completed: $e',
        );
      }
    }
  }

  Future<void> _syncFromFirestore() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _repository.syncFromFirestore();
      await _checkStatus();
      
      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Sync Complete',
          message: 'Onboarding status has been synced from Firestore.',
        );
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Sync Failed',
          message: 'Failed to sync from Firestore: $e',
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _previewOnboarding() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OnboardingScreen(),
      ),
    );
  }

  void _openAdminScreen() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminOnboardingScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Onboarding Test & Admin',
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _checkStatus,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppConstants.spacingMD),
                decoration: BoxDecoration(
                  color: _isCompleted
                      ? context.colorScheme.primaryContainer.withOpacity(0.1)
                      : context.colorScheme.errorContainer.withOpacity(0.1),
                  borderRadius: context.radiusLG,
                  border: Border.all(
                    color: _isCompleted
                        ? context.colorScheme.primary.withOpacity(0.3)
                        : context.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isLoadingStatus)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _isCompleted ? Iconsax.tick_circle : Iconsax.close_circle,
                            color: _isCompleted
                                ? context.colorScheme.primary
                                : context.colorScheme.error,
                            size: 24,
                          ),
                        SizedBox(width: AppConstants.spacingSM),
                        Text(
                          'Onboarding Status',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppConstants.spacingSM),
                    Text(
                      _isLoadingStatus 
                          ? 'Checking...' 
                          : (_isCompleted ? 'Completed' : 'Not Completed'),
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: _isLoadingStatus
                            ? context.colorScheme.onSurface.withOpacity(0.6)
                            : (_isCompleted
                                ? context.colorScheme.primary
                                : context.colorScheme.error),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingSM),
                    Text(
                      _isLoadingStatus
                          ? 'Syncing status from Firestore...'
                          : (_isCompleted
                              ? 'User has completed the onboarding walkthrough.'
                              : 'User will see onboarding screen on app launch.'),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.7),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppConstants.spacingXL),
              
              // Actions Section
              Text(
                'Test Actions',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: context.colorScheme.onSurface,
                ),
              ),
              
              SizedBox(height: AppConstants.spacingMD),
              
              // Preview Button
              _ActionButton(
                icon: Iconsax.eye,
                title: 'Preview Onboarding',
                description: 'See the onboarding walkthrough',
                onTap: _previewOnboarding,
                color: context.colorScheme.primary,
              ),
              
              SizedBox(height: AppConstants.spacingSM),
              
              // Sync Button
              _ActionButton(
                icon: _isSyncing ? Iconsax.loading_2 : Iconsax.refresh_2,
                title: 'Sync from Firestore',
                description: 'Update status from cloud database',
                onTap: _isSyncing ? () {} : _syncFromFirestore,
                color: Colors.blue,
                isLoading: _isSyncing,
              ),
              
              SizedBox(height: AppConstants.spacingSM),
              
              // Reset Button
              _ActionButton(
                icon: Iconsax.refresh,
                title: 'Reset Onboarding',
                description: 'Clear completion status for testing',
                onTap: _resetOnboarding,
                color: context.colorScheme.error,
              ),
              
              SizedBox(height: AppConstants.spacingSM),
              
              // Mark Complete Button
              _ActionButton(
                icon: Iconsax.tick_circle,
                title: 'Mark as Completed',
                description: 'Skip onboarding for future launches',
                onTap: _markCompleted,
                color: Colors.green,
              ),
              
              SizedBox(height: AppConstants.spacingXL),
              
              // Admin Section
              Text(
                'Admin Tools',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: context.colorScheme.onSurface,
                ),
              ),
              
              SizedBox(height: AppConstants.spacingMD),
              
              // Admin Screen Button
              _ActionButton(
                icon: Iconsax.setting_2,
                title: 'Admin Onboarding Manager',
                description: 'Manage onboarding for all users',
                onTap: _openAdminScreen,
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Color color;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: context.radiusLG,
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: context.radiusLG,
          child: Padding(
            padding: EdgeInsets.all(AppConstants.spacingMD),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppConstants.spacingSM),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: context.radiusSM,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        )
                      : Icon(
                          icon,
                          color: color,
                          size: 20,
                        ),
                ),
                SizedBox(width: AppConstants.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                          color: isLoading 
                              ? context.colorScheme.onSurface.withOpacity(0.6)
                              : context.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacingXS),
                      Text(
                        description,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withOpacity(0.6),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLoading)
                  Icon(
                    Iconsax.arrow_right_3,
                    color: context.colorScheme.onSurface.withOpacity(0.4),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}