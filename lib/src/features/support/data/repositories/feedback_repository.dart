import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/repositories/auth_repository.dart';
import '../models/report_model.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(
    firestore: FirebaseFirestore.instance,
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class FeedbackRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  FeedbackRepository({
    required FirebaseFirestore firestore,
    required AuthRepository authRepository,
  })  : _firestore = firestore,
        _authRepository = authRepository;

  Future<void> submitFeedbackAndCloseReport({
    required String reportId,
    required int rating,
    required String comments,
  }) async {
    final user = _authRepository.authUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final reportRef = _firestore.collection('reports').doc(reportId);

    await _firestore.runTransaction((transaction) async {
      // Get the current report data
      final reportSnapshot = await transaction.get(reportRef);
      if (!reportSnapshot.exists) {
        throw Exception('Report not found');
      }

      final reportData = reportSnapshot.data()!;
      final currentUpdates = List<Map<String, dynamic>>.from(reportData['updates'] ?? []);

      // Add feedback to the report document
      final feedbackData = {
        'rating': rating,
        'comment': comments,
      };

      // Add a final update message
      final finalUpdate = {
        'message': 'Report closed. Thank you for your feedback!',
        'timestamp': DateTime.now().toIso8601String(),
        'isAdmin': true,
      };
      currentUpdates.add(finalUpdate);

      // Update the report with feedback, closed status, and final update
      transaction.update(reportRef, {
        'status': ReportStatus.closed.name,
        'feedback': feedbackData,
        'updates': currentUpdates,
        'closedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> closeReport({
    required String reportId,
  }) async {
    final user = _authRepository.authUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final reportRef = _firestore.collection('reports').doc(reportId);

    await _firestore.runTransaction((transaction) async {
      // Get the current report data
      final reportSnapshot = await transaction.get(reportRef);
      if (!reportSnapshot.exists) {
        throw Exception('Report not found');
      }

      final reportData = reportSnapshot.data()!;
      final currentUpdates = List<Map<String, dynamic>>.from(reportData['updates'] ?? []);

      // Add a final update message
      final finalUpdate = {
        'message': 'Report closed without feedback.',
        'timestamp': DateTime.now().toIso8601String(),
        'isAdmin': true,
      };
      currentUpdates.add(finalUpdate);

      // Update the report status to closed
      transaction.update(reportRef, {
        'status': ReportStatus.closed.name,
        'updates': currentUpdates,
        'closedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
