import '../models/report_model.dart';
import '../repositories/report_repository.dart';

/// Utility class for simulating admin actions during testing
/// This is used since there's no admin interface implemented yet
class AdminTestUtils {
  static final ReportRepository _reportRepository = ReportRepository.instance;

  /// Simulate admin marking a report as in progress
  static Future<void> markReportInProgress(String reportId, {String? message}) async {
    await _reportRepository.updateReportStatus(reportId, ReportStatus.inProgress);
    
    if (message != null) {
      final update = ReportUpdate(
        message: message,
        timestamp: DateTime.now(),
        isAdmin: true,
      );
      await _reportRepository.addReportUpdate(reportId, update);
    }
  }

  /// Simulate admin resolving a report
  static Future<void> resolveReport(String reportId, {String? message}) async {
    await _reportRepository.updateReportStatus(reportId, ReportStatus.resolved);
    
    if (message != null) {
      final update = ReportUpdate(
        message: message,
        timestamp: DateTime.now(),
        isAdmin: true,
      );
      await _reportRepository.addReportUpdate(reportId, update);
    }
  }

  /// Simulate admin closing a report
  static Future<void> closeReport(String reportId, {String? message}) async {
    await _reportRepository.updateReportStatus(reportId, ReportStatus.closed);
    
    if (message != null) {
      final update = ReportUpdate(
        message: message,
        timestamp: DateTime.now(),
        isAdmin: true,
      );
      await _reportRepository.addReportUpdate(reportId, update);
    }
  }

  /// Add an admin update to a report
  static Future<void> addAdminUpdate(String reportId, String message) async {
    final update = ReportUpdate(
      message: message,
      timestamp: DateTime.now(),
      isAdmin: true,
    );
    await _reportRepository.addReportUpdate(reportId, update);
  }

  /// Get a list of common admin responses based on category
  static List<String> getSuggestedResponses(String category) {
    switch (category.toLowerCase()) {
      case 'maintenance / repairs':
        return [
          'Report received. Maintenance team has been notified.',
          'Technician scheduled for inspection.',
          'Work order created and assigned to maintenance crew.',
          'Repair has been completed. Please verify and confirm.',
        ];
      case 'billing & payment':
        return [
          'Report received. Checking billing records.',
          'Billing inquiry is being reviewed by our accounts team.',
          'Billing issue has been identified and corrected.',
          'Refund will be applied to your next statement.',
        ];
      case 'utilities':
        return [
          'Report received. Utilities team has been contacted.',
          'Investigating the utility issue.',
          'Working with service provider to resolve the issue.',
          'Utility service has been restored.',
        ];
      case 'complaints / concerns':
        return [
          'Report received. We are looking into your concern.',
          'Investigating the reported issue.',
          'Matter has been addressed with the concerned parties.',
          'Issue has been resolved. Thank you for your patience.',
        ];
      default:
        return [
          'Report received and is being reviewed.',
          'We are investigating this matter.',
          'Issue is being addressed.',
          'Matter has been resolved.',
        ];
    }
  }

  /// Create sample reports for testing (admin utility)
  static List<ReportModel> createSampleReports(String userId, String userName, String unitNumber) {
    return [
      ReportModel(
        id: 'R001',
        unitNumber: unitNumber,
        category: 'Maintenance / Repairs',
        subCategory: 'Plumbing (leaks, clogs, water issues)',
        description: 'Kitchen sink is clogged and water is backing up',
        status: ReportStatus.inProgress,
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
        tenant: ReportTenant(userId: userId, name: userName),
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
      ReportModel(
        id: 'R002',
        unitNumber: unitNumber,
        category: 'Billing & Payment',
        subCategory: 'Incorrect billing amount',
        description: 'Monthly rent charged includes utilities but I handle my own utilities',
        status: ReportStatus.resolved,
        submittedAt: DateTime.now().subtract(const Duration(days: 7)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 3)),
        tenant: ReportTenant(userId: userId, name: userName),
        updates: [
          ReportUpdate(
            message: 'Report received. Checking billing records.',
            timestamp: DateTime.now().subtract(const Duration(days: 7)),
            isAdmin: true,
          ),
          ReportUpdate(
            message: 'Billing has been corrected. Refund of ₱500 will be applied to next month.',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            isAdmin: true,
          ),
        ],
      ),
      ReportModel(
        id: 'R003',
        unitNumber: unitNumber,
        category: 'Complaints / Concerns',
        subCategory: 'Noise disturbance',
        description: 'Upstairs neighbor playing loud music past midnight on weekdays',
        status: ReportStatus.pending,
        submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
        tenant: ReportTenant(userId: userId, name: userName),
        updates: [],
      ),
    ];
  }
}