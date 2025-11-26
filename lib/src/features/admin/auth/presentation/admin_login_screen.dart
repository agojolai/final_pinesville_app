import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../../../../core/constants/validators.dart';
import '../controllers/admin_login_controller.dart';
import '../../../auth/providers/auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.durationNormal,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: AppConstants.durationSlow,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // UI-only method - delegates to controller
  Future<void> _handleAdminLogin() async {
    final controller = ref.read(adminLoginControllerProvider.notifier);
    
    if (!controller.validateForm(_formKey)) {
      return;
    }

    controller.dismissKeyboard(context);
    
    await controller.loginAsAdmin(
      email: _emailController.text,
      password: _passwordController.text,
      context: context,
    );
  }

  // Navigate back to tenant login
  void _navigateBackToTenantLogin() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watch controller state and auth state
    final adminLoginState = ref.watch(adminLoginControllerProvider);
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(AppConstants.spacingLG),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: AppConstants.spacingXL),
                    
                    // Admin Logo Section
                    const _AdminLogoSection(),
                    
                    SizedBox(height: AppConstants.spacingXL),
                    
                    // Admin Welcome Section
                    const _AdminWelcomeSection(),
                    
                    SizedBox(height: AppConstants.spacingXL),
                    
                    // Login Form
                    _AdminLoginForm(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      emailFocusNode: _emailFocusNode,
                      passwordFocusNode: _passwordFocusNode,
                      obscurePassword: adminLoginState.obscurePassword,
                      onTogglePassword: () {
                        final controller = ref.read(adminLoginControllerProvider.notifier);
                        controller.togglePasswordVisibility();
                      },
                    ),
                    
                    SizedBox(height: AppConstants.spacingXL),
                    
                    // Admin Login Button
                    _AdminLoginButton(
                      isLoading: isLoading,
                      onPressed: _handleAdminLogin,
                    ),
                    
                    SizedBox(height: AppConstants.spacingLG),
                    
                    // Back to Tenant Login Section
                    _BackToTenantLoginSection(onTap: _navigateBackToTenantLogin),
                    
                    SizedBox(height: AppConstants.spacingXL),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Admin Logo Section Widget
class _AdminLogoSection extends StatelessWidget {
  const _AdminLogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Admin Logo Container with gradient
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colorScheme.primary,
                context.colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.primary.withValues(alpha:0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Iconsax.shield_tick5,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: AppConstants.spacingMD),
        
        // Admin Panel Text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.security,
              color: context.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Text(
              'Admin Panel',
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: context.colorScheme.primary,
              ),
            ),
          ],
        ),
        
        SizedBox(height: AppConstants.spacingXS),
        
        // Security Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMD,
            vertical: AppConstants.spacingXS,
          ),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(
              color: context.colorScheme.primary.withValues(alpha:0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.lock_1,
                size: 14,
                color: context.colorScheme.primary,
              ),
              SizedBox(width: AppConstants.spacingXS),
              Text(
                'Secure Access',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Admin Welcome Section Widget
class _AdminWelcomeSection extends StatelessWidget {
  const _AdminWelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Administrative Access',
          style: context.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        
        SizedBox(height: AppConstants.spacingSM),
        
        Text(
          'Sign in with your admin credentials to access the management dashboard',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha:0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Admin Login Form Widget
class _AdminLoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  const _AdminLoginForm({
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Email Field
        TextFormField(
          controller: emailController,
          focusNode: emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.validateEmail,
          style: TextStyle(
                fontSize: context.textTheme.bodyMedium?.fontSize,
                fontFamily: 'Montserrat',
              ),
          decoration: InputDecoration(
            labelText: 'Admin Email',
            hintText: 'Enter your admin email',
            labelStyle: TextStyle(
              fontSize: context.textTheme.bodyMedium?.fontSize,
              fontFamily: 'Montserrat',
            ),
            prefixIcon: Icon(
              Iconsax.shield_tick,
              color: context.colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(
                color: context.colorScheme.outline.withValues(alpha:0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(
                color: context.colorScheme.outline.withValues(alpha:0.5),
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
          onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
        ),
        
        SizedBox(height: AppConstants.spacingMD),
        
        // Password Field
        TextFormField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          validator: (value) => Validators.validateEmptyText('Password', value),
          style: TextStyle(
                fontSize: context.textTheme.bodyMedium?.fontSize,
                fontFamily: 'Montserrat',
              ),
          decoration: InputDecoration(
            labelText: 'Admin Password',
            hintText: 'Enter your admin password',
            labelStyle: TextStyle(
              fontSize: context.textTheme.bodyMedium?.fontSize,
              fontFamily: 'Montserrat',
            ),
            prefixIcon: Icon(
              Iconsax.lock,
              color: context.colorScheme.primary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                color: context.colorScheme.onSurface.withValues(alpha:0.6),
              ),
              onPressed: onTogglePassword,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(
                color: context.colorScheme.outline.withValues(alpha:0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: BorderSide(
                color: context.colorScheme.outline.withValues(alpha:0.5),
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
          onFieldSubmitted: (_) => passwordFocusNode.unfocus(),
        ),
      ],
    );
  }
}

// Admin Login Button Widget
class _AdminLoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _AdminLoginButton({
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
          disabledBackgroundColor: context.colorScheme.onSurface.withValues(alpha:0.12),
          disabledForegroundColor: context.colorScheme.onSurface.withValues(alpha:0.38),
          elevation: 2,
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
                    Iconsax.shield_tick,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.spacingSM),
                  Text(
                    'Sign In as Admin',
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

// Back to Tenant Login Section Widget
class _BackToTenantLoginSection extends StatelessWidget {
  final VoidCallback onTap;

  const _BackToTenantLoginSection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingSM),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer.withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.arrow_left_2,
            size: 16,
            color: context.colorScheme.onSurface.withValues(alpha:0.7),
          ),
          SizedBox(width: AppConstants.spacingXS),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: context.colorScheme.onSurface,
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSM,
                vertical: AppConstants.spacingXS,
              ),
            ),
            child: Text(
              'Back to Tenant Login',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
