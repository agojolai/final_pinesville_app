import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../../../../core/snackbars/loaders.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../domain/lease_model.dart';
import '../../../../core/utils/app_logger.dart';

/// Dialog for admin to update lease information
class UpdateLeaseInfoDialog extends StatefulWidget {
  final UserModel tenant;

  const UpdateLeaseInfoDialog({
    super.key,
    required this.tenant,
  });

  @override
  State<UpdateLeaseInfoDialog> createState() => _UpdateLeaseInfoDialogState();
}

class _UpdateLeaseInfoDialogState extends State<UpdateLeaseInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for editable fields
  late TextEditingController _securityDepositController;
  
  // State variables
  DateTime? _leaseStartDate;
  int? _monthsBasedOnContract;
  DateTime? _calculatedEndDate;
  File? _selectedPdf;
  String? _pdfFileName;
  bool _isLoading = true;
  bool _isSubmitting = false;
  LeaseModel? _existingLease;

  final List<int> _contractMonthsOptions = [6, 9, 12];

  @override
  void initState() {
    super.initState();
    AppLogger.info('UpdateLeaseInfoDialog initialized for tenant: ${widget.tenant.fullName}');
    AppLogger.info('Tenant ID: ${widget.tenant.id}');
    AppLogger.info('Tenant move-in date: ${widget.tenant.moveInDate}');
    AppLogger.info('Tenant property: ${widget.tenant.propertyName}');
    AppLogger.info('Tenant rent amount: ${widget.tenant.rentAmount}');
    
    _securityDepositController = TextEditingController(
      text: widget.tenant.rentAmount.toStringAsFixed(2),
    );
    _loadExistingLease();
  }

  @override
  void dispose() {
    _securityDepositController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLease() async {
    try {
      AppLogger.info('Attempting to fetch existing lease for tenant ID: ${widget.tenant.id}');
      final lease = await UserRepository.instance.fetchUserLease(widget.tenant.id!);
      
      if (lease != null) {
        AppLogger.info('Existing lease found: ${lease.leaseId}');
        AppLogger.info('Lease start date: ${lease.leaseStartDate}');
        AppLogger.info('Lease end date: ${lease.leaseEndDate}');
        AppLogger.info('Contract months: ${lease.monthsBasedOnContract}');
      } else {
        AppLogger.info('No existing lease found - will create new lease');
        AppLogger.info('Using tenant move-in date: ${widget.tenant.moveInDate}');
      }
      
      if (mounted) {
        setState(() {
          _existingLease = lease;
          if (lease != null) {
            _leaseStartDate = lease.leaseStartDate;
            _monthsBasedOnContract = lease.monthsBasedOnContract;
            _calculatedEndDate = lease.leaseEndDate;
            _securityDepositController.text = lease.securityDeposit.toStringAsFixed(2);
            _pdfFileName = lease.pdfDocumentName;
            AppLogger.info('Loaded existing lease data into form');
          } else {
            // Pre-fill with user's move-in date if no existing lease
            _leaseStartDate = widget.tenant.moveInDate;
            AppLogger.info('Set lease start date from move-in date: $_leaseStartDate');
            // Auto-calculate if we have a start date
            if (_leaseStartDate != null && _monthsBasedOnContract != null) {
              _calculateEndDate();
              AppLogger.info('Auto-calculated end date: $_calculatedEndDate');
            } else {
              AppLogger.warning('Cannot auto-calculate end date - start date: $_leaseStartDate, months: $_monthsBasedOnContract');
            }
          }
          _isLoading = false;
          AppLogger.info('Lease loading completed');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading existing lease', e, stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to load existing lease: $e',
        );
      }
    }
  }

  void _calculateEndDate() {
    if (_leaseStartDate != null && _monthsBasedOnContract != null) {
      setState(() {
        _calculatedEndDate = DateTime(
          _leaseStartDate!.year,
          _leaseStartDate!.month + _monthsBasedOnContract!,
          _leaseStartDate!.day,
        );
      });
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      AppLogger.info('Opening file picker for PDF selection');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPdf = File(result.files.single.path!);
          _pdfFileName = result.files.single.name;
        });
      }
    } catch (e) {
      Loaders.errorSnackBar(
        context,
        title: 'Error',
        message: 'Failed to pick PDF file: $e',
      );
    }
  }

  Future<void> _submitLeaseInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    // When updating existing lease, only validate end date
    if (_existingLease != null) {
      if (_calculatedEndDate == null) {
        Loaders.errorSnackBar(
          context,
          title: 'Required Field',
          message: 'Please select a lease end date',
        );
        return;
      }
    } else {
      // When creating new lease, validate all required fields
      if (_leaseStartDate == null) {
        Loaders.errorSnackBar(
          context,
          title: 'Required Field',
          message: 'Please select a lease start date',
        );
        return;
      }

      if (_monthsBasedOnContract == null) {
        Loaders.errorSnackBar(
          context,
          title: 'Required Field',
          message: 'Please select contract duration',
        );
        return;
      }

      if (_selectedPdf == null) {
        Loaders.errorSnackBar(
          context,
          title: 'Required Field',
          message: 'Please upload a lease agreement PDF',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // Create lease model
      final LeaseModel lease;
      
      if (_existingLease != null) {
        // UPDATING existing lease: Only update leaseEndDate and renewalOptions
        AppLogger.info('Updating existing lease - preserving all fields except leaseEndDate and renewalOptions');
        lease = _existingLease!.copyWith(
          leaseEndDate: _calculatedEndDate!,
          resetRenewalOptions: true, // Explicitly reset renewalOptions to null
        );
      } else {
        // CREATING new lease: Upload PDF and populate all fields
        AppLogger.info('Creating new lease - all fields required');
        
        String pdfUrl = '';
        String pdfName = '';

        // Upload new PDF (required for new lease)
        if (_selectedPdf != null) {
          pdfUrl = await UserRepository.instance.uploadLeaseContract(
            userId: widget.tenant.id!,
            pdfFile: _selectedPdf!,
            fileName: _pdfFileName!,
          );
          pdfName = _pdfFileName!;
        }

        lease = LeaseModel(
          leaseId: null,
          createdAt: DateTime.now(),
          currentTenantId: widget.tenant.id!,
          leaseEndDate: _calculatedEndDate!,
          leaseStartDate: _leaseStartDate!,
          monthsBasedOnContract: _monthsBasedOnContract!,
          pdfDocumentName: pdfName,
          pdfDocumentUrl: pdfUrl,
          propertyId: widget.tenant.propertyId,
          propertyName: widget.tenant.propertyName,
          rentAmount: widget.tenant.rentAmount,
          renewalOptions: null,
          securityDeposit: double.parse(_securityDepositController.text),
          tenantName: widget.tenant.fullName,
          unitId: widget.tenant.unitId,
        );
      }

      // Save to Firestore
      await UserRepository.instance.createOrUpdateLease(
        userId: widget.tenant.id!,
        lease: lease,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        Loaders.successSnackBar(
          context,
          title: 'Success',
          message: _existingLease != null 
              ? 'Lease end date updated successfully'
              : 'Lease information created successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to update lease: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppConstants.spacingLG),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusLG),
                  topRight: Radius.circular(AppConstants.radiusLG),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.document_text,
                    color: context.colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: AppConstants.spacingSM),
                  Expanded(
                    child: Text(
                      'Update Lease Information',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Iconsax.close_square),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(AppConstants.spacingLG),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Pre-filled tenant info
                            _buildInfoSection(),
                            SizedBox(height: AppConstants.spacingLG),

                            // Lease Start Date
                            _buildDateField(),
                            SizedBox(height: AppConstants.spacingMD),

                            // Contract Duration
                            _buildContractDurationField(),
                            SizedBox(height: AppConstants.spacingMD),

                            // Renewal Options (only for existing leases)
                            _buildRenewalOptionsField(),
                            if (_existingLease != null) SizedBox(height: AppConstants.spacingMD),

                            // Editable Lease End Date
                            _buildEditableEndDateField(),
                            SizedBox(height: AppConstants.spacingMD),

                            // Security Deposit
                            _buildSecurityDepositField(),
                            SizedBox(height: AppConstants.spacingMD),

                            // PDF Upload
                            _buildPdfUploadSection(),
                            SizedBox(height: AppConstants.spacingXL),

                            // Submit Button
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitLeaseInfo,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppConstants.spacingMD,
                                ),
                                backgroundColor: context.colorScheme.primary,
                                foregroundColor: context.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
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
                                      _existingLease != null
                                          ? 'Update Lease Information'
                                          : 'Create Lease Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tenant Information',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.primary,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          _buildReadOnlyRow('Tenant Name', widget.tenant.fullName),
          _buildReadOnlyRow('Property', widget.tenant.propertyName),
          _buildReadOnlyRow('Rent Amount', '\₱${widget.tenant.rentAmount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              fontFamily: 'Montserrat',
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Lease Start Date',
        labelStyle: TextStyle(fontFamily: 'Montserrat'),
        prefixIcon: Icon(Iconsax.calendar),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        filled: true,
        fillColor: context.colorScheme.surfaceVariant.withValues(alpha: 0.3),
    
      ),
      child: Text(
        _leaseStartDate != null
            ? '${_leaseStartDate!.month}/${_leaseStartDate!.day}/${_leaseStartDate!.year}'
            : 'No move-in date available',
        style: TextStyle(
          fontFamily: 'Montserrat',
          color: _leaseStartDate != null
              ? context.colorScheme.onSurface
              : context.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildContractDurationField() {
    // If existing lease, show as read-only
    if (_existingLease != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Contract Duration',
          labelStyle: TextStyle(fontFamily: 'Montserrat'),
          prefixIcon: Icon(Iconsax.timer),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          filled: true,
          fillColor: context.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        ),
        child: Text(
          _monthsBasedOnContract != null
              ? '$_monthsBasedOnContract Months'
              : 'Not set',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: context.colorScheme.onSurface,
          ),
        ),
      );
    }

    // For new lease, show as editable dropdown
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Contract Duration',
        labelStyle: TextStyle(fontFamily: 'Montserrat'),
        prefixIcon: Icon(Iconsax.timer),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        filled: true,
        fillColor: context.colorScheme.surface,
      ),
      value: _monthsBasedOnContract,
      hint: Text(
        'Select duration',
        style: TextStyle(fontFamily: 'Montserrat'),
      ),
      isExpanded: true,
      items: _contractMonthsOptions.map((months) {
        return DropdownMenuItem(
          value: months,
          child: Text(
            '$months Months',
            style: TextStyle(fontFamily: 'Montserrat'),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _monthsBasedOnContract = value;
          _calculateEndDate();
        });
      },
    );
  }

  Widget _buildRenewalOptionsField() {
    // Only show for existing leases
    if (_existingLease == null) return SizedBox.shrink();

    String displayValue;
    if (_existingLease!.renewalOptions == null) {
      displayValue = 'Not Set (Will be set to null on update)';
    } else if (_existingLease!.renewalOptions == 0) {
      displayValue = 'Move Out (0 months)';
    } else {
      displayValue = '${_existingLease!.renewalOptions} Months Renewal';
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Renewal Options',
        labelStyle: TextStyle(fontFamily: 'Montserrat'),
        prefixIcon: Icon(Iconsax.refresh),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        filled: true,
        fillColor: context.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        helperText: 'Will be reset to null after update',
        helperStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 11,
          color: context.colorScheme.error,
        ),
      ),
      child: Text(
        displayValue,
        style: TextStyle(
          fontFamily: 'Montserrat',
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }

  

  Widget _buildEditableEndDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _calculatedEndDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) {
          setState(() {
            _calculatedEndDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Lease End Date',
          labelStyle: TextStyle(fontFamily: 'Montserrat'),
          prefixIcon: Icon(Iconsax.calendar_edit),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          filled: true,
          fillColor: context.colorScheme.surface
  
        ),
        child: Text(
          _calculatedEndDate != null
              ? '${_calculatedEndDate!.month}/${_calculatedEndDate!.day}/${_calculatedEndDate!.year}'
              : 'Select end date',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: _calculatedEndDate != null
                ? context.colorScheme.onSurface
                : context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityDepositField() {
    return TextFormField(
      controller: _securityDepositController,
      decoration: InputDecoration(
        labelText: 'Security Deposit',
        labelStyle: TextStyle(fontFamily: 'Montserrat'),
        prefixIcon: Icon(Iconsax.money),
        prefixText: ' ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        filled: true,
        fillColor: context.colorScheme.surface,
      ),
      style: TextStyle(fontFamily: 'Montserrat'),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter security deposit amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildPdfUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Lease Agreement Document (PDF)',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingSM),
        OutlinedButton.icon(
          onPressed: _pickPdfFile,
          icon: Icon(Iconsax.document_upload),
          label: Text(
            _pdfFileName ?? 'Upload PDF Contract',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.all(AppConstants.spacingMD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
        ),
        if (_pdfFileName != null) ...[
          SizedBox(height: AppConstants.spacingSM),
          Container(
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.document,
                  size: 16,
                  color: context.colorScheme.primary,
                ),
                SizedBox(width: AppConstants.spacingXS),
                Expanded(
                  child: Text(
                    _pdfFileName!,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Montserrat',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
