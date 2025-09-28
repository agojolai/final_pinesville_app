import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../data/models/report_model.dart';
import '../providers/reports_provider.dart';

class AdminReportsTestScreen extends ConsumerStatefulWidget {
  const AdminReportsTestScreen({super.key});

  @override
  ConsumerState<AdminReportsTestScreen> createState() => _AdminReportsTestScreenState();
}

class _AdminReportsTestScreenState extends ConsumerState<AdminReportsTestScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final adminReportsAsync = ref.watch(adminReportsStreamProvider);
    final adminStatsAsync = ref.watch(adminStatsProvider);
    final actionState = ref.watch(reportsActionProvider);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Admin Reports Testing',
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colorScheme.onSurface,
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
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            _buildStatusSection(context, adminStatsAsync),
            
            SizedBox(height: AppConstants.spacingXL),
            
            // Test Actions Section
            _buildTestActionsSection(context, actionState),
            
            SizedBox(height: AppConstants.spacingXL),
            
            // All Reports Section
            _buildAllReportsSection(context, adminReportsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, AsyncValue<Map<String, int>> statsAsync) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLG),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.chart,
                size: 24,
                color: context.colorScheme.primary,
              ),
              SizedBox(width: AppConstants.spacingXS),
              Text(
                'Global Statistics',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: context.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.spacingMD),
          
          statsAsync.when(
            data: (stats) => _buildStatsGrid(context, stats),
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.spacingMD),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Text(
              'Error loading statistics: $error',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context, 'Total', stats['total'] ?? 0, Iconsax.document_text),
        ),
        SizedBox(width: AppConstants.spacingSM),
        Expanded(
          child: _buildStatCard(context, 'Pending', stats['pending'] ?? 0, Iconsax.clock),
        ),
        SizedBox(width: AppConstants.spacingSM),
        Expanded(
          child: _buildStatCard(context, 'In Progress', stats['inProgress'] ?? 0, Iconsax.timer_1),
        ),
        SizedBox(width: AppConstants.spacingSM),
        Expanded(
          child: _buildStatCard(context, 'Resolved', stats['resolved'] ?? 0, Iconsax.tick_circle),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, int count, IconData icon) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingSM),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: context.colorScheme.primary,
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            count.toString(),
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTestActionsSection(BuildContext context, AsyncValue<void> actionState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Actions',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            color: context.colorScheme.onSurface,
          ),
        ),
        
        SizedBox(height: AppConstants.spacingMD),
        
        // Create Sample Data Button
        _ActionButton(
          icon: Iconsax.document_add,
          title: 'Create Sample Reports',
          description: 'Add sample reports to the current user account for testing',
          onTap: _createSampleData,
          color: context.colorScheme.primary,
          isLoading: _isLoading || actionState.isLoading,
        ),
        
        SizedBox(height: AppConstants.spacingSM),
        
        // Clear All Data Button
        _ActionButton(
          icon: Iconsax.trash,
          title: 'Clear All Reports',
          description: 'Delete all reports for the current user (use with caution)',
          onTap: _clearAllData,
          color: context.colorScheme.error,
          isLoading: _isLoading || actionState.isLoading,
        ),
        
        SizedBox(height: AppConstants.spacingSM),
        
        // Refresh Data Button
        _ActionButton(
          icon: Iconsax.refresh,
          title: 'Refresh Data',
          description: 'Refresh all reports and statistics from Firestore',
          onTap: _refreshData,
          color: context.colorScheme.secondary,
          isLoading: false,
        ),
        
        if (actionState.hasError)
          Container(
            margin: EdgeInsets.only(top: AppConstants.spacingSM),
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              color: context.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: 16,
                  color: context.colorScheme.error,
                ),
                SizedBox(width: AppConstants.spacingXS),
                Expanded(
                  child: Text(
                    'Error: ${actionState.error.toString()}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAllReportsSection(BuildContext context, AsyncValue<List<Report>> reportsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'All Reports',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: context.colorScheme.onSurface,
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: _refreshData,
              icon: Icon(
                Iconsax.refresh,
                size: 20,
                color: context.colorScheme.primary,
              ),
            ),
          ],
        ),
        
        SizedBox(height: AppConstants.spacingMD),
        
        reportsAsync.when(
          data: (reports) => reports.isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: reports.map((report) => _buildReportCard(context, report)).toList(),
                ),
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.spacingLG),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Container(
            padding: EdgeInsets.all(AppConstants.spacingMD),
            decoration: BoxDecoration(
              color: context.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
            ),
            child: Column(
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: 32,
                  color: context.colorScheme.error,
                ),
                SizedBox(height: AppConstants.spacingSM),
                Text(
                  'Error loading reports',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppConstants.spacingXS),
                Text(
                  error.toString(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.spacingXL),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLG),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_text,
            size: 64,
            color: context.colorScheme.onSurface.withValues(alpha:0.3),
          ),
          SizedBox(height: AppConstants.spacingLG),
          Text(
            'No Reports Found',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface.withValues(alpha:0.6),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'Create sample data to test the reports functionality.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.5),
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Report report) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacingSM),
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSM,
                  vertical: AppConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(context, report.status).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLG),
                ),
                child: Text(
                  _getStatusText(report.status),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(context, report.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              Text(
                report.id,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha:0.6),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.spacingSM),
          
          Text(
            '${report.category} - ${report.subCategory}',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface,
            ),
          ),
          
          SizedBox(height: AppConstants.spacingXS),
          
          Text(
            report.description,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: AppConstants.spacingSM),
          
          Row(
            children: [
              Icon(
                Iconsax.user,
                size: 14,
                color: context.colorScheme.onSurface.withValues(alpha:0.5),
              ),
              SizedBox(width: AppConstants.spacingXS),
              Text(
                report.tenantName,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha:0.6),
                ),
              ),
              Spacer(),
              Text(
                _formatDate(report.submittedAt),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha:0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.closed:
        return context.colorScheme.onSurface.withValues(alpha:0.5);
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

  Future<void> _createSampleData() async {
    HapticFeedback.mediumImpact();
    
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Sample Data'),
        content: Text('This will create sample reports for testing. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Create'),
          ),
        ],
      ),
    );

    if (shouldCreate == true) {
      setState(() => _isLoading = true);
      
      try {
        await ref.read(reportsActionProvider.notifier).createSampleData();
        
        if (mounted) {
          Loaders.successSnackBar(
            context,
            title: 'Success',
            message: 'Sample reports created successfully!',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _clearAllData() async {
    HapticFeedback.heavyImpact();
    
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data'),
        content: Text('This will permanently delete all reports. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete All'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      setState(() => _isLoading = true);
      
      try {
        await ref.read(reportsActionProvider.notifier).clearAllData();
        
        if (mounted) {
          Loaders.successSnackBar(
            context,
            title: 'Success',
            message: 'All reports have been cleared.',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _refreshData() {
    HapticFeedback.lightImpact();
    ref.invalidate(adminReportsStreamProvider);
    ref.invalidate(adminStatsProvider);
    
    Loaders.successSnackBar(
      context,
      title: 'Refreshed',
      message: 'Data has been refreshed from Firestore.',
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Color color;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppConstants.spacingXS),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
        border: Border.all(
          color: color.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.spacingMD),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMD),
                  ),
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        )
                      : Icon(
                          icon,
                          color: color,
                          size: 24,
                        ),
                ),
                SizedBox(width: AppConstants.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacingXS),
                      Text(
                        description,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha:0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 20,
                  color: context.colorScheme.onSurface.withValues(alpha:0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}