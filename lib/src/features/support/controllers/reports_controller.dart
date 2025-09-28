import '../data/models/report_model.dart';
import '../data/repositories/reports_repository.dart';

/// Controller for managing reports and tickets with Firestore integration
class ReportsController {
  final ReportsRepository _repository = ReportsRepository.instance;

  /// Get all reports for the current user
  Future<List<Report>> getReports() async {
    try {
      return await _repository.fetchUserReports();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get real-time stream of user reports
  Stream<List<Report>> streamReports() {
    return _repository.streamUserReports();
  }

  /// Get report by ID
  Future<Report?> getReportById(String id) async {
    try {
      return await _repository.getReportById(id);
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  /// Add a new report
  Future<void> addReport(Report report) async {
    try {
      await _repository.submitReport(report);
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Update an existing report
  Future<void> updateReport(Report updatedReport) async {
    try {
      await _repository.updateReport(updatedReport);
    } catch (e) {
      throw Exception('Failed to update report: $e');
    }
  }

  /// Remove a report (archive)
  Future<void> removeReport(String reportId) async {
    try {
      await _repository.deleteReport(reportId);
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  /// Generate a unique report ID
  String generateReportId() {
    return _repository.generateReportId();
  }

  /// Add an update to a report
  Future<void> addReportUpdate(String reportId, ReportUpdate update) async {
    try {
      await _repository.addReportUpdate(reportId, update);
    } catch (e) {
      throw Exception('Failed to add report update: $e');
    }
  }

  /// Update report status
  Future<void> updateReportStatus(String reportId, ReportStatus status, {DateTime? resolvedAt}) async {
    try {
      await _repository.updateReportStatus(reportId, status, resolvedAt: resolvedAt);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Get reports by status (from fetched data)
  List<Report> getReportsByStatus(List<Report> reports, ReportStatus status) {
    return reports.where((report) => report.status == status).toList();
  }

  /// Get reports count by status (from fetched data)
  int getReportsCountByStatus(List<Report> reports, ReportStatus status) {
    return reports.where((report) => report.status == status).length;
  }

  /// Get statistics (from fetched data)
  Map<String, int> getReportsStatistics(List<Report> reports) {
    return {
      'total': reports.length,
      'pending': getReportsCountByStatus(reports, ReportStatus.pending),
      'inProgress': getReportsCountByStatus(reports, ReportStatus.inProgress),
      'resolved': getReportsCountByStatus(reports, ReportStatus.resolved),
      'closed': getReportsCountByStatus(reports, ReportStatus.closed),
    };
  }

  // ADMIN METHODS

  /// Fetch all reports across all users (admin only)
  Future<List<Report>> getAllReports() async {
    try {
      return await _repository.fetchAllReports();
    } catch (e) {
      throw Exception('Failed to fetch all reports: $e');
    }
  }

  /// Get global statistics across all users (admin only)
  Future<Map<String, int>> getGlobalStatistics() async {
    try {
      return await _repository.fetchGlobalReportsStatistics();
    } catch (e) {
      throw Exception('Failed to fetch global statistics: $e');
    }
  }

  /// Stream all reports across all users (admin only)
  Stream<List<Report>> streamAllReports() {
    return _repository.streamAllReports();
  }

  /// Update any report by admin
  Future<void> adminUpdateReport(String userId, Report report) async {
    try {
      await _repository.adminUpdateReport(userId, report);
    } catch (e) {
      throw Exception('Failed to update report as admin: $e');
    }
  }

  /// Create sample reports for testing
  Future<void> createSampleData() async {
    try {
      await _repository.createSampleReports();
    } catch (e) {
      throw Exception('Failed to create sample data: $e');
    }
  }

  /// Clear all reports for testing
  Future<void> clearAllData() async {
    try {
      await _repository.clearAllReports();
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }
}