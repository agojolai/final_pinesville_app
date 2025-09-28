import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/reports_controller.dart';
import '../data/models/report_model.dart';

/// Provider for the reports controller
final reportsControllerProvider = Provider<ReportsController>((ref) {
  return ReportsController();
});

/// Provider for streaming user reports from Firestore
final reportsStreamProvider = StreamProvider<List<Report>>((ref) {
  final controller = ref.watch(reportsControllerProvider);
  return controller.streamReports();
});

/// Provider for reports statistics based on streamed data
final reportsStatsProvider = Provider<Map<String, int>>((ref) {
  final reportsAsyncValue = ref.watch(reportsStreamProvider);
  
  return reportsAsyncValue.when(
    data: (reports) {
      final controller = ref.watch(reportsControllerProvider);
      return controller.getReportsStatistics(reports);
    },
    loading: () => {
      'total': 0,
      'pending': 0,
      'inProgress': 0,
      'resolved': 0,
      'closed': 0,
    },
    error: (_, __) => {
      'total': 0,
      'pending': 0,
      'inProgress': 0,
      'resolved': 0,
      'closed': 0,
    },
  );
});

/// State notifier for managing reports actions
class ReportsNotifier extends StateNotifier<AsyncValue<void>> {
  final ReportsController _controller;

  ReportsNotifier(this._controller) : super(const AsyncValue.data(null));

  /// Add a new report
  Future<void> addReport(Report report) async {
    state = const AsyncValue.loading();
    try {
      await _controller.addReport(report);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update an existing report
  Future<void> updateReport(Report report) async {
    state = const AsyncValue.loading();
    try {
      await _controller.updateReport(report);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Remove a report (archive)
  Future<void> removeReport(String reportId) async {
    state = const AsyncValue.loading();
    try {
      await _controller.removeReport(reportId);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Add an update to a report
  Future<void> addReportUpdate(String reportId, ReportUpdate update) async {
    state = const AsyncValue.loading();
    try {
      await _controller.addReportUpdate(reportId, update);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update report status
  Future<void> updateReportStatus(String reportId, ReportStatus status, {DateTime? resolvedAt}) async {
    state = const AsyncValue.loading();
    try {
      await _controller.updateReportStatus(reportId, status, resolvedAt: resolvedAt);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Generate unique report ID
  String generateReportId() {
    return _controller.generateReportId();
  }

  /// Create sample data for testing
  Future<void> createSampleData() async {
    state = const AsyncValue.loading();
    try {
      await _controller.createSampleData();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Clear all data for testing
  Future<void> clearAllData() async {
    state = const AsyncValue.loading();
    try {
      await _controller.clearAllData();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Provider for the reports action notifier
final reportsActionProvider = StateNotifierProvider<ReportsNotifier, AsyncValue<void>>((ref) {
  final controller = ref.watch(reportsControllerProvider);
  return ReportsNotifier(controller);
});

// ADMIN PROVIDERS

/// Provider for streaming all reports across all users (admin only)
final adminReportsStreamProvider = StreamProvider<List<Report>>((ref) {
  final controller = ref.watch(reportsControllerProvider);
  return controller.streamAllReports();
});

/// Provider for global statistics (admin only)
final adminStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final controller = ref.watch(reportsControllerProvider);
  return controller.getGlobalStatistics();
});

/// Admin state notifier for cross-user operations
class AdminReportsNotifier extends StateNotifier<AsyncValue<void>> {
  final ReportsController _controller;

  AdminReportsNotifier(this._controller) : super(const AsyncValue.data(null));

  /// Update any report by admin
  Future<void> adminUpdateReport(String userId, Report report) async {
    state = const AsyncValue.loading();
    try {
      await _controller.adminUpdateReport(userId, report);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

/// Provider for admin actions
final adminReportsActionProvider = StateNotifierProvider<AdminReportsNotifier, AsyncValue<void>>((ref) {
  final controller = ref.watch(reportsControllerProvider);
  return AdminReportsNotifier(controller);
});