import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../../../core/exceptions/firebase_auth_exceptions.dart';
import '../../../core/constants/validators.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  
  bool _isLoading = false;

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
    
    // Pre-fill with user's email (you can get this from user data)
    _emailController.text = 'caleb.anderson@email.com';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate Firebase password reset email sending
      await Future.delayed(const Duration(seconds: 2));
      
      // TODO: Replace with actual Firebase Auth password reset
      // await FirebaseAuth.instance.sendPasswordResetEmail(
      //   email: _emailController.text.trim(),
      // );

      if (mounted) {
        // Show success message
        Loaders.successSnackBar(
          context,
          title: 'Email Sent!',
          message: 'Password reset instructions have been sent to ${_emailController.text.trim()}',
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Authentication Error',
          message: e.message,
        );
      }
    } catch (error) {
      // Handle other errors
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to send password reset email. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          icon: Icon(
            Iconsax.arrow_left,
            color: context.colorScheme.onSurface,
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
          padding: EdgeInsets.all(AppConstants.spacingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _HeaderSection(),
                
                SizedBox(height: AppConstants.spacingXL),
                
                // Email Input Section
                _EmailInputSection(
                  emailController: _emailController,
                  emailFocusNode: _emailFocusNode,
                ),
                
                SizedBox(height: AppConstants.spacingXL),
                
                // Action Button
                _ActionButton(
                  isLoading: _isLoading,
                  onPressed: _sendPasswordResetEmail,
                ),
                
                SizedBox(height: AppConstants.spacingLG),
                
                // Info Section
                _InfoSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Header Section Widget
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(AppConstants.spacingMD),
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Iconsax.security_safe,
            size: 32,
            color: context.colorScheme.primary,
          ),
        ),
        
        SizedBox(height: AppConstants.spacingLG),
        
        // Title
        Text(
          'Reset Your Password',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        
        SizedBox(height: AppConstants.spacingSM),
        
        // Description
        Text(
          'Enter your email address and we\'ll send you instructions to reset your password.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// Email Input Section Widget
class _EmailInputSection extends StatelessWidget {
  final TextEditingController emailController;
  final FocusNode emailFocusNode;

  const _EmailInputSection({
    required this.emailController,
    required this.emailFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        
        SizedBox(height: AppConstants.spacingSM),
        
        TextFormField(
          controller: emailController,
          focusNode: emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          validator: Validators.validateEmail,
          style: TextStyle(
                fontSize: context.textTheme.bodyMedium?.fontSize,
                fontFamily: 'Montserrat',
              ),
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            hintStyle: TextStyle(
              fontSize: context.textTheme.bodyMedium?.fontSize,
              fontFamily: 'Montserrat',
            ),
            prefixIcon: Icon(
              Iconsax.sms,
              color: context.colorScheme.onSurface.withOpacity(0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(
                color: context.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(
                color: context.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(
                color: context.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(
                color: context.colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(
                color: context.colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: context.colorScheme.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMD,
              vertical: AppConstants.spacingMD,
            ),
          ),
          onFieldSubmitted: (_) => emailFocusNode.unfocus(),
        ),
      ],
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.primary,
          foregroundColor: context.colorScheme.onPrimary,
          disabledBackgroundColor: context.colorScheme.onSurface.withOpacity(0.12),
          disabledForegroundColor: context.colorScheme.onSurface.withOpacity(0.38),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          padding: EdgeInsets.symmetric(
            vertical: AppConstants.spacingMD,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colorScheme.onPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.sms,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.spacingSM),
                  Text(
                    'Send Reset Email',
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
}

// Info Section Widget
class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: context.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle,
                size: 20,
                color: context.colorScheme.primary,
              ),
              SizedBox(width: AppConstants.spacingSM),
              Text(
                'Important Information',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.primary,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.spacingSM),
          
          Text(
            '• Check your email inbox and spam folder\n'
            '• The reset link will expire in 24 hours\n'
            '• If you don\'t receive the email, try again\n'
            '• Contact support if you continue having issues',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
