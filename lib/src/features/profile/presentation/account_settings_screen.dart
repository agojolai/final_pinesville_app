import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/constants/validators.dart';
import '../../../core/snackbars/loaders.dart';
import '../providers/profile_provider.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/data/models/occupant_model.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Form keys
  final _formKey = GlobalKey<FormState>();
  final _occupantFormKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupantNameController = TextEditingController();
  final _occupantPhoneController = TextEditingController();

  // State variables
  bool _isEditingEmail = false;
  bool _isEditingPhone = false;
  OccupantModel? _editingOccupant;

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
    _emailController.dispose();
    _phoneController.dispose();
    _occupantNameController.dispose();
    _occupantPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Settings',
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
          child: Padding(
            padding: context.paddingHorizontal(AppConstants.spacingLG),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppConstants.spacingSM),
                  _ContactInformationSection(),
                  SizedBox(height: AppConstants.spacingLG),
                  _OccupantSection(),
                  SizedBox(height: AppConstants.spacingXL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ContactInformationSection() {
    return Consumer(
      builder: (context, ref, child) {
        final userProfileAsync = ref.watch(userProfileProvider);
        
        return userProfileAsync.when(
          data: (userModel) => _ContactInformationContent(userModel: userModel),
          loading: () => _ContactInformationLoading(),
          error: (error, stack) => _ContactInformationError(error: error.toString()),
        );
      },
    );
  }

  Widget _ContactInformationContent({required UserModel userModel}) {
    // Initialize controllers with current data when user model is available
    if (_emailController.text.isEmpty && userModel.email.isNotEmpty) {
      _emailController.text = userModel.email;
    }
    if (_phoneController.text.isEmpty && userModel.phoneNumber.isNotEmpty) {
      _phoneController.text = userModel.phoneNumber;
    }

    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingLG),
          
          // Email Section
          _ContactField(
            icon: Iconsax.sms,
            label: 'Email Address',
            value: userModel.email,
            controller: _emailController,
            isEditing: _isEditingEmail,
            validator: Validators.validateEmail,
            onEdit: () => setState(() => _isEditingEmail = true),
            onSave: () => _saveEmail(userModel),
            onCancel: () {
              setState(() {
                _isEditingEmail = false;
                _emailController.text = userModel.email;
              });
            },
          ),
          
          SizedBox(height: AppConstants.spacingLG),
          
          // Phone Section
          _ContactField(
            icon: Iconsax.call,
            label: 'Phone Number',
            value: userModel.phoneNumber,
            controller: _phoneController,
            isEditing: _isEditingPhone,
            validator: Validators.validatePhoneNumber,
            keyboardType: TextInputType.phone,
            onEdit: () => setState(() => _isEditingPhone = true),
            onSave: () => _savePhone(userModel),
            onCancel: () {
              setState(() {
                _isEditingPhone = false;
                _phoneController.text = userModel.phoneNumber;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _OccupantSection() {
    return Consumer(
      builder: (context, ref, child) {
        final activeOccupantsAsync = ref.watch(activeOccupantsProvider);
        final pendingOccupantsAsync = ref.watch(pendingOccupantsProvider);
        
        return activeOccupantsAsync.when(
          data: (activeOccupants) => pendingOccupantsAsync.when(
            data: (pendingOccupants) => _OccupantContent(
              activeOccupants: activeOccupants, 
              pendingOccupants: pendingOccupants
            ),
            loading: () => _OccupantLoading(),
            error: (error, stack) => _OccupantError(error: error.toString()),
          ),
          loading: () => _OccupantLoading(),
          error: (error, stack) => _OccupantError(error: error.toString()),
        );
      },
    );
  }

  Widget _OccupantContent({
    required List<OccupantModel> activeOccupants, 
    required List<OccupantModel> pendingOccupants
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occupant Information',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              IconButton(
                onPressed: () => _handleAddOccupantAction(activeOccupants),
                icon: Icon(
                  Iconsax.add_circle,
                  color: context.colorScheme.primary,
                  size: 24,
                ),
                tooltip: activeOccupants.isEmpty ? 'Add Occupant' : 'Add Another Occupant',
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'Add details of anyone living with you',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.7),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingLG),
          
          if (activeOccupants.isNotEmpty)
            Column(
              children: activeOccupants.asMap().entries.map((entry) {
                int index = entry.key;
                OccupantModel occupant = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < activeOccupants.length - 1 ? AppConstants.spacingMD : 0,
                  ),
                  child: _OccupantCard(
                    occupant: occupant,
                    onEdit: () => _editOccupant(index, occupant),
                    onRemove: () => _removeOccupant(occupant),
                  ),
                );
              }).toList(),
            )
          else
            _EmptyOccupantState(),

          // Show pending occupants if any
          if (pendingOccupants.isNotEmpty) ...[
            SizedBox(height: AppConstants.spacingLG),
            _PendingOccupantsSection(pendingOccupants: pendingOccupants),
          ],
          
          // Permanent Admin Test Controls
          SizedBox(height: AppConstants.spacingLG),
        ],
      ),
    );
  }

  Widget _OccupantCard({
    required OccupantModel occupant,
    required VoidCallback onEdit,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: context.radiusMD,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [

              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occupant.occupantName,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Text(
                      occupant.occupantPhone,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha:0.7),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'remove') {
                    onRemove();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Iconsax.edit, size: 16),
                        SizedBox(width: AppConstants.spacingXS),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash, size: 16, color: context.colorScheme.error),
                        SizedBox(width: AppConstants.spacingXS),
                        Text('Remove', style: TextStyle(color: context.colorScheme.error)),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Iconsax.more,
                  color: context.colorScheme.onSurface.withValues(alpha:0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to determine add occupant action
  void _handleAddOccupantAction(List<OccupantModel> occupants) {
    if (occupants.isEmpty) {
      // If no occupants exist, show dialog directly
      _showAddOccupantDialog();
    } else {
      // If occupants exist, show warning first then proceed to add with PENDING status
      _showAddAnotherOccupantWarning();
    }
  }

  Widget _PendingOccupantsSection({required List<OccupantModel> pendingOccupants}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.clock,
              color: Colors.orange,
              size: 20,
            ),
            SizedBox(width: AppConstants.spacingXS),
            Text(
              'Pending Approval (${pendingOccupants.length})',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacingSM),
        Text(
          'These occupants are waiting for admin approval',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingMD),
        Column(
          children: pendingOccupants.asMap().entries.map((entry) {
            int index = entry.key;
            OccupantModel occupant = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < pendingOccupants.length - 1 ? AppConstants.spacingMD : 0,
              ),
              child: _PendingOccupantCard(occupant: occupant),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _PendingOccupantCard({required OccupantModel occupant}) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: context.radiusMD,
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: AppConstants.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occupant.occupantName,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(height: AppConstants.spacingXS / 2),
                Text(
                  occupant.occupantPhone,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(height: AppConstants.spacingXS / 2),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingXS,
                    vertical: AppConstants.spacingXS / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: context.radiusSM,
                  ),
                  child: Text(
                    'PENDING',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.clock,
            color: Colors.orange.withValues(alpha: 0.6),
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showAddOccupantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusLG,
        ),
        title: Text(
          _editingOccupant != null ? 'Edit Occupant' : 'Add Occupant',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: context.textTheme.titleLarge?.fontSize,
          ),
        ),
        content: Form(
          key: _occupantFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show status indicator for existing occupants
              if (_editingOccupant != null && _editingOccupant!.status == OccupantStatus.pending) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppConstants.spacingSM),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: context.radiusSM,
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: AppConstants.spacingXS),
                      Text(
                        'This occupant is pending approval',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppConstants.spacingMD),
              ],
              TextFormField(
                controller: _occupantNameController,
                validator: (value) => Validators.validateEmptyText('Name', value),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(
                    fontSize: context.textTheme.bodyMedium?.fontSize,
                    fontFamily: 'Montserrat',
                  ),
                  prefixIcon: Icon(Iconsax.user),
                  border: OutlineInputBorder(
                    borderRadius: context.radiusMD,
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: AppConstants.spacingMD),
              TextFormField(
                controller: _occupantPhoneController,
                validator: Validators.validatePhoneNumber,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(
                    fontSize: context.textTheme.bodyMedium?.fontSize,
                    fontFamily: 'Montserrat',
                  ),
                  prefixIcon: Icon(Iconsax.call),
                  border: OutlineInputBorder(
                    borderRadius: context.radiusMD,
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelAddOccupant();
            },
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_occupantFormKey.currentState!.validate()) {
                Navigator.of(context).pop();
                _saveOccupant();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: context.colorScheme.onPrimary,
            ),
            child: Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _EmptyOccupantState() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingXL),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer.withValues(alpha:0.5),
        borderRadius: context.radiusMD,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.user_add,
            size: 48,
            color: context.colorScheme.onSurface.withValues(alpha:0.4),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'No occupant added',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.6),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            'Tap the Add button to include someone living with you',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.5),
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _saveEmail(UserModel userModel) async {
    if (!_formKey.currentState!.validate()) {
      Loaders.errorSnackBar(
        context,
        title: 'Validation Error',
        message: 'Please check your email format',
      );
      return;
    }

    HapticFeedback.lightImpact();
    
    try {
      final profileNotifier = ref.read(userProfileNotifierProvider.notifier);
      await profileNotifier.updateProfileField({'email': _emailController.text});
      
      setState(() {
        _isEditingEmail = false;
      });

      Loaders.successSnackBar(
        context,
        title: 'Email Updated',
        message: 'Your email address has been successfully updated',
      );
    } catch (e) {
      Loaders.errorSnackBar(
        context,
        title: 'Update Failed',
        message: 'Failed to update email: ${e.toString()}',
      );
      
      // Reset the controller to the original value
      _emailController.text = userModel.email;
    }
  }

  Future<void> _savePhone(UserModel userModel) async {
    if (!_formKey.currentState!.validate()) {
      Loaders.errorSnackBar(
        context,
        title: 'Validation Error',
        message: 'Please check your phone number format',
      );
      return;
    }

    HapticFeedback.lightImpact();
    
    try {
      final profileNotifier = ref.read(userProfileNotifierProvider.notifier);
      await profileNotifier.updateProfileField({'phoneNumber': _phoneController.text});
      
      setState(() {
        _isEditingPhone = false;
      });

      Loaders.successSnackBar(
        context,
        title: 'Phone Updated',
        message: 'Your phone number has been successfully updated',
      );
    } catch (e) {
      Loaders.errorSnackBar(
        context,
        title: 'Update Failed',
        message: 'Failed to update phone: ${e.toString()}',
      );
      
      // Reset the controller to the original value
      _phoneController.text = userModel.phoneNumber;
    }
  }

  Future<void> _saveOccupant() async {
    HapticFeedback.lightImpact();
    
    try {
      final occupantsNotifier = ref.read(occupantsNotifierProvider.notifier);
      final newOccupant = OccupantModel(
        occupantName: _occupantNameController.text,
        occupantPhone: _occupantPhoneController.text,
        // Preserve the original status when editing, or use default for new occupants
        status: _editingOccupant?.status ?? OccupantStatus.active,
      );
      
      if (_editingOccupant != null) {
        // If editing, update existing occupant while preserving status
        await occupantsNotifier.updateOccupant(_editingOccupant!.id!, newOccupant);
        
        Loaders.successSnackBar(
          context,
          title: 'Occupant Updated',
          message: 'Occupant information has been successfully saved',
        );
        _editingOccupant = null;
      } else {
        // Add new occupant (status will be determined automatically in the provider)
        await occupantsNotifier.addOccupant(newOccupant);
        
        Loaders.successSnackBar(
          context,
          title: 'Occupant Added',
          message: 'Occupant information has been successfully saved',
        );
      }
      
      _occupantNameController.clear();
      _occupantPhoneController.clear();
    } catch (e) {
      Loaders.errorSnackBar(
        context,
        title: 'Save Failed',
        message: 'Failed to save occupant: ${e.toString()}',
      );
    }
  }

  void _editOccupant(int index, OccupantModel occupant) {
    setState(() {
      _occupantNameController.text = occupant.occupantName;
      _occupantPhoneController.text = occupant.occupantPhone;
      _editingOccupant = occupant;
    });
    _showAddOccupantDialog();
  }

  Future<void> _removeOccupant(OccupantModel occupant) async {
    HapticFeedback.mediumImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Remove Occupant',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${occupant.occupantName}?',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    // Only proceed if user confirmed and widget is still mounted
    if (confirmed == true && mounted) {
      try {
        final occupantsNotifier = ref.read(occupantsNotifierProvider.notifier);
        
        // Soft delete: Mark as DELETED instead of hard delete
        final deletedOccupant = occupant.copyWith(status: OccupantStatus.deleted);
        await occupantsNotifier.updateOccupant(occupant.id!, deletedOccupant);
        
        // Add a small delay to ensure the UI is stable before showing SnackBar
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (mounted) {
            Loaders.successSnackBar(
              context,
              title: 'Occupant Removed',
              message: 'Occupant information has been removed',
            );
          }
        }
      } catch (e) {
        // Check if widget is still mounted before showing error
        if (mounted) {
          Loaders.errorSnackBar(
            context,
            title: 'Remove Failed',
            message: 'Failed to remove occupant: ${e.toString()}',
          );
        }
      }
    }
  }

  void _cancelAddOccupant() {
    setState(() {
      _editingOccupant = null;
      _occupantNameController.clear();
      _occupantPhoneController.clear();
    });
  }

  void _showAddAnotherOccupantWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusLG,
        ),
        title: Row(
          children: [
            Icon(
              Iconsax.warning_2,
              color: context.colorScheme.error,
              size: 24,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Expanded(
              child: Text(
                'Additional Occupant',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: context.textTheme.titleLarge?.fontSize,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              decoration: BoxDecoration(
                color: context.colorScheme.errorContainer.withValues(alpha:0.3),
                borderRadius: context.radiusSM,
                border: Border.all(
                  color: context.colorScheme.error.withValues(alpha:0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Charges:',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.error,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingXS),
                  Text(
                    '• ₱500 additional on deposits',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  Text(
                    '• ₱500 monthly rent increase',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            Text(
              'We recommend speaking with the admins first before proceeding with this request.',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: context.colorScheme.onSurface.withValues(alpha:0.8),
              ),
            ),
            SizedBox(height: AppConstants.spacingSM),
            Text(
              'Do you want to proceed?',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: context.colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _showAddOccupantDialog(); // Directly show the add occupant dialog
            },
            child: Text(
              'Proceed',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateAdminApprove() async {
    HapticFeedback.mediumImpact();
    
    try {
      // Get current pending occupants
      final pendingOccupantsAsync = ref.read(pendingOccupantsProvider);
      
      await pendingOccupantsAsync.when(
        data: (pendingOccupants) async {
          if (pendingOccupants.isNotEmpty) {
            final firstPending = pendingOccupants.first;
            
            await ref.read(occupantsNotifierProvider.notifier).approveOccupant(firstPending.id!);
            
            if (mounted) {
              Loaders.successSnackBar(
                context,
                title: 'Occupant Approved',
                message: '${firstPending.occupantName} has been approved and is now active.',
              );
            }
          } else {
            if (mounted) {
              Loaders.infoSnackBar(
                context,
                title: 'No Pending Requests',
                message: 'There are no pending occupant requests to approve.',
              );
            }
          }
        },
        loading: () async {
          if (mounted) {
            Loaders.infoSnackBar(
              context,
              title: 'Loading...',
              message: 'Loading pending occupants...',
            );
          }
        },
        error: (error, stack) async {
          if (mounted) {
            Loaders.errorSnackBar(
              context,
              title: 'Error',
              message: 'Failed to load pending occupants: ${error.toString()}',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Approval Failed',
          message: 'Failed to approve occupant: ${e.toString()}',
        );
      }
    }
  }

  void _simulateAdminReject() async {
    HapticFeedback.mediumImpact();
    
    try {
      // Get current pending occupants
      final pendingOccupantsAsync = ref.read(pendingOccupantsProvider);
      
      await pendingOccupantsAsync.when(
        data: (pendingOccupants) async {
          if (pendingOccupants.isNotEmpty) {
            final firstPending = pendingOccupants.first;
            
            await ref.read(occupantsNotifierProvider.notifier).rejectOccupant(firstPending.id!);
            
            if (mounted) {
              Loaders.errorSnackBar(
                context,
                title: 'Occupant Rejected',
                message: '${firstPending.occupantName} request has been rejected.',
              );
            }
          } else {
            if (mounted) {
              Loaders.infoSnackBar(
                context,
                title: 'No Pending Requests',
                message: 'There are no pending occupant requests to reject.',
              );
            }
          }
        },
        loading: () async {
          if (mounted) {
            Loaders.infoSnackBar(
              context,
              title: 'Loading...',
              message: 'Loading pending occupants...',
            );
          }
        },
        error: (error, stack) async {
          if (mounted) {
            Loaders.errorSnackBar(
              context,
              title: 'Error',
              message: 'Failed to load pending occupants: ${error.toString()}',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Rejection Failed',
          message: 'Failed to reject occupant: ${e.toString()}',
        );
      }
    }
  }
}

// Contact Field Widget
class _ContactField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextEditingController controller;
  final bool isEditing;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ContactField({
    required this.icon,
    required this.label,
    required this.value,
    required this.controller,
    required this.isEditing,
    required this.validator,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: context.radiusMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: context.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: AppConstants.spacingXS),
              Text(
                label,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          
          if (isEditing) ...[
            TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: context.textTheme.bodyMedium?.fontSize,
                fontFamily: 'Montserrat',
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: context.radiusSM,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSM,
                  vertical: AppConstants.spacingSM,
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: AppConstants.spacingMD),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: AppConstants.spacingSM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: context.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                    ),
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Iconsax.edit,
                    color: context.colorScheme.primary,
                    size: 20,
                  ),
                  tooltip: 'Edit $label',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Loading and Error State Widgets
class _ContactInformationLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingLG),
          
          // Loading fields
          for (int i = 0; i < 2; i++) ...[
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                borderRadius: context.radiusMD,
              ),
            ),
            if (i < 1) SizedBox(height: AppConstants.spacingLG),
          ],
        ],
      ),
    );
  }
}

class _ContactInformationError extends StatelessWidget {
  final String error;
  
  const _ContactInformationError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.error.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.warning_2,
            color: context.colorScheme.error,
            size: 30,
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'Failed to load contact information',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            error.length > 50 ? '${error.substring(0, 50)}...' : error,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupantLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Occupant Information',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingLG),
          
          // Loading occupant cards
          for (int i = 0; i < 2; i++) ...[
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                borderRadius: context.radiusMD,
              ),
            ),
            if (i < 1) SizedBox(height: AppConstants.spacingMD),
          ],
        ],
      ),
    );
  }
}

class _OccupantError extends StatelessWidget {
  final String error;
  
  const _OccupantError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.error.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.warning_2,
            color: context.colorScheme.error,
            size: 30,
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'Failed to load occupants',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            error.length > 50 ? '${error.substring(0, 50)}...' : error,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
