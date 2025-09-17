import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/src/features/support/data/models/report_model.dart';
import 'package:untitled/src/features/support/data/repositories/report_repository.dart';

// Mock data for testing
void main() {
  group('ReportRepository', () {
    late ReportRepository repository;
    late ReportModel testReport;
    
    setUpAll(() {
      // Initialize Firebase for testing would go here in a real scenario
      // For now, we'll just create instances for unit testing
      repository = ReportRepository.instance;
    });

    setUp(() {
      // Create test report data
      testReport = ReportModel(
        unitNumber: '204-B',
        category: 'Maintenance / Repairs',
        subCategory: 'Plumbing (leaks, clogs, water issues)',
        description: 'Test plumbing issue',
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenant: const ReportTenant(
          userId: 'test-user-id',
          name: 'Test User',
        ),
        attachments: [],
        updates: [],
      );
    });

    test('should create empty report model', () {
      final emptyReport = ReportModel.empty();
      expect(emptyReport.id, isEmpty);
      expect(emptyReport.unitNumber, isEmpty);
      expect(emptyReport.status, ReportStatus.pending);
    });

    test('should convert report to JSON properly', () {
      final json = testReport.toJson();
      
      expect(json['unitNumber'], '204-B');
      expect(json['category'], 'Maintenance / Repairs');
      expect(json['status'], 'pending');
      expect(json['tenant']['userId'], 'test-user-id');
      expect(json['tenant']['name'], 'Test User');
    });

    test('should create report from JSON properly', () {
      final json = testReport.toJson();
      
      // Simulate Firestore document
      final mockDoc = MockDocumentSnapshot(
        id: 'test-report-id',
        data: json,
      );

      final recreatedReport = ReportModel.fromSnapshot(mockDoc);
      
      expect(recreatedReport.id, 'test-report-id');
      expect(recreatedReport.unitNumber, testReport.unitNumber);
      expect(recreatedReport.category, testReport.category);
      expect(recreatedReport.status, testReport.status);
      expect(recreatedReport.tenant.userId, testReport.tenant.userId);
    });

    test('should copy report with updated values', () {
      final updatedReport = testReport.copyWith(
        status: ReportStatus.resolved,
        resolvedAt: DateTime.now(),
      );

      expect(updatedReport.status, ReportStatus.resolved);
      expect(updatedReport.resolvedAt, isNotNull);
      expect(updatedReport.unitNumber, testReport.unitNumber); // Should remain same
    });

    test('should handle ReportUpdate serialization', () {
      final update = ReportUpdate(
        message: 'Test update',
        timestamp: DateTime.now(),
        isAdmin: true,
      );

      final json = update.toJson();
      expect(json['message'], 'Test update');
      expect(json['isAdmin'], true);

      final recreatedUpdate = ReportUpdate.fromJson(json);
      expect(recreatedUpdate.message, 'Test update');
      expect(recreatedUpdate.isAdmin, true);
    });

    test('should handle ReportFeedback serialization', () {
      const feedback = ReportFeedback(
        rating: 5,
        comment: 'Excellent service',
      );

      final json = feedback.toJson();
      expect(json['rating'], 5);
      expect(json['comment'], 'Excellent service');

      final recreatedFeedback = ReportFeedback.fromJson(json);
      expect(recreatedFeedback.rating, 5);
      expect(recreatedFeedback.comment, 'Excellent service');
    });

    test('should handle ReportTenant serialization', () {
      const tenant = ReportTenant(
        userId: 'test-user-id',
        name: 'Test User',
      );

      final json = tenant.toJson();
      expect(json['userId'], 'test-user-id');
      expect(json['name'], 'Test User');

      final recreatedTenant = ReportTenant.fromJson(json);
      expect(recreatedTenant.userId, 'test-user-id');
      expect(recreatedTenant.name, 'Test User');
    });

    test('should parse status strings correctly', () {
      final testData = [
        ('pending', ReportStatus.pending),
        ('inProgress', ReportStatus.inProgress),
        ('resolved', ReportStatus.resolved),
        ('closed', ReportStatus.closed),
        ('invalid', ReportStatus.pending), // Should default to pending
      ];

      for (final (statusStr, expectedStatus) in testData) {
        final mockDoc = MockDocumentSnapshot(
          id: 'test-id',
          data: {
            'status': statusStr,
            'unitNumber': '204-B',
            'category': 'Test',
            'subCategory': 'Test',
            'description': 'Test',
            'submittedAt': DateTime.now().toIso8601String(),
            'tenant': {'userId': 'test', 'name': 'test'},
          },
        );

        final report = ReportModel.fromSnapshot(mockDoc);
        expect(report.status, expectedStatus);
      }
    });
  });
}

// Mock DocumentSnapshot for testing
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