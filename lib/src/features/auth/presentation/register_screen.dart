import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../../../core/constants/validators.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  String? _selectedUnit;
  String? _selectedProperty;
  DateTime? _selectedMoveInDate;
  
  // Sample property options - will be fetched from database later
  final List<String> _availableProperties = [
    'Pinesville Pasig',
  ];
  
  // Sample unit numbers - will be fetched from database later
  final List<String> _availableUnits = [
    '101-A', '101-B', '102-A', '102-B', '103-A', '103-B',
    '201-A', '201-B', '202-A', '202-B', '203-A', '203-B',
    '301-A', '301-B', '302-A', '302-B', '303-A', '303-B',
    '401-A', '401-B', '402-A', '402-B', '403-A', '403-B',
  ];

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProperty == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Property Required',
        message: 'Please select a property',
      );
      return;
    }

    if (_selectedUnit == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Unit Required',
        message: 'Please select a unit number',
      );
      return;
    }

    if (_selectedMoveInDate == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Move-in Date Required',
        message: 'Please select your move-in date',
      );
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // Use Riverpod auth provider for registration
      final authNotifier = ref.read(authStateProvider.notifier);
      
      await authNotifier.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // TODO: After successful registration, store additional user data in Firestore
      // This should include firstName, lastName, phoneNumber, propertyName, unitNumber, moveInDate

      if (mounted) {
        // Show success message
        Loaders.successSnackBar(
          context,
          title: 'Account Created!',
          message: 'Your account has been created successfully',
        );

        // Navigate back to login
        Navigator.of(context).pop();
      }
    } catch (error) {
      // Handle errors
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Registration Failed',
          message: error.toString(),
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

  Future<void> _selectMoveInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020), // Allow dates from 2020 onwards
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.colorScheme,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedMoveInDate) {
      setState(() {
        _selectedMoveInDate = picked;
      });
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Account',
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppConstants.spacingSM),
                
                // Header Section
                _HeaderSection(),
                
                SizedBox(height: AppConstants.spacingXL),
                
                // Personal Information Section
                _SectionTitle(title: 'Personal Information'),
                SizedBox(height: AppConstants.spacingMD),
                
                // First Name & Last Name Row
                Row(
                  children: [
                    Expanded(
                      child: _CustomTextField(
                        controller: _firstNameController,
                        focusNode: _firstNameFocusNode,
                        label: 'First Name',
                        hint: 'Enter first name',
                      
                        icon: Iconsax.user,
                        validator: (value) => Validators.validateEmptyText('First name', value),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _lastNameFocusNode.requestFocus(),
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingMD),
                    Expanded(
                      child: _CustomTextField(
                        controller: _lastNameController,
                        focusNode: _lastNameFocusNode,
                        label: 'Last Name',
                        hint: 'Enter last name',
                        icon: Iconsax.user,
                        validator: (value) => Validators.validateEmptyText('Last name', value),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: AppConstants.spacingMD),
                
                // Email Field
                _CustomTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  icon: Iconsax.sms,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
                ),
                
                SizedBox(height: AppConstants.spacingMD),
                
                // Phone Number Field
                _CustomTextField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhoneNumber,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),
                
                SizedBox(height: AppConstants.spacingXL),
                
                // Unit & Move-in Information Section
                _SectionTitle(title: 'Unit & Move-in Information'),
                SizedBox(height: AppConstants.spacingMD),
                
                
                //Property Dropdown
                _PropertyDropdown(
                  selectedProperty: _selectedProperty,
                  availableProperties: _availableProperties,
                  onChanged: (value) {
                    setState(() {
                      _selectedProperty = value;
                    });
                  },
                ),
                
                SizedBox(height: AppConstants.spacingMD),
                
                // Unit Number Dropdown
                _UnitDropdown(
                  selectedUnit: _selectedUnit,
                  availableUnits: _availableUnits,
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value;
                    });
                  },
                ),
                
                SizedBox(height: AppConstants.spacingMD),
                
                // Move-in Date Picker
                _DatePickerField(
                  selectedDate: _selectedMoveInDate,
                  onTap: _selectMoveInDate,
                ),
                
                SizedBox(height: AppConstants.spacingXL),
                
                // Security Section
                _SectionTitle(title: 'Security'),
                SizedBox(height: AppConstants.spacingMD),
                
                // Password Field
                _CustomTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  label: 'Password',
                  hint: 'Create a strong password',
                  icon: Iconsax.lock,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                      color: context.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                
                SizedBox(height: AppConstants.spacingMD),
                
                // Confirm Password Field
                _CustomTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Iconsax.lock,
                  obscureText: _obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _confirmPasswordFocusNode.unfocus(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                      color: context.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                
                SizedBox(height: AppConstants.spacingXL),
                
                // Register Button
                _RegisterButton(
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                
                SizedBox(height: AppConstants.spacingMD),
                
                // Terms and Conditions
                _TermsAndConditions(),
                
                SizedBox(height: AppConstants.spacingXL),
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
      children: [
        Icon(
          Iconsax.user_add,
          size: 64,
          color: context.colorScheme.primary,
        ),
        SizedBox(height: AppConstants.spacingMD),
        Text(
          'Join Pinesville',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingSM),
        Text(
          'Create your account to get started with your digital home experience',
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Section Title Widget
class _SectionTitle extends StatelessWidget {
  final String title;
  
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontFamily: 'Montserrat',
        color: context.colorScheme.primary,
      ),
    );
  }
}

// Custom Text Field Widget
class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool obscureText;
  final Widget? suffixIcon;

  const _CustomTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(
        fontSize: context.textTheme.bodyMedium?.fontSize,
        fontFamily: 'Montserrat',
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: context.textTheme.bodyMedium?.fontSize,
          fontFamily: 'Montserrat',
        ),
        hintStyle: TextStyle(
          fontSize: context.textTheme.bodyMedium?.fontSize,
          fontFamily: 'Montserrat',
        ),
        prefixIcon: Icon(
          icon,
          color: context.colorScheme.onSurface.withOpacity(0.6),
        ),
        suffixIcon: suffixIcon,
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
    );
  }
}

// Property Dropdown Widget
class _PropertyDropdown extends StatelessWidget {
  final String? selectedProperty;
  final List<String> availableProperties;
  final void Function(String?) onChanged;

  const _PropertyDropdown({
    required this.selectedProperty,
    required this.availableProperties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedProperty,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a property' : null,
      style: TextStyle(
        fontSize: context.textTheme.bodyMedium?.fontSize,
        fontFamily: 'Montserrat',
        color: context.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: 'Property',
        hintText: 'Select property',
        labelStyle: TextStyle(
          fontSize: context.textTheme.bodyMedium?.fontSize,
          fontFamily: 'Montserrat',
        ),
        hintStyle: TextStyle(
          fontSize: context.textTheme.bodyMedium?.fontSize,
          fontFamily: 'Montserrat',
        ),
        prefixIcon: Icon(
          Iconsax.buildings,
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
      items: availableProperties.map((String property) {
        return DropdownMenuItem<String>(
          value: property,
          child: Text(property),
        );
      }).toList(),
    );
  }
}

// Unit Dropdown Widget
class _UnitDropdown extends StatelessWidget {
  final String? selectedUnit;
  final List<String> availableUnits;
  final void Function(String?) onChanged;

  const _UnitDropdown({
    required this.selectedUnit,
    required this.availableUnits,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedUnit,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select a unit' : null,
      style: TextStyle(
        fontSize: context.textTheme.bodyMedium?.fontSize,
        fontFamily: 'Montserrat',
        color: context.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: 'Unit Number',
        hintText: 'Select your unit',
        labelStyle: TextStyle(
          fontSize: context.textTheme.bodyMedium?.fontSize,
          fontFamily: 'Montserrat',
        ),
        hintStyle: TextStyle(
          fontSize: context.textTheme.bodyMedium?.fontSize,
          fontFamily: 'Montserrat',
        ),
        prefixIcon: Icon(
          Iconsax.home_2,
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
      items: availableUnits.map((String unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(unit),
        );
      }).toList(),
    );
  }
}

// Date Picker Field Widget
class _DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      validator: (value) => selectedDate == null ? 'Please select move-in date' : null,
      style: TextStyle(
        fontSize: context.textTheme.bodyMedium?.fontSize,
        fontFamily: 'Montserrat',
      ),
      decoration: InputDecoration(
        labelText: 'Move-in Date',
        hintText: 'Select your move-in date',
        labelStyle: TextStyle(
          fontSize: context.textTheme.bodyMedium?.fontSize,
          fontFamily: 'Montserrat',
        ),
        hintStyle: TextStyle(
          fontSize: context.textTheme.bodyMedium?.fontSize,
          fontFamily: 'Montserrat',
          color: context.colorScheme.onSurface.withOpacity(0.6),
        ),
        prefixIcon: Icon(
          Iconsax.calendar,
          color: context.colorScheme.onSurface.withOpacity(0.6),
        ),
        suffixIcon: Icon(
          Iconsax.arrow_down_1,
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
      controller: TextEditingController(
        text: selectedDate != null 
            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
            : '',
      ),
    );
  }
}

// Register Button Widget
class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RegisterButton({
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
                    Iconsax.user_add,
                    size: 20,
                  ),
                  SizedBox(width: AppConstants.spacingSM),
                  Text(
                    'Create Account',
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

// Terms and Conditions Widget
class _TermsAndConditions extends StatelessWidget {
  const _TermsAndConditions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSM),
      child: Text(
        'By creating an account, you agree to our Terms of Service and Privacy Policy. Your information will be used to manage your tenancy and improve your experience.',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurface.withOpacity(0.6),
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
