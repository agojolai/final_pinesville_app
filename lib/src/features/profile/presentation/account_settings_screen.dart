import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/constants/validators.dart';
import '../../../core/snackbars/loaders.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool get _showAddOccupantButton => !_isWaitingForAdminApproval;

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
  bool _isWaitingForAdminApproval = false;
  bool _hasApprovedRequest = false; // Track if admin has approved adding another occupant
  List<Occupant> _occupants = [];
  Occupant? _editingOccupant;
  int? _editingOccupantIndex;

  // Sample current data
  String _currentEmail = 'caleb.anderson@email.com';
  String _currentPhone = '+63 912 345 6789';

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

    // Initialize controllers with current data
    _emailController.text = _currentEmail;
    _phoneController.text = _currentPhone;

    // Sample occupant data
    _occupants = [
      Occupant(
        name: 'Sarah Johnson',
        phoneNumber: '09171234567',
      ),
    ];
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
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withOpacity(0.08),
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
            value: _currentEmail,
            controller: _emailController,
            isEditing: _isEditingEmail,
            validator: Validators.validateEmail,
            onEdit: () => setState(() => _isEditingEmail = true),
            onSave: _saveEmail,
            onCancel: () {
              setState(() {
                _isEditingEmail = false;
                _emailController.text = _currentEmail;
              });
            },
          ),
          
          SizedBox(height: AppConstants.spacingLG),
          
          // Phone Section
          _ContactField(
            icon: Iconsax.call,
            label: 'Phone Number',
            value: _currentPhone,
            controller: _phoneController,
            isEditing: _isEditingPhone,
            validator: Validators.validatePhoneNumber,
            keyboardType: TextInputType.phone,
            onEdit: () => setState(() => _isEditingPhone = true),
            onSave: _savePhone,
            onCancel: () {
              setState(() {
                _isEditingPhone = false;
                _phoneController.text = _currentPhone;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _OccupantSection() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withOpacity(0.08),
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
              if (_showAddOccupantButton)
                IconButton(
                  onPressed: _handleAddOccupantAction,
                  icon: Icon(
                    Iconsax.add_circle,
                    color: context.colorScheme.primary,
                    size: 24,
                  ),
                  tooltip: _occupants.isEmpty ? 'Add Occupant' : 'Add Another Occupant',
                ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'Add details of anyone living with you',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.7),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingLG),
          
          if (_occupants.isNotEmpty)
            Column(
              children: _occupants.asMap().entries.map((entry) {
                int index = entry.key;
                Occupant occupant = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _occupants.length - 1 ? AppConstants.spacingMD : 0,
                  ),
                  child: _OccupantCard(
                    occupant: occupant,
                    onEdit: () => _editOccupant(index),
                    onRemove: () => _removeOccupant(index),
                  ),
                );
              }).toList(),
            )
          else
            _EmptyOccupantState(),
          
          // Permanent Admin Test Controls
          SizedBox(height: AppConstants.spacingLG),
          _PermanentAdminTestControls(),
        ],
      ),
    );
  }

  Widget _OccupantCard({
    required Occupant occupant,
    required VoidCallback onEdit,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: context.radiusMD,
        border: Border.all(
          color: context.colorScheme.primary.withOpacity(0.2),
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
                      occupant.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Text(
                      occupant.phoneNumber,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.7),
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
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to determine add occupant action
  void _handleAddOccupantAction() {
    if (_occupants.isEmpty || _hasApprovedRequest) {
      // If no occupants exist or admin has already approved, show dialog directly
      _showAddOccupantDialog();
    } else {
      // If occupants exist and no approval yet, show warning first
      _showAddAnotherOccupantWarning();
    }
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


  Widget _PermanentAdminTestControls() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: context.radiusSM,
        border: Border.all(
          color: context.colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '🛠️ Admin Test Controls',
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.error,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            'For testing purposes only',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.6),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _simulateAdminReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.error,
                    side: BorderSide(color: context.colorScheme.error),
                    padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                  ),
                  child: Text(
                    'Reject Request',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: ElevatedButton(
                  onPressed: _simulateAdminApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: context.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                  ),
                  child: Text(
                    'Approve Request',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _EmptyOccupantState() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingXL),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: context.radiusMD,
        border: Border.all(
          color: context.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.user_add,
            size: 48,
            color: context.colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'No occupant added',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.6),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            'Tap the Add button to include someone living with you',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.5),
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Action methods
  void _saveEmail() {
    if (!_formKey.currentState!.validate()) {
      Loaders.errorSnackBar(
        context,
        title: 'Validation Error',
        message: 'Please check your email format',
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _currentEmail = _emailController.text;
      _isEditingEmail = false;
    });

    Loaders.successSnackBar(
      context,
      title: 'Email Updated',
      message: 'Your email address has been successfully updated',
    );
  }

  void _savePhone() {
    if (!_formKey.currentState!.validate()) {
      Loaders.errorSnackBar(
        context,
        title: 'Validation Error',
        message: 'Please check your phone number format',
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _currentPhone = _phoneController.text;
      _isEditingPhone = false;
    });

    Loaders.successSnackBar(
      context,
      title: 'Phone Updated',
      message: 'Your phone number has been successfully updated',
    );
  }

  void _saveOccupant() {
    HapticFeedback.lightImpact();
    setState(() {
      final newOccupant = Occupant(
        name: _occupantNameController.text,
        phoneNumber: _occupantPhoneController.text,
      );
      if (_editingOccupantIndex != null) {
        // If editing, insert at the original index
        _occupants.insert(_editingOccupantIndex!, newOccupant);
        _editingOccupant = null;
        _editingOccupantIndex = null;
      } else {
        _occupants.add(newOccupant);
        // Reset approval flag when occupant is successfully added
        _hasApprovedRequest = false;
      }
      _occupantNameController.clear();
      _occupantPhoneController.clear();
    });

    Loaders.successSnackBar(
      context,
      title: 'Occupant Added',
      message: 'Occupant information has been successfully saved',
    );
  }

  void _editOccupant(int index) {
    setState(() {
      _occupantNameController.text = _occupants[index].name;
      _occupantPhoneController.text = _occupants[index].phoneNumber;
      _editingOccupant = _occupants[index];
      _editingOccupantIndex = index;
      // Remove the occupant being edited so it gets replaced when saved, otherwise it duplicates
      _occupants.removeAt(index);
    });
    _showAddOccupantDialog();
  }

  void _removeOccupant(int index) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Occupant',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${_occupants[index].name}?',
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
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _occupants.removeAt(index));
              Loaders.successSnackBar(
                context,
                title: 'Occupant Removed',
                message: 'Occupant information has been removed',
              );
            },
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _cancelAddOccupant() {
    setState(() {
      if (_editingOccupant != null && _editingOccupantIndex != null) {
        // Restore the occupant if editing was cancelled
        _occupants.insert(_editingOccupantIndex!, _editingOccupant!);
        _editingOccupant = null;
        _editingOccupantIndex = null;
      }
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
                color: context.colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: context.radiusSM,
                border: Border.all(
                  color: context.colorScheme.error.withOpacity(0.3),
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
                color: context.colorScheme.onSurface.withOpacity(0.8),
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
              _requestAdminApproval();
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

  void _requestAdminApproval() {
    HapticFeedback.lightImpact();
    setState(() {
      _isWaitingForAdminApproval = true;
    });

    Loaders.infoSnackBar(
      context,
      title: 'Request Sent',
      message: 'We will notify the admins, please wait',
    );
  }

  void _simulateAdminApprove() {
    HapticFeedback.mediumImpact();
    
    if (_isWaitingForAdminApproval) {
      // If waiting for approval, approve the request and allow adding
      setState(() {
        _isWaitingForAdminApproval = false;
        _hasApprovedRequest = true; // Set approval flag
      });

      Loaders.successSnackBar(
        context,
        title: 'Request Approved',
        message: 'Admin has approved your request. You can now add another occupant.',
      );
      
      // Show the add occupant dialog after approval
      _showAddOccupantDialog();
    } else {
      // If not waiting, just show test message
      Loaders.infoSnackBar(
        context,
        title: 'Admin Test',
        message: 'This would approve an occupant request when one is pending.',
      );
    }
  }

  void _simulateAdminReject() {
    HapticFeedback.mediumImpact();
    
    if (_isWaitingForAdminApproval) {
      // If waiting for approval, reject the request
      setState(() {
        _isWaitingForAdminApproval = false;
        _hasApprovedRequest = false; // Reset approval flag on rejection
      });

      Loaders.errorSnackBar(
        context,
        title: 'Request Rejected',
        message: 'Admin has rejected your request. Please contact them for more details.',
      );
    } else {
      // If not waiting, just show test message
      Loaders.infoSnackBar(
        context,
        title: 'Admin Test',
        message: 'This would reject an occupant request when one is pending.',
      );
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

// Data Models
class Occupant {
  final String name;
  final String phoneNumber;

  const Occupant({
    required this.name,
    required this.phoneNumber,
  });
}
