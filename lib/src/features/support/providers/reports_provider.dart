import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/reports_controller.dart';
import '../data/models/report_model.dart';

/// Provider for the reports controller
final reportsControllerProvider = Provider<ReportsController>((ref) {
  return ReportsController();
});

/// State notifier for managing reports
class ReportsNotifier extends StateNotifier<List<Report>> {
  final ReportsController _controller;

  ReportsNotifier(this._controller) : super(_controller.reports);

  /// Add a new report
  void addReport(Report report) {
    _controller.addReport(report);
    state = _controller.reports;
  }

  /// Update an existing report
  void updateReport(Report report) {
    _controller.updateReport(report);
    state = _controller.reports;
  }

  /// Remove a report (archive)
  void removeReport(String reportId) {
    _controller.removeReport(reportId);
    state = _controller.reports;
  }

  /// Get report by ID
  Report? getReportById(String id) {
    return _controller.getReportById(id);
  }

  /// Generate unique report ID
  String generateReportId() {
    return _controller.generateReportId();
  }

  /// Get reports by status
  List<Report> getReportsByStatus(ReportStatus status) {
    return _controller.getReportsByStatus(status);
  }

  /// Get reports statistics
  Map<String, int> getReportsStatistics() {
    return _controller.getReportsStatistics();
  }
}

/// Provider for the reports state notifier
final reportsProvider = StateNotifierProvider<ReportsNotifier, List<Report>>((ref) {
  final controller = ref.watch(reportsControllerProvider);
  return ReportsNotifier(controller);
});

/// Provider for reports statistics
final reportsStatsProvider = Provider<Map<String, int>>((ref) {
  final reportsNotifier = ref.watch(reportsProvider.notifier);
  return reportsNotifier.getReportsStatistics();
});