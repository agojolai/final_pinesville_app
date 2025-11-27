import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:image_picker/image_picker.dart';
import '../data/models/report_model.dart';
import '../data/repositories/report_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../auth/data/models/user_model.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/utils/app_logger.dart';

// Report Repository Provider
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository.instance;
});

// Current User's Reports Stream Provider - Reactive to auth changes
final tenantReportsProvider = StreamProvider<List<ReportModel>>((ref) async* {
  final reportRepository = ref.watch(reportRepositoryProvider);
  
  AppLogger.debug('📋 tenantReportsProvider: Starting to listen to auth state changes');
  
  // Listen to Firebase auth state changes to react to account switching
  await for (final authUser in firebase_auth.FirebaseAuth.instance.authStateChanges()) {
    if (authUser == null) {
      AppLogger.debug('📋 tenantReportsProvider: User logged out - yielding empty reports list');
      yield [];
      continue;
    }

    AppLogger.debug('📋 tenantReportsProvider: Fetching reports for user ${authUser.uid}');
    
    // Stream reports for the current authenticated user
    await for (final reports in reportRepository.streamTenantReports(authUser.uid)) {
      AppLogger.debug('📋 tenantReportsProvider: Yielding ${reports.length} reports for user ${authUser.uid}');
      yield reports;
    }
  }
});

// All Reports Stream Provider (Admin function)
final allReportsProvider = StreamProvider<List<ReportModel>>((ref) async* {
  final reportRepository = ref.watch(reportRepositoryProvider);
  yield* reportRepository.streamAllReports();
});

// Reports Stats Provider
final reportsStatsProvider = Provider<ReportsStats>((ref) {
  final reportsAsync = ref.watch(tenantReportsProvider);
  
  return reportsAsync.when(
    data: (reports) {
      // Note: Closed reports are now filtered out at the query level
      final pendingCount = reports.where((r) => r.status == ReportStatus.pending).length;
      final inProgressCount = reports.where((r) => r.status == ReportStatus.inProgress).length;
      final resolvedCount = reports.where((r) => r.status == ReportStatus.resolved).length;
      // closedCount is 0 since we filter out closed reports for tenant view
      
      return ReportsStats(
        totalReports: reports.length,
        pendingCount: pendingCount,
        inProgressCount: inProgressCount,
        resolvedCount: resolvedCount,
        closedCount: 0, // Always 0 for tenant view to minimize reads
      );
    },
    loading: () => ReportsStats.empty(),
    error: (_, __) => ReportsStats.empty(),
  );
});

// Report Submission State Provider
final reportSubmissionProvider = StateNotifierProvider<ReportSubmissionNotifier, ReportSubmissionState>((ref) {
  final reportRepository = ref.watch(reportRepositoryProvider);
  final userProfile = ref.watch(userProfileProvider);
  return ReportSubmissionNotifier(reportRepository, userProfile);
});

// Report Submission State Classes
enum ReportSubmissionStatus { idle, loading, success, error }

class ReportSubmissionState {
  final ReportSubmissionStatus status;
  final String? errorMessage;
  final String? successMessage;
  final ReportModel? submittedReport;

  const ReportSubmissionState({
    this.status = ReportSubmissionStatus.idle,
    this.errorMessage,
    this.successMessage,
    this.submittedReport,
  });

  ReportSubmissionState copyWith({
    ReportSubmissionStatus? status,
    String? errorMessage,
    String? successMessage,
    ReportModel? submittedReport,
  }) {
    return ReportSubmissionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      submittedReport: submittedReport ?? this.submittedReport,
    );
  }
}

// Reports Stats Class
class ReportsStats {
  final int totalReports;
  final int pendingCount;
  final int inProgressCount;
  final int resolvedCount;
  final int closedCount;

  const ReportsStats({
    required this.totalReports,
    required this.pendingCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.closedCount,
  });

  static ReportsStats empty() {
    return const ReportsStats(
      totalReports: 0,
      pendingCount: 0,
      inProgressCount: 0,
      resolvedCount: 0,
      closedCount: 0,
    );
  }
}

// Report Submission Notifier
class ReportSubmissionNotifier extends StateNotifier<ReportSubmissionState> {
  final ReportRepository _reportRepository;
  final AsyncValue<UserModel> _userProfile;

  ReportSubmissionNotifier(this._reportRepository, this._userProfile) 
    : super(const ReportSubmissionState());

  // Submit a new report
  Future<void> submitReport({
    required String category,
    required String subCategory,
    required String description,
    List<XFile>? attachmentFiles,
  }) async {
    state = state.copyWith(status: ReportSubmissionStatus.loading);

    try {
      // Get user data
      final userModel = _userProfile.asData?.value;
      if (userModel == null) {
        throw Exception('User profile not available');
      }

      // Get current user info
      final currentUser = AuthRepository.instance.authUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Submit report
      final report = await _reportRepository.submitReport(
        unitNumber: userModel.unitId,
        propertyName: userModel.propertyName,
        category: category,
        subCategory: subCategory,
        description: description,
        tenantUserId: currentUser.uid,
        tenantName: '${userModel.firstName} ${userModel.lastName}',
        attachmentFiles: attachmentFiles,
      );

      state = state.copyWith(
        status: ReportSubmissionStatus.success,
        successMessage: 'Report submitted successfully',
        submittedReport: report,
      );
    } catch (e) {
      state = state.copyWith(
        status: ReportSubmissionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // Reset state to idle
  void resetState() {
    state = const ReportSubmissionState();
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(
      status: ReportSubmissionStatus.idle,
      errorMessage: null,
    );
  }

  // Clear success message
  void clearSuccess() {
    state = state.copyWith(
      status: ReportSubmissionStatus.idle,
      successMessage: null,
      submittedReport: null,
    );
  }
}

// Individual Report Provider (for report details)
final reportProvider = FutureProviderFamily<ReportModel?, String>((ref, reportId) async {
  final reportRepository = ref.watch(reportRepositoryProvider);
  return await reportRepository.getReportById(reportId);
});

// Report Status Update Provider
final reportStatusUpdateProvider = StateNotifierProvider<ReportStatusUpdateNotifier, AsyncValue<void>>((ref) {
  final reportRepository = ref.watch(reportRepositoryProvider);
  return ReportStatusUpdateNotifier(reportRepository);
});

// Report Status Update Notifier
class ReportStatusUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final ReportRepository _reportRepository;

  ReportStatusUpdateNotifier(this._reportRepository) : super(const AsyncValue.data(null));

  // Update report status (Admin function)
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? message,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _reportRepository.updateReportStatus(
        reportId: reportId,
        status: newStatus,
        message: message,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}