import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../../support/data/models/report_model.dart';
import '../../support/data/repositories/report_repository.dart';

/// Admin Reports & Ticketing Management Screen
/// 
/// Features:
/// - View all tenant reports/tickets across all properties
/// - Filter reports by status (Pending, In Progress, Resolved, Closed)
/// - Update report status with automatic notifications
/// - Add updates/comments to reports
/// - Real-time statistics dashboard
/// - Admin utilities (create samples, bulk delete)
class AdminReportsManagementScreen extends StatefulWidget {
  const AdminReportsManagementScreen({
    super.key,
    required this.onMenuTap,
  });

  final VoidCallback onMenuTap;

  @override
  State<AdminReportsManagementScreen> createState() => _AdminReportsManagementScreenState();
}

class _AdminReportsManagementScreenState extends State<AdminReportsManagementScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<ReportModel> _reports = [];
  bool _isLoading = false;
  ReportStatus? _selectedFilter; // null means show all reports

  // Get filtered reports based on selected filter
  List<ReportModel> get _filteredReports {
    if (_selectedFilter == null) return _reports;
    return _reports.where((report) => report.status == _selectedFilter).toList();
  }

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
    _loadAllReports();
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
          'Reports & Ticketing',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onMenuTap();
          },
          icon: Icon(
            Iconsax.menu,
            color: context.colorScheme.onSurface,
          ),
          tooltip: 'Open navigation menu',
        ),
        toolbarHeight: AppConstants.appBarHeight,
        elevation: 0,
        backgroundColor: context.colorScheme.surface,
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _AdminActions(),
            SizedBox(height: AppConstants.spacingMD),
            _StatsHeader(),
            // Filter status chips
            if (_selectedFilter != null) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppConstants.spacingMD),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        'Filtered: ${_getStatusText(_selectedFilter!)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: _getStatusColor(_selectedFilter!),
                      deleteIcon: Icon(Iconsax.close_circle, color: Colors.white, size: 18),
                      onDeleted: () => setState(() => _selectedFilter = null),
                    ),
                    SizedBox(width: AppConstants.spacingSM),
                    Text(
                      '${_filteredReports.length} reports',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppConstants.spacingMD),
            ],
            Expanded(
              child: _isLoading
                  ? RefreshIndicator(
                      onRefresh: _loadAllReports,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 400,
                          child: _LoadingState(),
                        ),
                      ),
                    )
                  : _reports.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _loadAllReports,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 400,
                              child: _EmptyState(),
                            ),
                          ),
                        )
                      : _filteredReports.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _loadAllReports,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height - 400,
                                  child: _EmptyFilterState(),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAllReports,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: EdgeInsets.all(AppConstants.spacingMD),
                                itemCount: _filteredReports.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: AppConstants.spacingMD,
                                    ),
                                    child: _AdminReportCard(
                                      report: _filteredReports[index],
                                  onStatusUpdate: (report, status) => _updateReportStatus(report, status),
                                  onAddUpdate: (report) => _addReportUpdate(report),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _AdminActions() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      margin: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: context.radiusLG,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Developer Utilities',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: context.colorScheme.primary,
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createSampleReports,
                  icon: Icon(Iconsax.add_circle, size: 18),
                  label: Text('Create Samples'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _deleteAllReports,
                  icon: Icon(Iconsax.trash, size: 18),
                  label: Text('Delete All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _StatsHeader() {
    final pendingCount = _reports.where((r) => r.status == ReportStatus.pending).length;
    final inProgressCount = _reports.where((r) => r.status == ReportStatus.inProgress).length;
    final resolvedCount = _reports.where((r) => r.status == ReportStatus.resolved).length;
    final closedCount = _reports.where((r) => r.status == ReportStatus.closed).length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacingMD),
      child: Row(
        children: [
          _StatCard(
            label: 'Pending',
            count: pendingCount,
            color: Colors.orange,
          ),
          SizedBox(width: AppConstants.spacingSM),
          _StatCard(
            label: 'In Progress',
            count: inProgressCount,
            color: Colors.blue,
          ),
          SizedBox(width: AppConstants.spacingSM),
          _StatCard(
            label: 'Resolved',
            count: resolvedCount,
            color: Colors.green,
          ),
          SizedBox(width: AppConstants.spacingSM),
          _StatCard(
            label: 'Closed',
            count: closedCount,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _StatCard({
    required String label,
    required int count,
    required Color color,
  }) {
    final status = _getStatusFromLabel(label);
    final isSelected = _selectedFilter == status;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedFilter = _selectedFilter == status ? null : status;
            });
          },
          borderRadius: context.radiusMD,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: AppConstants.spacingSM,
              horizontal: AppConstants.spacingXS,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.1),
              borderRadius: context.radiusMD,
              border: Border.all(
                color: isSelected 
                    ? color
                    : color.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontFamily: 'Montserrat',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _EmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.document_text,
              size: 80,
              color: context.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: AppConstants.spacingLG),
            Text(
              'No Reports Found',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                fontFamily: 'Montserrat',
              ),
            ),
            SizedBox(height: AppConstants.spacingSM),
            Text(
              'No tenant reports have been submitted yet.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAllReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await ReportRepository.instance.getAllReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error Loading Reports',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _createSampleReports() async {
    try {
      await ReportRepository.instance.createSampleReports();
      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Success',
          message: 'Sample reports created successfully',
        );
      }
      _loadAllReports();
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to create sample reports: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteAllReports() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Delete',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all reports? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ReportRepository.instance.deleteAllReports();
        if (mounted) {
          Loaders.successSnackBar(
            context,
            title: 'Success',
            message: 'All reports deleted successfully',
          );
        }
        _loadAllReports();
      } catch (e) {
        if (mounted) {
          Loaders.errorSnackBar(
            context,
            title: 'Error',
            message: 'Failed to delete reports: ${e.toString()}',
          );
        }
      }
    }
  }

  Future<void> _updateReportStatus(ReportModel report, ReportStatus newStatus) async {
    try {
      String? message;
      switch (newStatus) {
        case ReportStatus.inProgress:
          message = 'Report is now being processed by the maintenance team.';
          break;
        case ReportStatus.resolved:
          message = 'Report has been resolved successfully.';
          break;
        case ReportStatus.closed:
          message = 'Report has been closed.';
          break;
        default:
          break;
      }

      await ReportRepository.instance.updateReportStatus(
        reportId: report.id,
        status: newStatus,
        message: message,
      );

      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Status Updated',
          message: 'Report status updated to ${newStatus.name}',
        );
      }
      _loadAllReports();
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to update status: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _addReportUpdate(ReportModel report) async {
    String? message = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(
            'Add Update',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter update message...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('Add'),
            ),
          ],
        );
      },
    );

    if (message != null && message.isNotEmpty) {
      try {
        await ReportRepository.instance.addReportUpdate(
          reportId: report.id,
          message: message,
        );

        if (mounted) {
          Loaders.successSnackBar(
            context,
            title: 'Update Added',
            message: 'Report update added successfully',
          );
        }
        _loadAllReports();
      } catch (e) {
        if (mounted) {
          Loaders.errorSnackBar(
            context,
            title: 'Error',
            message: 'Failed to add update: ${e.toString()}',
          );
        }
      }
    }
  }

  // Helper method to get ReportStatus from label text
  ReportStatus _getStatusFromLabel(String label) {
    switch (label) {
      case 'Pending':
        return ReportStatus.pending;
      case 'In Progress':
        return ReportStatus.inProgress;
      case 'Resolved':
        return ReportStatus.resolved;
      case 'Closed':
        return ReportStatus.closed;
      default:
        return ReportStatus.pending;
    }
  }

  // Helper method to get status text
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

  // Helper method to get status color
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

  // Empty state for when filter has no results
  Widget _EmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.search_status,
            size: 64,
            color: context.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          SizedBox(height: AppConstants.spacingMD),
          Text(
            'No ${_getStatusText(_selectedFilter!).toLowerCase()} reports found',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'Try selecting a different status or clear the filter',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacingLG),
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedFilter = null),
            icon: Icon(Iconsax.refresh),
            label: Text('Show All Reports'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  final ReportModel report;
  final Function(ReportModel, ReportStatus) onStatusUpdate;
  final Function(ReportModel) onAddUpdate;

  const _AdminReportCard({
    required this.report,
    required this.onStatusUpdate,
    required this.onAddUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${report.id}',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        Spacer(),
                        _StatusChip(status: report.status),
                      ],
                    ),
                    SizedBox(height: AppConstants.spacingXS),
                    Text(
                      report.category,
                      style: context.textTheme.bodyLarge?.copyWith(
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
                    SizedBox(height: AppConstants.spacingSM),
                    Text(
                      report.description,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFamily: 'Montserrat',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppConstants.spacingSM),
                    Row(
                      children: [
                        Icon(
                          Iconsax.profile,
                          size: 14,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        SizedBox(width: AppConstants.spacingXS),
                        Text(
                          report.tenant.name,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        SizedBox(width: AppConstants.spacingMD),
                        Icon(
                          Iconsax.home_2,
                          size: 14,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        SizedBox(width: AppConstants.spacingXS),
                        Text(
                          report.unitNumber,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ReportStatus>(
                  value: report.status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: ReportStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.name.toUpperCase(),
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (status) {
                    if (status != null && status != report.status) {
                      onStatusUpdate(report, status);
                    }
                  },
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              ElevatedButton.icon(
                onPressed: () => onAddUpdate(report),
                icon: Icon(Iconsax.message_add, size: 16),
                label: Text('Add Update', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ReportStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color getColor() {
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

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSM,
        vertical: AppConstants.spacingXS / 2,
      ),
      decoration: BoxDecoration(
        color: getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: getColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: getColor(),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}