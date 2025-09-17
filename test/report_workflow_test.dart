import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/support/data/models/report_model.dart';
import 'package:untitled/src/features/support/data/utils/admin_test_utils.dart';

void main() {
  group('Report Workflow Integration Test', () {
    late ReportModel testReport;

    setUp(() {
      testReport = ReportModel(
        id: 'TEST001',
        unitNumber: '204-B',
        category: 'Maintenance / Repairs',
        subCategory: 'Plumbing (leaks, clogs, water issues)',
        description: 'Test report for integration testing',
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenant: const ReportTenant(
          userId: 'test-user-123',
          name: 'Test User',
        ),
        attachments: [],
        updates: [],
      );
    });

    test('should create and serialize report correctly', () {
      final json = testReport.toJson();
      
      expect(json['unitNumber'], '204-B');
      expect(json['category'], 'Maintenance / Repairs');
      expect(json['status'], 'pending');
      expect(json['tenant']['userId'], 'test-user-123');
      expect(json['tenant']['name'], 'Test User');
    });

    test('should deserialize report from JSON', () {
      final json = testReport.toJson();
      
      // Simulate Firestore document
      final mockDoc = MockDocumentSnapshot(
        id: 'TEST001',
        data: json,
      );

      final recreatedReport = ReportModel.fromSnapshot(mockDoc);
      
      expect(recreatedReport.id, 'TEST001');
      expect(recreatedReport.unitNumber, testReport.unitNumber);
      expect(recreatedReport.category, testReport.category);
      expect(recreatedReport.status, testReport.status);
      expect(recreatedReport.tenant.userId, testReport.tenant.userId);
    });

    test('should update report status with copyWith', () {
      final resolvedReport = testReport.copyWith(
        status: ReportStatus.resolved,
        resolvedAt: DateTime.now(),
      );

      expect(resolvedReport.status, ReportStatus.resolved);
      expect(resolvedReport.resolvedAt, isNotNull);
      expect(resolvedReport.unitNumber, testReport.unitNumber);
      expect(resolvedReport.id, testReport.id);
    });

    test('should add updates to report', () {
      final update = ReportUpdate(
        message: 'Admin response added',
        timestamp: DateTime.now(),
        isAdmin: true,
      );

      final updatedReport = testReport.copyWith(
        updates: [...testReport.updates, update],
      );

      expect(updatedReport.updates.length, 1);
      expect(updatedReport.updates.first.message, 'Admin response added');
      expect(updatedReport.updates.first.isAdmin, true);
    });

    test('should add feedback to resolved report', () {
      const feedback = ReportFeedback(
        rating: 5,
        comment: 'Excellent service',
      );

      final reportWithFeedback = testReport.copyWith(
        status: ReportStatus.resolved,
        feedback: feedback,
      );

      expect(reportWithFeedback.feedback?.rating, 5);
      expect(reportWithFeedback.feedback?.comment, 'Excellent service');
    });

    test('should provide admin test utilities', () {
      final suggestions = AdminTestUtils.getSuggestedResponses('Maintenance / Repairs');
      
      expect(suggestions, isNotEmpty);
      expect(suggestions.first, contains('Report received'));
    });

    test('should create sample reports for testing', () {
      final sampleReports = AdminTestUtils.createSampleReports(
        'test-user-123',
        'Test User',
        '204-B',
      );

      expect(sampleReports.length, 3);
      expect(sampleReports.first.tenant.userId, 'test-user-123');
      expect(sampleReports.first.unitNumber, '204-B');
    });

    test('should handle different status transitions', () {
      // Test pending to in progress
      var report = testReport;
      expect(report.status, ReportStatus.pending);

      // Simulate admin marking as in progress
      report = report.copyWith(status: ReportStatus.inProgress);
      expect(report.status, ReportStatus.inProgress);

      // Simulate admin resolving
      report = report.copyWith(
        status: ReportStatus.resolved,
        resolvedAt: DateTime.now(),
      );
      expect(report.status, ReportStatus.resolved);
      expect(report.resolvedAt, isNotNull);

      // Simulate closing
      report = report.copyWith(status: ReportStatus.closed);
      expect(report.status, ReportStatus.closed);
    });

    test('should handle attachments correctly', () {
      final reportWithAttachments = testReport.copyWith(
        attachments: ['url1.jpg', 'url2.pdf'],
      );

      expect(reportWithAttachments.attachments.length, 2);
      expect(reportWithAttachments.attachments.first, 'url1.jpg');
    });
  });
}

// Mock DocumentSnapshot for testing (reused from report_repository_test.dart)
class MockDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  
  final Map<String, dynamic>? _data;
  
  MockDocumentSnapshot({required this.id, required Map<String, dynamic> data}) 
      : _data = data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data != null;

  // Implement required abstract methods with minimal functionality for testing
  @override
  DocumentReference<Map<String, dynamic>> get reference => 
      throw UnimplementedError('Mock reference not implemented');

  @override
  SnapshotMetadata get metadata => 
      throw UnimplementedError('Mock metadata not implemented');

  @override
  dynamic get(Object field) => _data?[field];

  @override
  dynamic operator [](Object field) => get(field);
}