import '../data/models/report_model.dart';

/// Controller for managing reports and tickets
class ReportsController {
  // Sample reports data - in a real app, this would come from a backend service
  List<Report> _reports = [
    Report(
      id: 'R001',
      unitNumber: '204-B',
      category: 'Maintenance / Repairs',
      subCategory: 'Plumbing (leaks, clogs, water issues)',
      description: 'Kitchen sink is clogged and water is backing up',
      status: ReportStatus.inProgress,
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      tenantName: 'Caleb Anderson',
      attachments: [],
      updates: [
        ReportUpdate(
          message: 'Report received. Maintenance team has been notified.',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          isAdmin: true,
        ),
        ReportUpdate(
          message: 'Plumber scheduled for tomorrow morning.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isAdmin: true,
        ),
      ],
    ),
    Report(
      id: 'R002',
      unitNumber: '204-B',
      category: 'Billing & Payment',
      subCategory: 'Incorrect billing amount',
      description: 'Monthly rent charged includes utilities but I handle my own utilities',
      status: ReportStatus.resolved,
      submittedAt: DateTime.now().subtract(const Duration(days: 7)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 3)),
      tenantName: 'Caleb Anderson',
      attachments: [],
      updates: [
        ReportUpdate(
          message: 'Report received. Checking billing records.',
          timestamp: DateTime.now().subtract(const Duration(days: 7)),
          isAdmin: true,
        ),
        ReportUpdate(
          message: 'Billing error confirmed. Adjustment will appear on next statement.',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          isAdmin: true,
        ),
      ],
    ),
    Report(
      id: 'R003',
      unitNumber: '204-B',
      category: 'Complaints / Concerns',
      subCategory: 'Noise disturbance',
      description: 'Upstairs neighbor is consistently loud during late night hours',
      status: ReportStatus.pending,
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      tenantName: 'Caleb Anderson',
      attachments: [],
      updates: [],
    ),
  ];

  /// Get all reports
  List<Report> get reports => List.unmodifiable(_reports);

  /// Get report by ID
  Report? getReportById(String id) {
    try {
      return _reports.firstWhere((report) => report.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add a new report
  void addReport(Report report) {
    _reports.insert(0, report);
  }

  /// Update an existing report
  void updateReport(Report updatedReport) {
    final index = _reports.indexWhere((report) => report.id == updatedReport.id);
    if (index != -1) {
      _reports[index] = updatedReport;
    }
  }

  /// Remove a report (archive)
  void removeReport(String reportId) {
    _reports.removeWhere((report) => report.id == reportId);
  }

  /// Generate a unique report ID
  String generateReportId() {
    return 'R${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  /// Get reports by status
  List<Report> getReportsByStatus(ReportStatus status) {
    return _reports.where((report) => report.status == status).toList();
  }

  /// Get reports count by status
  int getReportsCountByStatus(ReportStatus status) {
    return _reports.where((report) => report.status == status).length;
  }

  /// Get statistics
  Map<String, int> getReportsStatistics() {
    return {
      'total': _reports.length,
      'pending': getReportsCountByStatus(ReportStatus.pending),
      'inProgress': getReportsCountByStatus(ReportStatus.inProgress),
      'resolved': getReportsCountByStatus(ReportStatus.resolved),
      'closed': getReportsCountByStatus(ReportStatus.closed),
    };
  }
}