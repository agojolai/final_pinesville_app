import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../common/widgets/feedback/feedback.dart';
import '../../../core/snackbars/loaders.dart';
import '../data/models/report_model.dart';
import '../providers/feedback_provider.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final ReportModel report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report #${widget.report.id}',
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
        actions: [
          PopupMenuButton(
            icon: Icon(Iconsax.more),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Iconsax.copy, size: 16),
                    SizedBox(width: AppConstants.spacingXS),
                    Text('Copy Report ID'),
                  ],
                ),
                onTap: () => _copyReportId(),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Iconsax.export, size: 16),
                    SizedBox(width: AppConstants.spacingXS),
                    Text('Export Report'),
                  ],
                ),
                onTap: () => _exportReport(),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppConstants.spacingMD),
          child: Column(
            children: [
              _StatusHeader(),
              SizedBox(height: AppConstants.spacingLG),
              _ReportDetails(),
              SizedBox(height: AppConstants.spacingLG),
              _UpdatesSection(),
              // Add feedback section for resolved reports
              if (widget.report.status == ReportStatus.resolved) ...[
                SizedBox(height: AppConstants.spacingLG),
                // Feedback Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppConstants.spacingLG),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: context.radiusXL,
                    border: Border.all(
                      color: context.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Iconsax.star,
                            color: context.colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: AppConstants.spacingSM),
                          Text(
                            'Feedback',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.primary,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.spacingMD),
                      if (widget.report.feedback != null) 
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Your Rating: ',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < widget.report.feedback!.rating ? Iconsax.star5 : Iconsax.star,
                                      color: index < widget.report.feedback!.rating ? Colors.amber : context.colorScheme.outline,
                                      size: 16,
                                    );
                                  }),
                                ),
                                Text(' ${widget.report.feedback!.rating}/5'),
                              ],
                            ),
                            if (widget.report.feedback!.comment.isNotEmpty) ...[
                              SizedBox(height: AppConstants.spacingMD),
                              Text(
                                'Comment: ${widget.report.feedback!.comment}',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _showFeedbackDialog(),
                          icon: Icon(Iconsax.star, size: 18),
                          label: Text('Give Feedback'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: AppConstants.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _StatusHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: _getStatusColor(widget.report.status).withValues(alpha:0.1),
        borderRadius: context.radiusXL,
        border: Border.all(
          color: _getStatusColor(widget.report.status).withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacingMD),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.report.status).withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(widget.report.status),
              size: 32,
              color: _getStatusColor(widget.report.status),
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          Text(
            _getStatusText(widget.report.status),
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getStatusColor(widget.report.status),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            _getStatusDescription(widget.report.status),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.7),
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.report.resolvedAt != null) ...[
            SizedBox(height: AppConstants.spacingSM),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSM,
                vertical: AppConstants.spacingXS,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Resolved on ${_formatDate(widget.report.resolvedAt!)}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ReportDetails() {
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
          
          _DetailRow(
            icon: Iconsax.home_2,
            label: 'Unit Number',
            value: widget.report.unitNumber,
          ),
          
          _DetailRow(
            icon: Iconsax.category,
            label: 'Category',
            value: widget.report.category,
          ),
          
          if (widget.report.subCategory.isNotEmpty)
            _DetailRow(
              icon: Iconsax.tag,
              label: 'Subcategory',
              value: widget.report.subCategory,
            ),
          
          _DetailRow(
            icon: Iconsax.user,
            label: 'Submitted by',
            value: widget.report.tenant.name,
          ),
          
          _DetailRow(
            icon: Iconsax.calendar,
            label: 'Submitted on',
            value: _formatFullDate(widget.report.submittedAt),
            isLast: true,
          ),
          
          SizedBox(height: AppConstants.spacingLG),
          
          Row(
            children: [
              Icon(
                Iconsax.document_text,
                size: 20,
                color: context.colorScheme.primary,
              ),
              SizedBox(width: AppConstants.spacingXS),
              Text(
                'Description',
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
            ),
            child: Text(
              widget.report.description,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha:0.8),
                fontFamily: 'Montserrat',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _DetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : AppConstants.spacingMD,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: context.colorScheme.primary,
          ),
          SizedBox(width: AppConstants.spacingSM),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha:0.7),
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _UpdatesSection() {
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
            children: [
              Icon(
                Iconsax.message_text,
                size: 20,
                color: context.colorScheme.primary,
              ),
              SizedBox(width: AppConstants.spacingXS),
              Text(
                'Updates & Responses',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          
          if (widget.report.updates.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppConstants.spacingLG),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainer.withValues(alpha:0.3),
                borderRadius: context.radiusMD,
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.message,
                    size: 40,
                    color: context.colorScheme.onSurface.withValues(alpha:0.4),
                  ),
                  SizedBox(height: AppConstants.spacingSM),
                  Text(
                    'No updates yet',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha:0.6),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingXS),
                  Text(
                    'You will receive updates from the admin team here.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha:0.5),
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...widget.report.updates.asMap().entries.map((entry) {
              int index = entry.key;
              ReportUpdate update = entry.value;
              return Container(
                margin: EdgeInsets.only(
                  bottom: index < widget.report.updates.length - 1 
                      ? AppConstants.spacingMD : 0,
                ),
                child: _UpdateCard(update: update),
              );
            }).toList(),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.closed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Iconsax.clock;
      case ReportStatus.inProgress:
        return Iconsax.refresh;
      case ReportStatus.resolved:
        return Iconsax.tick_circle;
      case ReportStatus.closed:
        return Iconsax.close_circle;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.closed:
        return 'Closed';
    }
  }

  String _getStatusDescription(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Your report is waiting to be reviewed by the admin team.';
      case ReportStatus.inProgress:
        return 'The admin team is working on resolving your report.';
      case ReportStatus.resolved:
        return 'Your report has been resolved successfully.';
      case ReportStatus.closed:
        return 'This report has been closed.';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyReportId() {
    Clipboard.setData(ClipboardData(text: widget.report.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportReport() {
    // In real app, implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showFeedbackDialog() {
    FeedbackUtils.showFeedback(
      context,
      title: 'Rate Your Experience',
      subtitle: 'How satisfied are you with the resolution of your ${widget.report.category.toLowerCase()} report?',
      submitButtonText: 'Submit Feedback',
      cancelButtonText: 'Skip',
      onSubmit: (rating, comment) async {
        await _submitFeedback(rating, comment);
      },
      onCancel: () {
        // Just close the dialog, no feedback submitted
      },
    );
  }

  Future<void> _submitFeedback(int rating, String comment) async {
    try {
      // Submit feedback using the feedback provider
      await ref.read(feedbackSubmissionProvider.notifier).submitFeedback(
        reportId: widget.report.id,
        rating: rating,
        comments: comment,
      );

      if (mounted) {
        final feedbackState = ref.read(feedbackSubmissionProvider);
        if (feedbackState.status == FeedbackSubmissionStatus.success) {
          Loaders.successSnackBar(
            context,
            title: 'Feedback Submitted',
            message: 'Thank you for your feedback! The report has been closed.',
          );
          // Navigate back to refresh the report list
          Navigator.of(context).pop();
        } else if (feedbackState.status == FeedbackSubmissionStatus.error) {
          Loaders.errorSnackBar(
            context,
            title: 'Feedback Failed',
            message: feedbackState.errorMessage ?? 'Failed to submit feedback',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Feedback Failed',
          message: 'An error occurred while submitting feedback: $e',
        );
      }
    }
  }


}

// Update Card Widget
class _UpdateCard extends StatelessWidget {
  final ReportUpdate update;

  const _UpdateCard({required this.update});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: update.isAdmin 
            ? context.colorScheme.primaryContainer.withValues(alpha:0.3)
            : context.colorScheme.surfaceContainer.withValues(alpha:0.5),
        borderRadius: context.radiusMD,
        border: Border.all(
          color: update.isAdmin 
              ? context.colorScheme.primary.withValues(alpha:0.3)
              : context.colorScheme.outline.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacingXS),
                decoration: BoxDecoration(
                  color: update.isAdmin 
                      ? context.colorScheme.primary.withValues(alpha:0.2)
                      : context.colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  update.isAdmin ? Iconsax.shield_tick : Iconsax.user,
                  size: 16,
                  color: update.isAdmin 
                      ? context.colorScheme.primary
                      : context.colorScheme.onSurface.withValues(alpha:0.6),
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.isAdmin ? 'Admin Team' : 'You',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: update.isAdmin 
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurface,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      _formatUpdateTime(update.timestamp),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha:0.5),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            update.message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.8),
              fontFamily: 'Montserrat',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatUpdateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}


