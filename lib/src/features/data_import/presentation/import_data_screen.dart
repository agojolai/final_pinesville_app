import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../providers/import_providers.dart';
import '../data/models/import_models.dart';

class ImportDataScreen extends ConsumerStatefulWidget {
  const ImportDataScreen({
    super.key,
    required this.onMenuTap,
  });

  final VoidCallback onMenuTap;

  @override
  ConsumerState<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends ConsumerState<ImportDataScreen> {
  Uint8List? _billsFileBytes;
  String? _billsFileName;
  Uint8List? _paymentsFileBytes;
  String? _paymentsFileName;
  List<ValidationError> _billsErrors = [];
  List<ValidationError> _paymentsErrors = [];
  bool _isValidating = false;
  int _importProgress = 0;
  int _importTotal = 0;

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Iconsax.menu,
            color: context.colorScheme.onSurface,
          ),
          tooltip: 'Open navigation menu',
          onPressed: widget.onMenuTap,
        ),
        title: Text(
          'Import Historical Data',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            SizedBox(height: AppConstants.spacingLG),
            _buildBillsSection(),
            SizedBox(height: AppConstants.spacingLG),
            _buildPaymentsSection(),
            SizedBox(height: AppConstants.spacingLG),
            _buildActionButtons(importState),
            if (importState.isLoading) ...[
              SizedBox(height: AppConstants.spacingLG),
              _buildProgressIndicator(),
            ],
            if (importState.hasValue && importState.value != null) ...[
              SizedBox(height: AppConstants.spacingLG),
              _buildResultSummary(importState.value!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: context.radiusMD,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.info_circle,
            color: context.colorScheme.primary,
          ),
          SizedBox(width: AppConstants.spacingMD),
          Expanded(
            child: Text(
              'Import historical billing and payment data from CSV or JSON files. No limit on the number of records or time period.',
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsSection() {
    return _buildFileSection(
      title: 'Bills',
      subtitle: 'Select the bills CSV/JSON file',
      icon: Iconsax.document,
      fileName: _billsFileName,
      errors: _billsErrors,
      onSelectFile: _selectBillsFile,
      onClear: () => setState(() {
        _billsFileBytes = null;
        _billsFileName = null;
        _billsErrors = [];
      }),
    );
  }

  Widget _buildPaymentsSection() {
    return _buildFileSection(
      title: 'Payments',
      subtitle: 'Select the payments CSV/JSON file',
      icon: Iconsax.money_send,
      fileName: _paymentsFileName,
      errors: _paymentsErrors,
      onSelectFile: _selectPaymentsFile,
      onClear: () => setState(() {
        _paymentsFileBytes = null;
        _paymentsFileName = null;
        _paymentsErrors = [];
      }),
    );
  }

  Widget _buildFileSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required List<ValidationError> errors,
    required VoidCallback onSelectFile,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusMD,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.colorScheme.primary),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          if (fileName == null)
            ElevatedButton.icon(
              onPressed: onSelectFile,
              icon: const Icon(Iconsax.folder_open),
              label: const Text('Select File'),
            )
          else
            Container(
              padding: EdgeInsets.all(AppConstants.spacingSM),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: context.radiusSM,
              ),
              child: Row(
                children: [
                  Icon(Iconsax.document_text, size: 20),
                  SizedBox(width: AppConstants.spacingSM),
                  Expanded(
                    child: Text(
                      fileName,
                      style: context.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle),
                    onPressed: onClear,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
          if (errors.isNotEmpty) ...[
            SizedBox(height: AppConstants.spacingSM),
            Container(
              padding: EdgeInsets.all(AppConstants.spacingSM),
              decoration: BoxDecoration(
                color: context.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: context.radiusSM,
                border: Border.all(
                  color: context.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.warning_2,
                        size: 16,
                        color: context.colorScheme.error,
                      ),
                      SizedBox(width: AppConstants.spacingXS),
                      Text(
                        '${errors.length} validation error(s)',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacingXS),
                  ...errors.take(5).map((error) => Padding(
                    padding: EdgeInsets.only(top: AppConstants.spacingXS / 2),
                    child: Text(
                      error.toDisplayString(),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.error,
                        fontSize: 11,
                      ),
                    ),
                  )),
                  if (errors.length > 5)
                    Padding(
                      padding: EdgeInsets.only(top: AppConstants.spacingXS),
                      child: TextButton(
                        onPressed: () => _showAllErrors(errors, title),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Show all ${errors.length} errors...',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.error,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(AsyncValue<ImportResult?> importState) {
    final canValidate = _billsFileBytes != null || _paymentsFileBytes != null;
    final canImport = _billsFileBytes != null && 
                      _paymentsFileBytes != null && 
                      _billsErrors.isEmpty && 
                      _paymentsErrors.isEmpty;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_isValidating || importState.isLoading || !canValidate) 
                ? null 
                : _validateFiles,
            icon: const Icon(Iconsax.verify),
            label: Text(_isValidating ? 'Validating...' : 'Validate'),
          ),
        ),
        SizedBox(width: AppConstants.spacingMD),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (importState.isLoading || !canImport) ? null : _importData,
            icon: const Icon(Iconsax.import),
            label: const Text('Import Data'),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      child: Column(
        children: [
          Text('Importing: $_importProgress / $_importTotal'),
          LinearProgressIndicator(
            value: _importTotal > 0 ? _importProgress / _importTotal : 0,
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummary(ImportResult result) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: result.isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: context.radiusMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.isSuccess ? 'Import Successful!' : 'Import Failed',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('Total: ${result.totalRecords}'),
          Text('Success: ${result.successCount}'),
          Text('Errors: ${result.errorCount}'),
          Text('Duration: ${result.duration.inSeconds}s'),
        ],
      ),
    );
  }

  Future<void> _selectBillsFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Accept any file type
        withData: true, // KEY: This loads file bytes for mobile devices
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file extension (CSV or JSON)
        if (!file.name.toLowerCase().endsWith('.csv') && 
            !file.name.toLowerCase().endsWith('.json')) {
          if (!mounted) return;
          Loaders.errorSnackBar(
            context,
            title: 'Invalid File Type',
            message: 'Please select a CSV or JSON file.',
          );
          return;
        }
        
        if (file.bytes != null) {
          if (!mounted) return;
          setState(() {
            _billsFileBytes = file.bytes!;
            _billsFileName = file.name;
            _billsErrors = [];
          });
          
          Loaders.successSnackBar(
            context,
            title: 'File Selected',
            message: 'Bills file loaded: ${file.name}',
          );
        } else {
          if (!mounted) return;
          Loaders.errorSnackBar(
            context,
            title: 'Error',
            message: 'Could not read file data. Please try again.',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Loaders.errorSnackBar(
        context,
        title: 'Error',
        message: 'Failed to select file: $e',
      );
    }
  }

  Future<void> _selectPaymentsFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Accept any file type
        withData: true, // KEY: This loads file bytes for mobile devices
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file extension (CSV or JSON)
        if (!file.name.toLowerCase().endsWith('.csv') && 
            !file.name.toLowerCase().endsWith('.json')) {
          if (!mounted) return;
          Loaders.errorSnackBar(
            context,
            title: 'Invalid File Type',
            message: 'Please select a CSV or JSON file.',
          );
          return;
        }
        
        if (file.bytes != null) {
          if (!mounted) return;
          setState(() {
            _paymentsFileBytes = file.bytes!;
            _paymentsFileName = file.name;
            _paymentsErrors = [];
          });
          
          Loaders.successSnackBar(
            context,
            title: 'File Selected',
            message: 'Payments file loaded: ${file.name}',
          );
        } else {
          if (!mounted) return;
          Loaders.errorSnackBar(
            context,
            title: 'Error',
            message: 'Could not read file data. Please try again.',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Loaders.errorSnackBar(
        context,
        title: 'Error',
        message: 'Failed to select file: $e',
      );
    }
  }

  Future<void> _validateFiles() async {
    setState(() => _isValidating = true);

    try {
      final notifier = ref.read(importStateProvider.notifier);

      if (_billsFileBytes != null && _billsFileName != null) {
        final errors = await notifier.validateBillsFile(_billsFileBytes!, _billsFileName!);
        setState(() => _billsErrors = errors);
      }

      if (_paymentsFileBytes != null && _paymentsFileName != null) {
        final errors = await notifier.validatePaymentsFile(_paymentsFileBytes!, _paymentsFileName!);
        setState(() => _paymentsErrors = errors);
      }

      if (!mounted) return;
      if (_billsErrors.isEmpty && _paymentsErrors.isEmpty) {
        Loaders.successSnackBar(
          context,
          title: 'Validation Passed',
          message: 'All files are valid and ready to import!',
        );
      } else {
        final totalErrors = _billsErrors.length + _paymentsErrors.length;
        Loaders.errorSnackBar(
          context,
          title: 'Validation Failed',
          message: 'Found $totalErrors error(s). Check the details below.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Loaders.errorSnackBar(
        context,
        title: 'Validation Error',
        message: e.toString(),
      );
    } finally {
      setState(() => _isValidating = false);
    }
  }

  void _showAllErrors(List<ValidationError> errors, String fileType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '$fileType Validation Errors',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: errors.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, index) {
              final error = errors[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: context.colorScheme.error.withValues(alpha: 0.1),
                  radius: 16,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: context.colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  'Row ${error.rowNumber} - ${error.field}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  error.message,
                  style: TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    try {
      setState(() {
        _importProgress = 0;
        _importTotal = 48;
      });

      final notifier = ref.read(importStateProvider.notifier);

      await notifier.importBills(
        _billsFileBytes!,
        _billsFileName!,
        onProgress: (current, total) {
          if (mounted) setState(() => _importProgress = current);
        },
      );

      await notifier.importPayments(
        _paymentsFileBytes!,
        _paymentsFileName!,
        onProgress: (current, total) {
          if (mounted) setState(() => _importProgress = 24 + current);
        },
      );

      if (!mounted) return;
      Loaders.successSnackBar(
        context,
        title: 'Success',
        message: 'Data imported successfully!',
      );
    } catch (e) {
      if (!mounted) return;
      Loaders.errorSnackBar(
        context,
        title: 'Import Failed',
        message: e.toString(),
      );
    }
  }
}
