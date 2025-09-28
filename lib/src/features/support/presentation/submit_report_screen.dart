import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/constants/validators.dart';
import '../../../core/snackbars/loaders.dart';
import '../data/models/report_model.dart';
import '../providers/reports_provider.dart';

class SubmitReportScreen extends ConsumerStatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  ConsumerState<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends ConsumerState<SubmitReportScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubCategory;
  List<String> _attachments = [];

  // User's unit (in real app, this would come from user session/account data)
  final String _userUnit = '204-B';

  // Image picker instance
  final ImagePicker _picker = ImagePicker();
  
  // Maximum number of attachments allowed
  static const int maxAttachments = 5;

  // Categories and subcategories
  final Map<String, List<String>> _categories = {
    'Maintenance / Repairs': [
      'Plumbing (leaks, clogs, water issues)',
      'Electrical (wiring, outlets, lights not working)',
      'Structural (walls, ceilings, doors, windows)',
      'Appliances / Fixtures (broken or malfunctioning)',
    ],
    'Billing & Payment': [
      'Incorrect billing amount',
      'Payment not reflected',
      'Proof of payment issues',
    ],
    'Utilities': [
      'Water supply problems',
      'Power outages or fluctuations',
      'Internet/WiFi connectivity issues',
    ],
    'Complaints / Concerns': [
      'Noise disturbance',
      'Neighbor disputes',
      'Safety/security concerns',
    ],
  };

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
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit Report',
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(AppConstants.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoHeader(),
                SizedBox(height: AppConstants.spacingLG),
                _FormSection(),
                SizedBox(height: AppConstants.spacingXL),
                _SubmitButton(),
                SizedBox(height: AppConstants.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _InfoHeader() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withValues(alpha:0.3),
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.info_circle,
            color: context.colorScheme.primary,
            size: 24,
          ),
          SizedBox(width: AppConstants.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Information',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.primary,
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(height: AppConstants.spacingXS / 2),
                Text(
                  'Your report will be automatically tagged with your name, unit number, and submission date.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha:0.7),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _FormSection() {
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
            'Report Details',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingLG),
          
          // Category Dropdown
          _buildDropdownField(
            label: 'Category',
            icon: Iconsax.category,
            value: _selectedCategory,
            items: _categories.keys.toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _selectedSubCategory = null; // Reset subcategory when category changes
              });
            },
            validator: (value) => value == null ? 'Please select a category' : null,
          ),
          
          SizedBox(height: AppConstants.spacingMD),
          
          // Subcategory Dropdown
          if (_selectedCategory != null)
            _buildDropdownField(
              label: 'Subcategory',
              icon: Iconsax.tag,
              value: _selectedSubCategory,
              items: _categories[_selectedCategory!] ?? [],
              onChanged: (value) => setState(() => _selectedSubCategory = value),
              validator: (value) => value == null ? 'Please select a subcategory' : null,
            ),
          
          if (_selectedCategory != null) SizedBox(height: AppConstants.spacingMD),
          
          // Description Field
          _buildDescriptionField(),
          
          SizedBox(height: AppConstants.spacingMD),
          
          // Attachments Section
          _buildAttachmentsSection(),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: context.colorScheme.primary,
            ),
            SizedBox(width: AppConstants.spacingXS),
            Text(
              label,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacingSM),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha:0.3), // Background color
            border: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.outline.withValues(alpha:0.5), // Default border color
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.outline.withValues(alpha:0.5), // Border when not focused
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.primary, // Border when focused
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.error, // Border when there's an error
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.error, // Border when focused with error
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacingMD,
              vertical: AppConstants.spacingSM,
            ),
          ),
          style: TextStyle(
            fontSize: context.textTheme.bodyMedium?.fontSize,
            fontFamily: 'Montserrat',
            color: context.colorScheme.onSurface, // Text color for selected value
          ),
          dropdownColor: context.colorScheme.surface, // Background color of dropdown menu
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: context.textTheme.bodyMedium?.fontSize,
                    fontFamily: 'Montserrat',
                    color: context.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList();
          },
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Container(
                width: double.infinity,
                child: Text(
                  item,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: context.colorScheme.onSurface, // Menu item text color
                    fontSize: context.textTheme.bodyMedium?.fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.document_text,
              size: 20,
              color: context.colorScheme.primary,
            ),
            SizedBox(width: AppConstants.spacingXS),
            Text(
              'Detailed Description',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacingSM),
        TextFormField(
          controller: _descriptionController,
          validator: (value) => Validators.validateEmptyText('Description', value),
          maxLines: 4,
          style: TextStyle(
            fontSize: context.textTheme.bodyMedium?.fontSize,
            fontFamily: 'Montserrat',
            color: context.colorScheme.onSurface, // Text color
          ),
          decoration: InputDecoration(
            hintText: 'Please provide detailed information about the issue...',
            hintStyle: TextStyle(
              color: context.colorScheme.onSurface.withValues(alpha:0.5),
              fontFamily: 'Montserrat',
            ),
            filled: true,
            fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha:0.3), // Background color
            border: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.outline.withValues(alpha:0.5), // Default border color
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.outline.withValues(alpha:0.5), // Border when not focused
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.primary, // Border when focused
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.error, // Border when there's an error
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: context.radiusMD,
              borderSide: BorderSide(
                color: context.colorScheme.error, // Border when focused with error
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.all(AppConstants.spacingMD),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.attach_square,
              size: 20,
              color: context.colorScheme.primary,
            ),
            SizedBox(width: AppConstants.spacingXS),
            Text(
              'Attachments',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacingSM),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppConstants.spacingMD),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer.withValues(alpha:0.5),
            borderRadius: context.radiusMD,
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha:0.3),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Iconsax.gallery_add,
                size: 40,
                color: context.colorScheme.onSurface.withValues(alpha:0.4),
              ),
              SizedBox(height: AppConstants.spacingSM),
              Text(
                'Add Photos or Videos',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface.withValues(alpha:0.6),
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: AppConstants.spacingXS),
              Text(
                'Upload photos of damage, screenshots, or any relevant files to help us understand the issue better. (${_attachments.length}/$maxAttachments attachments)',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha:0.5),
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.spacingMD),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentButton(
                    icon: Iconsax.camera,
                    label: 'Camera',
                    onTap: _attachments.length < maxAttachments ? _takePhoto : null,
                    isEnabled: _attachments.length < maxAttachments,
                  ),
                  _AttachmentButton(
                    icon: Iconsax.gallery,
                    label: 'Gallery',
                    onTap: _attachments.length < maxAttachments ? _pickFromGallery : null,
                    isEnabled: _attachments.length < maxAttachments,
                  ),
                ],
              ),
              if (_attachments.isNotEmpty) ...[
                SizedBox(height: AppConstants.spacingMD),
                _AttachmentsList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _AttachmentsList() {
    return Column(
      children: _attachments.asMap().entries.map((entry) {
        int index = entry.key;
        String attachment = entry.value;
        
        // Get file name from path
        String fileName = attachment.split('/').last;
        if (fileName.isEmpty) fileName = attachment.split('\\').last;
        
        // Determine icon based on file extension
        IconData fileIcon = Iconsax.document;
        if (fileName.toLowerCase().contains('.jpg') || 
            fileName.toLowerCase().contains('.jpeg') || 
            fileName.toLowerCase().contains('.png') ||
            fileName.toLowerCase().contains('.gif')) {
          fileIcon = Iconsax.image;
        } else if (fileName.toLowerCase().contains('.mp4') || 
                   fileName.toLowerCase().contains('.mov') ||
                   fileName.toLowerCase().contains('.avi')) {
          fileIcon = Iconsax.video;
        }
        
        return Container(
          margin: EdgeInsets.only(bottom: AppConstants.spacingXS),
          padding: EdgeInsets.all(AppConstants.spacingSM),
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer.withValues(alpha:0.3),
            borderRadius: context.radiusSM,
          ),
          child: Row(
            children: [
              Icon(
                fileIcon,
                size: 16,
                color: context.colorScheme.primary,
              ),
              SizedBox(width: AppConstants.spacingXS),
              Expanded(
                child: Text(
                  fileName,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _attachments.removeAt(index)),
                icon: Icon(
                  Iconsax.trash,
                  size: 16,
                  color: context.colorScheme.error,
                ),
                constraints: BoxConstraints.tightFor(width: 32, height: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _SubmitButton() {
    return ElevatedButton(
      onPressed: _submitReport,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colorScheme.primary,
        foregroundColor: context.colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMD),
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusXL,
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.send_2),
          SizedBox(width: AppConstants.spacingSM),
          Text(
            'Submit Report',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  void _takePhoto() async {
    try {
      HapticFeedback.lightImpact();
      
      // Check attachment limit
      if (_attachments.length >= maxAttachments) {
        Loaders.errorSnackBar(
          context,
          title: 'Attachment Limit',
          message: 'Maximum $maxAttachments attachments allowed',
        );
        return;
      }
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _attachments.add(photo.path);
        });
        Loaders.customToast(context, message: 'Photo captured successfully');
      }
    } catch (e) {
      Loaders.errorSnackBar(
        context,
        title: 'Camera Error',
        message: 'Failed to capture photo: ${e.toString()}',
      );
    }
  }

  void _pickFromGallery() async {
    try {
      HapticFeedback.lightImpact();
      
      // Check attachment limit
      if (_attachments.length >= maxAttachments) {
        Loaders.errorSnackBar(
          context,
          title: 'Attachment Limit',
          message: 'Maximum $maxAttachments attachments allowed',
        );
        return;
      }
      
      // Show dialog to let user choose between image and video
      final String? mediaType = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Select Media Type',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Iconsax.image, color: context.colorScheme.primary),
                  title: Text(
                    'Image',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  onTap: () => Navigator.of(context).pop('image'),
                ),
                ListTile(
                  leading: Icon(Iconsax.video, color: context.colorScheme.primary),
                  title: Text(
                    'Video',
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                  onTap: () => Navigator.of(context).pop('video'),
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
            ],
          );
        },
      );
      
      if (mediaType != null) {
        XFile? pickedFile;
        
        if (mediaType == 'image') {
          pickedFile = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
          );
        } else if (mediaType == 'video') {
          pickedFile = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 5), // Limit video to 5 minutes
          );
        }
        
        if (pickedFile != null) {
          setState(() {
            _attachments.add(pickedFile!.path);
          });
          Loaders.customToast(
            context, 
            message: '${mediaType[0].toUpperCase()}${mediaType.substring(1)} selected successfully'
          );
        }
      }
    } catch (e) {
      Loaders.errorSnackBar(
        context,
        title: 'Gallery Error',
        message: 'Failed to pick media: ${e.toString()}',
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      Loaders.errorSnackBar(
        context,
        title: 'Error',
        message: 'Please fill in all required fields',
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // Generate report ID
    final reportId = ref.read(reportsActionProvider.notifier).generateReportId();

    // Create report object
    final report = Report(
      id: reportId,
      unitNumber: _userUnit,
      category: _selectedCategory!,
      subCategory: _selectedSubCategory ?? '',
      description: _descriptionController.text,
      status: ReportStatus.pending,
      submittedAt: DateTime.now(),
      tenantName: 'Caleb Anderson', // In real app, get from user session
      attachments: List.from(_attachments),
      updates: [],
    );

    try {
      // Submit to Firestore
      await ref.read(reportsActionProvider.notifier).addReport(report);
      
      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Report Submitted',
          message: 'Your report has been submitted successfully.',
        );
        
        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Submission Failed',
          message: 'Failed to submit report: ${e.toString()}',
        );
      }
    }
  }
}

// Attachment Button Widget
class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSM,
          vertical: AppConstants.spacingXS,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isEnabled 
                  ? context.colorScheme.primary 
                  : context.colorScheme.onSurface.withValues(alpha:0.3),
            ),
            SizedBox(height: AppConstants.spacingXS / 2),
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: isEnabled 
                    ? context.colorScheme.primary 
                    : context.colorScheme.onSurface.withValues(alpha:0.3),
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
