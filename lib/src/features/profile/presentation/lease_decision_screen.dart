import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/snackbars/loaders.dart';
import '../../profile/domain/lease_analytics_model.dart';

class LeaseDecisionScreen extends ConsumerStatefulWidget {
  const LeaseDecisionScreen({super.key});

  @override
  ConsumerState<LeaseDecisionScreen> createState() => _LeaseDecisionScreenState();
}

class _LeaseDecisionScreenState extends ConsumerState<LeaseDecisionScreen> {
  DateTime? _leaseEndDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaseEndDate();
  }

  Future<void> _loadLeaseEndDate() async {
    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId != null) {
        final leaseEndDate = await UserRepository.instance.getLeaseEndDate(userId);
        if (mounted) {
          setState(() {
            _leaseEndDate = leaseEndDate;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToRenewForm() async {
    HapticFeedback.lightImpact();
    
    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) {
        Loaders.errorSnackBar(
          context,
          title: 'Authentication Error',
          message: 'User not authenticated',
        );
        return;
      }

      // Check if already submitted
      final hasSubmitted = await UserRepository.instance.hasSubmittedLeaseDecision(userId);
      if (hasSubmitted) {
        if (mounted) {
          Loaders.warningSnackBar(
            context,
            title: 'Decision Already Submitted',
            message: 'You have already submitted a lease decision. Please contact management if you need to make changes.',
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RenewLeaseForm()),
        );
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to check lease status: $e',
        );
      }
    }
  }

  Future<void> _navigateToMoveOutForm() async {
    HapticFeedback.lightImpact();
    
    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) {
        Loaders.errorSnackBar(
          context,
          title: 'Authentication Error',
          message: 'User not authenticated',
        );
        return;
      }

      // Check if already submitted
      final hasSubmitted = await UserRepository.instance.hasSubmittedLeaseDecision(userId);
      if (hasSubmitted) {
        if (mounted) {
          Loaders.warningSnackBar(
            context,
            title: 'Decision Already Submitted',
            message: 'You have already submitted a lease decision. Please contact management if you need to make changes.',
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoveOutForm()),
        );
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to check lease status: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lease Decision',
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
      body: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLG.toDouble()),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: context.colorScheme.primary,
                ),
              )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(AppConstants.spacingXL.toDouble()),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.home,
                size: 60,
                color: context.colorScheme.primary,
              ),
            ),
            SizedBox(height: AppConstants.spacingXL.toDouble()),
      
            Text(
              'What would you like to do?',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacingSM.toDouble()),
            Text(
              'Please select one of the options below to proceed with your lease decision.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacingXL.toDouble() * 1),

                 
            // Display lease end date
            if (_leaseEndDate != null) ...[
              Center(
                child: Container(
                  padding: EdgeInsets.all(AppConstants.spacingMD.toDouble()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.calendar,
                        size: 20,
                      ),
                      SizedBox(width: AppConstants.spacingSM.toDouble()),
                      Text(
                        'Target Move-Out Date:  ${_leaseEndDate!.month}/${_leaseEndDate!.day}/${_leaseEndDate!.year}',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      SizedBox(width: AppConstants.spacingSM.toDouble()),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppConstants.spacingXL.toDouble() * 1),
            ],
            
            
            // Renew Lease Button
            ElevatedButton(
              onPressed: _navigateToRenewForm,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMD.toDouble()),
                backgroundColor: context.colorScheme.primary,
                foregroundColor: context.colorScheme.onPrimary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: context.radiusLG,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.refresh, size: 24),
                  SizedBox(width: AppConstants.spacingSM.toDouble()),
                  Text(
                    'Renew My Lease',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: AppConstants.spacingMD.toDouble()),
            
            // Move Out Button
            OutlinedButton(
              onPressed: _navigateToMoveOutForm,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMD.toDouble()),
                side: BorderSide(
                  color: context.colorScheme.error,
                  width: 2.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: context.radiusLG,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.logout,
                    size: 24,
                    color: context.colorScheme.error,
                  ),
                  SizedBox(width: AppConstants.spacingSM.toDouble()),
                  Text(
                    'I Want to Move Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      color: context.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Form for renewing lease
class RenewLeaseForm extends StatefulWidget {
  const RenewLeaseForm({super.key});

  @override
  State<RenewLeaseForm> createState() => _RenewLeaseFormState();
}

class _RenewLeaseFormState extends State<RenewLeaseForm> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedMonths;
  RenewalReason? _selectedReason;
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        title: Row(
          children: [
            Icon(
              isDestructive ? Iconsax.warning_2 : Iconsax.info_circle,
              color: isDestructive 
                  ? Theme.of(dialogContext).colorScheme.error 
                  : Theme.of(dialogContext).colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: AppConstants.spacingSM.toDouble()),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive 
                  ? Theme.of(dialogContext).colorScheme.error 
                  : Theme.of(dialogContext).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              confirmText,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRenewal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMonths == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Selection Required',
        message: 'Please select renewal duration',
      );
      return;
    }
    if (_selectedReason == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Selection Required',
        message: 'Please select a reason for renewal',
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      title: 'Confirm Renewal',
      message: 'Are you sure you want to renew your lease for $_selectedMonths months? This decision cannot be changed later.',
      confirmText: 'Yes, Renew',
      isDestructive: false,
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get lease end date
      final leaseEndDate = await UserRepository.instance.getLeaseEndDate(userId);
      if (leaseEndDate == null) throw Exception('Lease information not found');

      // Create analytics record
      await UserRepository.instance.createLeaseAnalytics(
        tenantId: userId,
        decisionType: 'renew',
        previousLeaseEndDate: leaseEndDate,
        renewalMonths: _selectedMonths,
        primaryReasonCategory: _selectedReason!.code,
        feedbackNote: _feedbackController.text.trim().isEmpty 
            ? null 
            : _feedbackController.text.trim(),
      );

      // Update renewal options
      await UserRepository.instance.updateLeaseRenewalOptions(
        userId: userId,
        renewalOptions: _selectedMonths!,
      );

      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Renewal Submitted',
          message: 'Your lease renewal request has been submitted successfully.',
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to submit renewal: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Renew Lease',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppConstants.spacingLG.toDouble()),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppConstants.spacingSM.toDouble()),
              Text(
                'Renewal Duration',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: AppConstants.spacingMD.toDouble()),
              
              // Duration selection
              ...[3, 6, 9].map((months) => RadioListTile<int>(
                title: Text(
                  '$months Months',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                value: months,
                groupValue: _selectedMonths,
                onChanged: (value) => setState(() => _selectedMonths = value),
                activeColor: context.colorScheme.primary,
              )),
              
              SizedBox(height: AppConstants.spacingLG.toDouble()),
              
              Text(
                'Why are you renewing?',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: AppConstants.spacingMD.toDouble()),
              
              // Reason dropdown
              DropdownButtonFormField<RenewalReason>(
                decoration: InputDecoration(
                  labelText: 'Select Reason',
                  labelStyle: TextStyle(fontFamily: 'Montserrat'),
                  prefixIcon: Icon(Iconsax.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    borderSide: BorderSide(
                      color: context.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    borderSide: BorderSide(
                      color: context.colorScheme.outline.withValues(alpha: 0.5),
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
                value: _selectedReason,
                items: RenewalReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(
                      reason.label,
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedReason = value),
                validator: (value) =>
                    value == null ? 'Please select a reason' : null,
              ),
              
              SizedBox(height: AppConstants.spacingLG.toDouble()),
              
              Text(
                'Additional Feedback (Optional)',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: AppConstants.spacingMD.toDouble()),
              
              // Feedback text field
              TextFormField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  labelText: 'Your feedback',
                  labelStyle: TextStyle(fontFamily: 'Montserrat'),
                  hintText: 'Tell us more about your decision...',
                  hintStyle: TextStyle(fontFamily: 'Montserrat'),
                  prefixIcon: Icon(Iconsax.message_text),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    borderSide: BorderSide(
                      color: context.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    borderSide: BorderSide(
                      color: context.colorScheme.outline.withValues(alpha: 0.5),
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
                style: TextStyle(fontFamily: 'Montserrat'),
                maxLines: 4,
              ),
              
              SizedBox(height: AppConstants.spacingXL.toDouble()),
              
              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRenewal,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMD.toDouble()),
                  backgroundColor: context.colorScheme.primary,
                  foregroundColor: context.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: context.radiusLG,
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        'Submit Renewal Request',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                      ),
              ),
              SizedBox(height: AppConstants.spacingLG.toDouble()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form for move-out decision
class MoveOutForm extends StatefulWidget {
  const MoveOutForm({super.key});

  @override
  State<MoveOutForm> createState() => _MoveOutFormState();
}

class _MoveOutFormState extends State<MoveOutForm> {
  final _formKey = GlobalKey<FormState>();
  MoveOutReason? _selectedReason;
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required bool isDestructive,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        title: Row(
          children: [
            Icon(
              isDestructive ? Iconsax.warning_2 : Iconsax.info_circle,
              color: isDestructive 
                  ? Theme.of(dialogContext).colorScheme.error 
                  : Theme.of(dialogContext).colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: AppConstants.spacingSM.toDouble()),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive 
                  ? Theme.of(dialogContext).colorScheme.error 
                  : Theme.of(dialogContext).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              confirmText,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitMoveOut() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReason == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Selection Required',
        message: 'Please select a reason for moving out',
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      title: 'Confirm Move-Out',
      message: 'Are you sure you want to move out? This decision cannot be changed later and will notify management.',
      confirmText: 'Yes, Move Out',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = AuthRepository.instance.authUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get lease end date
      final leaseEndDate = await UserRepository.instance.getLeaseEndDate(userId);
      if (leaseEndDate == null) throw Exception('Lease information not found');

      // Create analytics record
      await UserRepository.instance.createLeaseAnalytics(
        tenantId: userId,
        decisionType: 'move_out',
        previousLeaseEndDate: leaseEndDate,
        renewalMonths: null,
        primaryReasonCategory: _selectedReason!.code,
        feedbackNote: _feedbackController.text.trim().isEmpty 
            ? null 
            : _feedbackController.text.trim(),
      );

      // Update renewal options to 0 (move-out)
      await UserRepository.instance.updateLeaseRenewalOptions(
        userId: userId,
        renewalOptions: 0,
      );

      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Move-Out Submitted',
          message: 'Your move-out request has been submitted successfully.',
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to submit move-out: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Move Out',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppConstants.spacingLG.toDouble()),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppConstants.spacingSM.toDouble()),
              Text(
                'Why are you moving out?',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: AppConstants.spacingMD.toDouble()),
              
              // Reason dropdown
              DropdownButtonFormField<MoveOutReason>(
                decoration: InputDecoration(
                  labelText: 'Select Reason',
                  labelStyle: TextStyle(fontFamily: 'Montserrat'),
                  prefixIcon: Icon(Iconsax.tag),
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
                value: _selectedReason,
                items: MoveOutReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(
                      reason.label,
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedReason = value),
                validator: (value) => value == null ? 'Please select a reason' : null,
              ),
              
              SizedBox(height: AppConstants.spacingLG.toDouble()),
              
              Text(
                'Additional Feedback (Optional)',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: AppConstants.spacingMD.toDouble()),
              
              // Feedback text field
              TextFormField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  labelText: 'Your feedback',
                  labelStyle: TextStyle(fontFamily: 'Montserrat'),
                  hintText: 'Tell us more about your decision...',
                  hintStyle: TextStyle(fontFamily: 'Montserrat',
                  fontSize: context.textTheme.bodyMedium?.fontSize,),
                  prefixIcon: Icon(
                    Iconsax.message_text,
                  color: context.colorScheme.onSurface.withValues(alpha:0.6)
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
                style: TextStyle(fontFamily: 'Montserrat'),
                maxLines: 4,
              ),
              
              SizedBox(height: AppConstants.spacingXL.toDouble()),
              
              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMoveOut,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMD.toDouble()),
                  backgroundColor: context.colorScheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: context.radiusLG,
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Submit Move-Out Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
              ),
              SizedBox(height: AppConstants.spacingLG.toDouble()),
            ],
          ),
        ),
      ),
    );
  }
}
