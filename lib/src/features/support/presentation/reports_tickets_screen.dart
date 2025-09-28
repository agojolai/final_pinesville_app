import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../common/widgets/feedback/feedback.dart';
import '../data/models/report_model.dart';
import '../data/repositories/report_repository.dart';
import 'submit_report_screen.dart';
import 'report_detail_screen.dart';

class ReportsTicketsScreen extends StatefulWidget {
  const ReportsTicketsScreen({super.key});

  @override
  State<ReportsTicketsScreen> createState() => _ReportsTicketsScreenState();
}

class _ReportsTicketsScreenState extends State<ReportsTicketsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<ReportModel> _reports = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

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
    _loadReports();
  }

  void _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final currentUser = AuthRepository.instance.authUser;
      if (currentUser != null) {
        final reports = await ReportRepository.instance.getTenantReports(currentUser.uid);
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      } else {
        throw 'User not authenticated';
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _refreshReports() async {
    await _loadReports();
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
          'Reports & Tickets',
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
        child: Column(
          children: [
            _StatsHeader(),
            Expanded(
              child: _isLoading
                  ? _LoadingState()
                  : _hasError
                      ? _ErrorState()
                      : _reports.isEmpty
                          ? _EmptyState()
                          : RefreshIndicator(
                              onRefresh: _refreshReports,
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.all(AppConstants.spacingMD),
                                itemCount: _reports.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: AppConstants.spacingMD,
                                    ),
                                    child: _ReportCard(
                                      report: _reports[index],
                                      onTap: () => _showReportDetail(_reports[index]),
                                      onConfirmResolved: _reports[index].status == ReportStatus.resolved
                                          ? () => _handleResolvedTicketConfirmation(_reports[index])
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitReport,
        backgroundColor: context.colorScheme.primary,
        foregroundColor: context.colorScheme.onPrimary,
        icon: Icon(Iconsax.add),
        label: Text(
          'Submit Report',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _StatsHeader() {
    final pendingCount = _reports.where((r) => r.status == ReportStatus.pending).length;
    final inProgressCount = _reports.where((r) => r.status == ReportStatus.inProgress).length;
    final resolvedCount = _reports.where((r) => r.status == ReportStatus.resolved).length;

    return Container(
      margin: EdgeInsets.all(AppConstants.spacingMD),
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
            'Report Summary',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Pending',
                  count: pendingCount,
                  color: context.colorScheme.error,
                  icon: Iconsax.clock,
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: _StatCard(
                  title: 'In Progress',
                  count: inProgressCount,
                  color: Colors.orange,
                  icon: Iconsax.refresh,
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: _StatCard(
                  title: 'Resolved',
                  count: resolvedCount,
                  color: Colors.green,
                  icon: Iconsax.tick_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _StatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingSM),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: context.radiusMD,
        border: Border.all(
          color: color.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            count.toString(),
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Montserrat',
            ),
          ),
          Text(
            title,
            style: context.textTheme.bodySmall?.copyWith(
              color: color,
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _EmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Iconsax.document_text,
              size: 80,
              color: context.colorScheme.onSurface.withValues(alpha:0.3),
            ),
            SizedBox(height: AppConstants.spacingLG),
            Text(
              'No Reports Yet',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurface.withValues(alpha:0.6),
                fontFamily: 'Montserrat',
              ),
            ),
            SizedBox(height: AppConstants.spacingSM),
            Text(
              'Submit your first report or ticket using the button below.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha:0.5),
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }

  Widget _LoadingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colorScheme.primary,
              ),
            ),
            SizedBox(height: AppConstants.spacingLG),
            Text(
              'Loading Reports...',
              style: context.textTheme.titleMedium?.copyWith(
                fontFamily: 'Montserrat',
                color: context.colorScheme.onSurface.withValues(alpha:0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: context.colorScheme.error,
            ),
            SizedBox(height: AppConstants.spacingLG),
            Text(
              'Error Loading Reports',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.error,
                fontFamily: 'Montserrat',
              ),
            ),
            SizedBox(height: AppConstants.spacingSM),
            Text(
              _errorMessage,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha:0.6),
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacingLG),
            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: Icon(Iconsax.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitReport() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmitReportScreen(
          onReportSubmitted: (report) {
            setState(() {
              _reports.insert(0, report);
            });
            // No need for success message here as it's shown in the submit screen
          },
        ),
      ),
    );
  }

  void _showReportDetail(ReportModel report) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(report: report),
      ),
    ).then((result) {
      // Refresh reports if feedback was submitted
      if (result == true) {
        _loadReports();
      }
    });
  }

  void _handleResolvedTicketConfirmation(ReportModel report) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Iconsax.archive_tick,
              color: context.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Text(
              'Archive Report',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'After confirming, this report will be archived and removed from your active reports list. This action cannot be undone.\n\nContinue?',
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showFeedbackForResolvedTicket(report);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: context.colorScheme.onPrimary,
            ),
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackForResolvedTicket(Report report) {
    FeedbackUtils.showFeedback(
      context,
      title: 'Rate Your Experience',
      subtitle: 'How satisfied are you with the resolution of your ${report.category.toLowerCase()} report?',
      submitButtonText: 'Submit',
      cancelButtonText: 'Skip',
      onSubmit: (rating, comment) {
        _archiveReport(report, rating, comment);
      },
      onCancel: () {
        _archiveReport(report, null, null);
      },
    );
  }

  void _archiveReport(Report report, int? rating, String? comment) {
    setState(() {
      _reports.removeWhere((r) => r.id == report.id);
    });

    // Show success message
    Loaders.successSnackBar(
      context,
      title: 'Report Archived',
      message: rating != null 
          ? 'Thank you for your feedback! The report has been archived.'
          : 'The report has been archived successfully.',
    );

    // Here you would typically save the feedback to your backend
    if (rating != null && comment != null) {
      print('Feedback saved: Rating $rating, Comment: "$comment"');
    }
  }
}

// Report Card Widget
class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;
  final VoidCallback? onConfirmResolved;

  const _ReportCard({
    required this.report,
    required this.onTap,
    this.onConfirmResolved,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radiusXL,
        child: Container(
          padding: EdgeInsets.all(AppConstants.spacingMD),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: context.radiusXL,
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha:0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withValues(alpha:0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingSM,
                          vertical: AppConstants.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(report.status).withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(report.status),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(report.status),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                      SizedBox(width: AppConstants.spacingSM),
                      Text(
                        '#${report.id}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha:0.6),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Iconsax.arrow_right_3,
                    color: context.colorScheme.onSurface.withValues(alpha:0.4),
                    size: 16,
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacingSM),
              Text(
                report.category,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
              if (report.subCategory.isNotEmpty) ...[
                SizedBox(height: AppConstants.spacingXS / 2),
                Text(
                  report.subCategory,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.primary,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
              SizedBox(height: AppConstants.spacingXS),
              Text(
                report.description,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha:0.7),
                  fontFamily: 'Montserrat',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppConstants.spacingSM),
              Row(
                children: [
                  Icon(
                    Iconsax.calendar,
                    size: 14,
                    color: context.colorScheme.onSurface.withValues(alpha:0.5),
                  ),
                  SizedBox(width: AppConstants.spacingXS / 2),
                  Text(
                    _formatDate(report.submittedAt),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha:0.5),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Iconsax.home_2,
                    size: 14,
                    color: context.colorScheme.onSurface.withValues(alpha:0.5),
                  ),
                  SizedBox(width: AppConstants.spacingXS / 2),
                  Text(
                    'Unit ${report.unitNumber}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha:0.5),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
              
              // Show confirm button for resolved tickets
              if (report.status == ReportStatus.resolved && onConfirmResolved != null) ...[
                SizedBox(height: AppConstants.spacingMD),
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onConfirmResolved?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: AppConstants.spacingSM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      ),
                    ),
                    icon: Icon(Iconsax.tick_circle, size: 18),
                    label: Text(
                      'Confirm Resolution',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
