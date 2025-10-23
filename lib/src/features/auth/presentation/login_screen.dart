import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/constants/validators.dart';
import '../controllers/login_controller.dart';
import '../providers/auth_provider.dart';
import '../../admin/auth/presentation/admin_login_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
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
  Future<void> _handleLogin() async {
    final controller = ref.read(loginControllerProvider.notifier);
    
    if (!controller.validateForm(_formKey)) {
      return;
    }

    controller.dismissKeyboard(context);
    
    await controller.login(
      email: _emailController.text,
      password: _passwordController.text,
      context: context,
    );
  }

  // UI-only navigation methods - delegate to controller
  void _navigateToRegister() {
    HapticFeedback.lightImpact();
    final controller = ref.read(loginControllerProvider.notifier);
    controller.navigateToRegister(context);
  }

  void _navigateToForgotPassword() {
    HapticFeedback.lightImpact();
    final controller = ref.read(loginControllerProvider.notifier);
    controller.navigateToForgotPassword(context);
  }

  void _navigateToAdminLogin() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch controller state and auth state
    final loginState = ref.watch(loginControllerProvider);
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
                    
                    // Logo Section
                    const _LogoSection(),
                    
                    SizedBox(height: AppConstants.spacingXL),
                    
                    // Welcome Section
                    const _WelcomeSection(),
                    
                    SizedBox(height: AppConstants.spacingXL),
                    
                    // Login Form
                    _LoginForm(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      emailFocusNode: _emailFocusNode,
                      passwordFocusNode: _passwordFocusNode,
                      obscurePassword: loginState.obscurePassword,
                      onTogglePassword: () {
                        final controller = ref.read(loginControllerProvider.notifier);
                        controller.togglePasswordVisibility();
                      },
                    ),
                    
                    SizedBox(height: AppConstants.spacingMD),
                    
                    // Forgot Password Link
                    _ForgotPasswordLink(onTap: _navigateToForgotPassword),
                    
                    SizedBox(height: AppConstants.spacingXL),
                    
                    // Login Button
                    _LoginButton(
                      isLoading: isLoading,
                      onPressed: _handleLogin,
                    ),
                    
                    SizedBox(height: AppConstants.spacingLG),
                    
                    // Create Account Section
                    _CreateAccountSection(onTap: _navigateToRegister),
                    
                    SizedBox(height: AppConstants.spacingXXL),
                    
                    // Admin Login Button
                    _AdminLoginButton(onTap: _navigateToAdminLogin),
                    
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

// Logo Section Widget
class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo Container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: context.colorScheme.primary.withValues(alpha:0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/images/pinesville_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.colorScheme.primary,
                        context.colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Iconsax.home_2,
                    size: 60,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        
        SizedBox(height: AppConstants.spacingMD),
        
        // App Name
        Text(
          'Pinesville',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            color: context.colorScheme.primary,
          ),
        ),
        
        SizedBox(height: AppConstants.spacingXS),
        
        // Tagline
        Text(
          'Your Digital Home',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha:0.6),
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }
}

// Welcome Section Widget
class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: context.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        
        SizedBox(height: AppConstants.spacingSM),
        
        Text(
          'Sign in to access your account and manage your unit',
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

// Login Form Widget
class _LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  const _LoginForm({
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
            labelText: 'Email Address',
            hintText: 'Enter your email',
            labelStyle: TextStyle(
              fontSize: context.textTheme.bodyMedium?.fontSize,
              fontFamily: 'Montserrat',
            ),
            prefixIcon: Icon(
              Iconsax.sms,
              color: context.colorScheme.onSurface.withValues(alpha:0.6),
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
            labelText: 'Password',
            hintText: 'Enter your password',
            labelStyle: TextStyle(
              fontSize: context.textTheme.bodyMedium?.fontSize,
              fontFamily: 'Montserrat',
            ),
            prefixIcon: Icon(
              Iconsax.lock,
              color: context.colorScheme.onSurface.withValues(alpha:0.6),
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

// Forgot Password Link Widget
class _ForgotPasswordLink extends StatelessWidget {
  final VoidCallback onTap;

  const _ForgotPasswordLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: context.colorScheme.primary,
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMD,
            vertical: AppConstants.spacingSM,
          ),
        ),
        child: Text(
          'Forgot Password?',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }
}

// Login Button Widget
class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({
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
                    Iconsax.login,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.spacingSM),
                  Text(
                    'Sign In',
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

// Create Account Section Widget
class _CreateAccountSection extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateAccountSection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingSM),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha:0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Don\'t have an account? ',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.7),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: context.colorScheme.primary,
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSM,
                vertical: AppConstants.spacingXS,
              ),
            ),
            child: Text(
              'Create Account',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Admin Login Button Widget
class _AdminLoginButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AdminLoginButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: context.colorScheme.primary,
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD,
          vertical: AppConstants.spacingSM,
        ),
      ),
      child: Text(
        'Log in as Admin',
        style: context.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontFamily: 'Montserrat',
          color: context.colorScheme.primary,
        ),
      ),
    );
  }
}
