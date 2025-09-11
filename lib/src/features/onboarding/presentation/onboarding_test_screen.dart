import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../data/onboarding_repository.dart';
import 'onboarding_screen.dart';

class OnboardingTestScreen extends StatefulWidget {
  const OnboardingTestScreen({super.key});

  @override
  State<OnboardingTestScreen> createState() => _OnboardingTestScreenState();
}

class _OnboardingTestScreenState extends State<OnboardingTestScreen> {
  final OnboardingRepository _repository = OnboardingRepository();
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    setState(() {
      _isCompleted = _repository.isOnboardingCompleted;
    });
  }

  void _resetOnboarding() async {
    HapticFeedback.mediumImpact();
    await _repository.resetOnboarding();
    _checkStatus();
    
    if (mounted) {
      Loaders.successSnackBar(
        context,
        title: 'Reset Complete',
        message: 'Onboarding has been reset. App will show onboarding on next launch.',
      );
    }
  }

  void _markCompleted() async {
    HapticFeedback.lightImpact();
    await _repository.markOnboardingCompleted();
    _checkStatus();
    
    if (mounted) {
      Loaders.successSnackBar(
        context,
        title: 'Marked Complete',
        message: 'Onboarding is now marked as completed.',
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Onboarding Test',
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
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
                      _isCompleted ? 'Completed' : 'Not Completed',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: _isCompleted
                            ? context.colorScheme.primary
                            : context.colorScheme.error,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingSM),
                    Text(
                      _isCompleted
                          ? 'User has completed the onboarding walkthrough.'
                          : 'User will see onboarding screen on app launch.',
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

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.color,
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
          onTap: onTap,
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
                  child: Icon(
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