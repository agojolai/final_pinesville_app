import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/feedback_repository.dart';

enum FeedbackSubmissionStatus { initial, loading, success, error }

class FeedbackSubmissionState {
  final FeedbackSubmissionStatus status;
  final String? errorMessage;

  FeedbackSubmissionState({
    this.status = FeedbackSubmissionStatus.initial,
    this.errorMessage,
  });

  FeedbackSubmissionState copyWith({
    FeedbackSubmissionStatus? status,
    String? errorMessage,
  }) {
    return FeedbackSubmissionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final feedbackSubmissionProvider = StateNotifierProvider<
    FeedbackSubmissionNotifier, FeedbackSubmissionState>((ref) {
  return FeedbackSubmissionNotifier(ref.watch(feedbackRepositoryProvider));
});

class FeedbackSubmissionNotifier
    extends StateNotifier<FeedbackSubmissionState> {
  final FeedbackRepository _feedbackRepository;

  FeedbackSubmissionNotifier(this._feedbackRepository)
      : super(FeedbackSubmissionState());

  Future<void> submitFeedback({
    required String reportId,
    required int rating,
    required String comments,
  }) async {
    state = state.copyWith(status: FeedbackSubmissionStatus.loading);
    try {
      await _feedbackRepository.submitFeedbackAndCloseReport(
        reportId: reportId,
        rating: rating,
        comments: comments,
      );
      state = state.copyWith(status: FeedbackSubmissionStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: FeedbackSubmissionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> closeReportWithoutFeedback({
    required String reportId,
  }) async {
    state = state.copyWith(status: FeedbackSubmissionStatus.loading);
    try {
      await _feedbackRepository.closeReport(reportId: reportId);
      state = state.copyWith(status: FeedbackSubmissionStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: FeedbackSubmissionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
