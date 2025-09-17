import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../data/models/report_model.dart';
import '../data/utils/admin_test_utils.dart';

class AdminTestScreen extends StatefulWidget {
  const AdminTestScreen({super.key});

  @override
  State<AdminTestScreen> createState() => _AdminTestScreenState();
}

class _AdminTestScreenState extends State<AdminTestScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedReportId;
  final List<String> _sampleReportIds = ['R001', 'R002', 'R003'];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Test Utilities',
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
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(),
            SizedBox(height: AppConstants.spacingLG),
            _ReportIdSelector(),
            SizedBox(height: AppConstants.spacingLG),
            _MessageInput(),
            SizedBox(height: AppConstants.spacingLG),
            _ActionButtons(),
            SizedBox(height: AppConstants.spacingLG),
            _QuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _InfoCard() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: context.radiusMD,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.3),
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
                  'Admin Test Mode',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.primary,
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(height: AppConstants.spacingXS / 2),
                Text(
                  'Use these utilities to simulate admin actions like updating report status and adding admin messages. This is for testing purposes only.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.7),
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

  Widget _ReportIdSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Report ID',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingSM),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMD),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: context.radiusSM,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReportId,
              isExpanded: true,
              hint: Text(
                'Choose a report ID',
                style: TextStyle(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontFamily: 'Montserrat',
                ),
              ),
              onChanged: (String? value) {
                setState(() {
                  _selectedReportId = value;
                });
              },
              items: _sampleReportIds.map((String reportId) {
                return DropdownMenuItem<String>(
                  value: reportId,
                  child: Text(
                    reportId,
                    style: TextStyle(fontFamily: 'Montserrat'),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _MessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Message (Optional)',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingSM),
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter admin message...',
            hintStyle: TextStyle(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              fontFamily: 'Montserrat',
            ),
            border: OutlineInputBorder(
              borderRadius: context.radiusSM,
            ),
          ),
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
      ],
    );
  }

  Widget _ActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Actions',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingSM),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'In Progress',
                icon: Iconsax.clock,
                color: Colors.orange,
                onPressed: () => _updateReportStatus(ReportStatus.inProgress),
              ),
            ),
            SizedBox(width: AppConstants.spacingSM),
            Expanded(
              child: _ActionButton(
                label: 'Resolve',
                icon: Iconsax.tick_circle,
                color: Colors.green,
                onPressed: () => _updateReportStatus(ReportStatus.resolved),
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacingSM),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Close',
                icon: Iconsax.close_circle,
                color: Colors.red,
                onPressed: () => _updateReportStatus(ReportStatus.closed),
              ),
            ),
            SizedBox(width: AppConstants.spacingSM),
            Expanded(
              child: _ActionButton(
                label: 'Add Message',
                icon: Iconsax.message_add,
                color: context.colorScheme.primary,
                onPressed: _addMessage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: _selectedReportId != null ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusSM,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          SizedBox(height: AppConstants.spacingXS / 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _QuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Messages',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingSM),
        Wrap(
          spacing: AppConstants.spacingSM,
          runSpacing: AppConstants.spacingSM,
          children: AdminTestUtils.getSuggestedResponses('maintenance')
              .take(4)
              .map((message) => _QuickMessageChip(
                    message: message,
                    onTap: () {
                      _messageController.text = message;
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _QuickMessageChip({
    required String message,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSM,
          vertical: AppConstants.spacingXS,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHigh,
          borderRadius: context.radiusSM,
          border: Border.all(
            color: context.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          message,
          style: context.textTheme.bodySmall?.copyWith(
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Future<void> _updateReportStatus(ReportStatus status) async {
    if (_selectedReportId == null) return;

    try {
      final message = _messageController.text.trim();

      switch (status) {
        case ReportStatus.inProgress:
          await AdminTestUtils.markReportInProgress(
            _selectedReportId!,
            message: message.isEmpty ? null : message,
          );
          break;
        case ReportStatus.resolved:
          await AdminTestUtils.resolveReport(
            _selectedReportId!,
            message: message.isEmpty ? null : message,
          );
          break;
        case ReportStatus.closed:
          await AdminTestUtils.closeReport(
            _selectedReportId!,
            message: message.isEmpty ? null : message,
          );
          break;
        default:
          break;
      }

      HapticFeedback.successNotificationImpact();
      Loaders.successSnackBar(
        context,
        title: 'Status Updated',
        message: 'Report $_selectedReportId has been marked as ${status.name}',
      );

      _messageController.clear();
    } catch (e) {
      Loaders.errorSnackBar(
        context,
        title: 'Action Failed',
        message: e.toString(),
      );
    }
  }

  Future<void> _addMessage() async {
    if (_selectedReportId == null || _messageController.text.trim().isEmpty) {
      Loaders.warningSnackBar(
        context,
        title: 'Missing Information',
        message: 'Please select a report ID and enter a message',
      );
      return;
    }

    try {
      await AdminTestUtils.addAdminUpdate(
        _selectedReportId!,
        _messageController.text.trim(),
      );

      HapticFeedback.successNotificationImpact();
      Loaders.successSnackBar(
        context,
        title: 'Message Added',
        message: 'Admin message has been added to report $_selectedReportId',
      );

      _messageController.clear();
    } catch (e) {
      Loaders.errorSnackBar(
        context,
        title: 'Action Failed',
        message: e.toString(),
      );
    }
  }
}