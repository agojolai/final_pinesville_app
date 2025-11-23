import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/snackbars/loaders.dart';
import 'account_settings_screen.dart';
import 'change_password_screen.dart';
import '../../support/presentation/reports_tickets_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../onboarding/presentation/onboarding_test_screen.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../providers/profile_provider.dart';
import '../../auth/data/models/user_model.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.durationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        toolbarHeight: AppConstants.appBarHeight,
        elevation: 0,
        backgroundColor: context.colorScheme.surface,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Watch the user profile provider
              Consumer(
                builder: (context, ref, child) {
                  final userProfileAsync = ref.watch(userProfileProvider);
                  
                  return userProfileAsync.when(
                    data: (userModel) => _ProfileHeader(userModel: userModel),
                    loading: () => _ProfileHeaderLoading(),
                    error: (error, stack) => _ProfileHeaderError(error: error.toString()),
                  );
                },
              ),
              SizedBox(height: AppConstants.spacingLG),
              const _ProfileSections(),
              SizedBox(height: AppConstants.spacingXL),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Header Widget
class _ProfileHeader extends ConsumerStatefulWidget {
  final UserModel userModel;
  
  const _ProfileHeader({required this.userModel});

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _isUploadingImage = false;

  Future<void> _changeProfilePicture() async {
    // Store theme before any async operations
    final theme = Theme.of(context);
    
    try {
      // Show image source selection bottom sheet
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusMD),
          ),
        ),
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Iconsax.gallery, color: Theme.of(context).colorScheme.primary),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null || !mounted) return;

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      // Crop image - use stored theme instead of context
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: theme.colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null || !mounted) return;

      // Show loading state
      setState(() {
        _isUploadingImage = true;
      });

      // Upload to Firebase Storage
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final String storagePath = 'users/$userId';
      final XFile imageFile = XFile(croppedFile.path);
      final String downloadUrl = await UserRepository.instance.uploadImage(
        storagePath,
        imageFile,
      );

      // Update Firestore with new profile picture URL
      await UserRepository.instance.updateProfilePicture(downloadUrl);

      if (!mounted) return;

      // Hide loading state
      setState(() {
        _isUploadingImage = false;
      });

      // Invalidate profile provider to refresh UI
      ref.invalidate(userProfileProvider);

      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Success',
          message: 'Profile picture updated successfully',
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to update profile picture: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(AppConstants.spacingMD),
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary,
            context.colorScheme.primary.withValues(alpha: 0.92),
            context.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: context.radiusXL,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: _isUploadingImage ? null : _changeProfilePicture,
            child: Stack(
              children: [
                Hero(
                  tag: 'profile_picture',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _isUploadingImage
                          ? Container(
                              color: context.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: context.colorScheme.primary,
                                ),
                              ),
                            )
                          : widget.userModel.profilePicture.isNotEmpty
                              ? Image.network(
                                  widget.userModel.profilePicture,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/default_profile.png',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/default_profile.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: context.colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Iconsax.user,
                                        size: 40,
                                        color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ),
                ),
                if (!_isUploadingImage)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(AppConstants.spacingXS),
                      decoration: BoxDecoration(
                        color: context.colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Iconsax.camera,
                        size: 16,
                        color: context.colorScheme.onSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          
          // Name and Unit
          Text(
            widget.userModel.fullName,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSM,
              vertical: AppConstants.spacingXS,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.userModel.unitId.isNotEmpty ? 'Unit ${widget.userModel.unitId}' : 'No Unit Assigned',
              style: context.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          
          // Quick Info
          _QuickInfoRow(userModel: widget.userModel),
        ],
      ),
    );
  }
}

// Quick Info Row Widget
class _QuickInfoRow extends StatelessWidget {
  final UserModel userModel;
  
  const _QuickInfoRow({required this.userModel});

  String _formatMoveInDate(DateTime? moveInDate) {
    if (moveInDate == null) return 'Move-in date not available';
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return 'Move-in: ${months[moveInDate.month - 1]} ${moveInDate.day}, ${moveInDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Iconsax.sms,
              size: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            SizedBox(width: AppConstants.spacingXS),
            Expanded(
              child: Text(
                userModel.email.isNotEmpty ? userModel.email : 'No email available',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacingXS),
        Row(
          children: [
            Icon(
              Iconsax.call,
              size: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            SizedBox(width: AppConstants.spacingXS),
            Text(
              userModel.phoneNumber.isNotEmpty ? userModel.phoneNumber : 'No phone number',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacingXS),
        Row(
          children: [
            Icon(
              Iconsax.calendar,
              size: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            SizedBox(width: AppConstants.spacingXS),
            Text(
              _formatMoveInDate(userModel.moveInDate),
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Profile Sections Widget
class _ProfileSections extends StatelessWidget {
  const _ProfileSections();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMD),
      child: Column(
        children: [
          _ProfileSection(
            title: 'Account',
            items: [
              _ProfileMenuItem(
                icon: Iconsax.setting_2,
                title: 'Account Settings',
                subtitle: 'Edit profile, manage occupants',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen(),
                    ),
                  );
                },
              ),
              _ProfileMenuItem(
                icon: Iconsax.security_safe,
                title: 'Security',
                subtitle: 'Change password',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          _ProfileSection(
            title: 'Contract & Property',
            items: [
              _ProfileMenuItem(
                icon: Iconsax.document_text,
                title: 'My Contract',
                subtitle: 'Download your contract',
                onTap: () => _showComingSoon(context), // TODO: download dapat to
              ),
              _ProfileMenuItem(
                icon: Iconsax.refresh,
                title: 'Renew / Move-out',
                subtitle: 'Contract renewal options',
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          _ProfileSection(
            title: 'Support',
            items: [
              _ProfileMenuItem(
                icon: Iconsax.message_question,
                title: 'Submit an Issue',
                subtitle: 'Submit and track issues',
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReportsTicketsScreen(),
                    ),
                  );
      
                },
 
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          _ProfileSection(
            title: 'Information',
            items: [
              _ProfileMenuItem(
                icon: Iconsax.info_circle,
                title: 'About App',
                subtitle: 'Version, privacy policy',
                onTap: () => _showAboutDialog(context),
              ),
              _ProfileMenuItem(
                icon: Iconsax.command_square,
                title: 'Onboarding Test',
                subtitle: 'Test onboarding walkthrough',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OnboardingTestScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          _LogoutButton(),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    Loaders.infoSnackBar(
      context,
      title: 'Coming Soon',
      message: 'This feature will be available in a future update.',
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About Pinesville App',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: AppConstants.spacingSM),
            Text('Developer: Pinesville Management'),
            SizedBox(height: AppConstants.spacingSM),
            Text('© 2025 Pinesville. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Profile Section Widget
class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _ProfileSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSM),
          child: Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface.withValues(alpha: 0.8),
              fontFamily: 'Montserrat',
            ),
          ),
        ),
        SizedBox(height: AppConstants.spacingSM),
        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: context.radiusXL,
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.outline.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

// Profile Menu Item Widget
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;


  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,

  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radiusXL,
        child: Container(
          padding: EdgeInsets.all(AppConstants.spacingMD),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(AppConstants.spacingSM),
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: context.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: AppConstants.spacingMD),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon
              Icon(
                Iconsax.arrow_right_3,
                color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Logout Button Widget
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.errorContainer,
          foregroundColor: context.colorScheme.onErrorContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: context.radiusXL,
          ),
          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMD),
        ),
        onPressed: () => _showLogoutDialog(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.logout,
              size: 20,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Text(
              'Logout',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // Show loading indicator using circular progress dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text('Logging out...'),
                      ],
                    ),
                  ),
                );
                
                // Sign out using AuthRepository
                await AuthRepository.instance.logout();
                
                // Hide loading dialog
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                
                // Navigate to login screen and clear navigation stack
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
                
                // Show success message
                if (context.mounted) {
                  Loaders.successSnackBar(
                    context,
                    title: 'Logged out successfully',
                  );
                }
              } catch (e) {
                // Hide loading dialog if error occurs
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                
                // Show error message
                if (context.mounted) {
                  Loaders.errorSnackBar(
                    context,
                    title: 'Logout Failed',
                    message: 'An error occurred while logging out. Please try again.',
                  );
                }
              }
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Profile Header Loading Widget
class _ProfileHeaderLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(AppConstants.spacingMD),
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary.withValues(alpha: 0.3),
            context.colorScheme.primaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: context.radiusXL,
      ),
      child: Column(
        children: [
          // Profile Picture Skeleton
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: Icon(
              Iconsax.user,
              size: 40,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          
          // Loading text
          Container(
            height: 24,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Container(
            height: 20,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          
          // Loading info rows
          for (int i = 0; i < 3; i++) ...[
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: AppConstants.spacingXS),
                Container(
                  height: 16,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            if (i < 2) SizedBox(height: AppConstants.spacingXS),
          ],
        ],
      ),
    );
  }
}

// Profile Header Error Widget
class _ProfileHeaderError extends StatelessWidget {
  final String error;
  
  const _ProfileHeaderError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(AppConstants.spacingMD),
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.warning_2,
            size: 50,
            color: context.colorScheme.error,
          ),
          SizedBox(height: AppConstants.spacingMD),
          Text(
            'Error Loading Profile',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.error,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            error.length > 100 ? '${error.substring(0, 100)}...' : error,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onErrorContainer,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          ElevatedButton.icon(
            onPressed: () {
              // Refresh could be implemented by invalidating the provider
            },
            icon: Icon(Iconsax.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
