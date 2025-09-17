import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/repositories/user_repository.dart';

/// Service class to handle business logic for reports
class ReportService {
  static ReportService? _instance;
  static ReportService get instance => _instance ??= ReportService._();
  
  ReportService._();

  final ReportRepository _reportRepository = ReportRepository.instance;
  final UserRepository _userRepository = UserRepository.instance;
  final AuthRepository _authRepository = AuthRepository.instance;

  /// Submit a new report with attachments
  Future<String> submitReport({
    required String unitNumber,
    required String category,
    required String subCategory,
    required String description,
    List<XFile>? attachments,
  }) async {
    try {
      // Get current user information
      final user = await _userRepository.fetchUserDetails();
      if (user.id == null || user.id!.isEmpty) {
        throw Exception('User not found. Please login again.');
      }

      // Create report model without attachments first
      final report = ReportModel(
        unitNumber: unitNumber,
        category: category,
        subCategory: subCategory,
        description: description,
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenant: ReportTenant(
          userId: user.id!,
          name: user.fullName,
        ),
        attachments: [],
        updates: [
          ReportUpdate(
            message: 'Report submitted successfully and is awaiting review.',
            timestamp: DateTime.now(),
            isAdmin: false,
          ),
        ],
      );

      // Save report to get the ID
      final reportId = await _reportRepository.saveReport(report);

      // Upload attachments if any
      List<String> attachmentUrls = [];
      if (attachments != null && attachments.isNotEmpty) {
        attachmentUrls = await _reportRepository.uploadAttachments(reportId, attachments);
        
        // Update report with attachment URLs
        final updatedReport = report.copyWith(
          id: reportId,
          attachments: attachmentUrls,
        );
        
        // Update the report in Firestore with attachment URLs
        await _updateReportAttachments(reportId, attachmentUrls);
      }

      return reportId;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Get reports for the current user
  Future<List<ReportModel>> getUserReports() async {
    try {
      final user = await _userRepository.fetchUserDetails();
      if (user.id == null || user.id!.isEmpty) {
        throw Exception('User not found. Please login again.');
      }

      return await _reportRepository.fetchUserReports(user.id!);
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get a specific report by ID
  Future<ReportModel> getReport(String reportId) async {
    try {
      return await _reportRepository.fetchReport(reportId);
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  /// Get real-time stream of user reports
  Stream<List<ReportModel>> getUserReportsStream() {
    try {
      final user = _authRepository.authUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      return _reportRepository.getUserReportsStream(user.uid);
    } catch (e) {
      throw Exception('Failed to get reports stream: $e');
    }
  }

  /// Get real-time stream of a specific report
  Stream<ReportModel> getReportStream(String reportId) {
    try {
      return _reportRepository.getReportStream(reportId);
    } catch (e) {
      throw Exception('Failed to get report stream: $e');
    }
  }

  /// Submit feedback for a resolved report
  Future<void> submitFeedback(String reportId, int rating, String comment) async {
    try {
      final feedback = ReportFeedback(
        rating: rating,
        comment: comment,
      );

      await _reportRepository.addReportFeedback(reportId, feedback);
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  /// Add a tenant update to a report
  Future<void> addTenantUpdate(String reportId, String message) async {
    try {
      final update = ReportUpdate(
        message: message,
        timestamp: DateTime.now(),
        isAdmin: false,
      );

      await _reportRepository.addReportUpdate(reportId, update);
    } catch (e) {
      throw Exception('Failed to add update: $e');
    }
  }

  /// Check if user can submit feedback (report must be resolved)
  bool canSubmitFeedback(ReportModel report) {
    return report.status == ReportStatus.resolved && report.feedback == null;
  }

  /// Check if user can add updates (report must not be closed)
  bool canAddUpdate(ReportModel report) {
    return report.status != ReportStatus.closed;
  }

  /// Get status display text
  String getStatusDisplayText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending Review';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.closed:
        return 'Closed';
    }
  }

  /// Get status description for user
  String getStatusDescription(ReportStatus status) {
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

  /// Helper method to update report attachments
  Future<void> _updateReportAttachments(String reportId, List<String> attachmentUrls) async {
    await _reportRepository.updateReportField(reportId, {
      'attachments': attachmentUrls,
    });
  }

  /// Get summary statistics for user reports
  Future<Map<String, int>> getUserReportStats() async {
    try {
      final reports = await getUserReports();
      
      final stats = <String, int>{
        'total': reports.length,
        'pending': 0,
        'inProgress': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (final report in reports) {
        switch (report.status) {
          case ReportStatus.pending:
            stats['pending'] = (stats['pending'] ?? 0) + 1;
            break;
          case ReportStatus.inProgress:
            stats['inProgress'] = (stats['inProgress'] ?? 0) + 1;
            break;
          case ReportStatus.resolved:
            stats['resolved'] = (stats['resolved'] ?? 0) + 1;
            break;
          case ReportStatus.closed:
            stats['closed'] = (stats['closed'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get report statistics: $e');
    }
  }
}