// Test for the reports and tickets feature with Firestore integration
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/features/support/data/models/report_model.dart';
import '../lib/src/features/support/controllers/reports_controller.dart';

void main() {
  group('Reports and Tickets Feature Tests', () {
    test('should create a report with proper data', () {
      final report = Report(
        id: 'TEST001',
        unitNumber: '123-A',
        category: 'Test Category',
        subCategory: 'Test Sub-category',
        description: 'Test description',
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenantName: 'Test User',
      );

      expect(report.id, equals('TEST001'));
      expect(report.status, equals(ReportStatus.pending));
      expect(report.tenantName, equals('Test User'));
    });

    test('should serialize and deserialize report correctly', () {
      final now = DateTime.now();
      final report = Report(
        id: 'TEST001',
        unitNumber: '123-A',
        category: 'Test Category',
        subCategory: 'Test Sub-category',
        description: 'Test description',
        status: ReportStatus.pending,
        submittedAt: now,
        tenantName: 'Test User',
        attachments: ['attachment1.jpg', 'attachment2.pdf'],
        updates: [
          ReportUpdate(
            message: 'Test update',
            timestamp: now,
            isAdmin: true,
          ),
        ],
      );

      // Test serialization
      final json = report.toJson();
      expect(json['id'], equals('TEST001'));
      expect(json['status'], equals('pending'));
      expect(json['attachments'], equals(['attachment1.jpg', 'attachment2.pdf']));

      // Test deserialization
      final deserializedReport = Report.fromJson(json);
      expect(deserializedReport.id, equals(report.id));
      expect(deserializedReport.status, equals(report.status));
      expect(deserializedReport.attachments, equals(report.attachments));
      expect(deserializedReport.updates.length, equals(1));
      expect(deserializedReport.updates.first.message, equals('Test update'));
    });

    test('should serialize and deserialize ReportUpdate correctly', () {
      final now = DateTime.now();
      final update = ReportUpdate(
        message: 'Test message',
        timestamp: now,
        isAdmin: false,
      );

      // Test serialization
      final json = update.toJson();
      expect(json['message'], equals('Test message'));
      expect(json['isAdmin'], equals(false));

      // Test deserialization
      final deserializedUpdate = ReportUpdate.fromJson(json);
      expect(deserializedUpdate.message, equals(update.message));
      expect(deserializedUpdate.isAdmin, equals(update.isAdmin));
      expect(deserializedUpdate.timestamp.millisecondsSinceEpoch, 
             equals(update.timestamp.millisecondsSinceEpoch));
    });

    test('controller should generate unique report IDs', () {
      final controller = ReportsController();
      final id1 = controller.generateReportId();
      final id2 = controller.generateReportId();
      
      expect(id1, isNot(equals(id2)));
      expect(id1.startsWith('R'), isTrue);
      expect(id2.startsWith('R'), isTrue);
    });

    test('controller should calculate statistics correctly from report list', () {
      final controller = ReportsController();
      final reports = [
        Report(
          id: 'R001',
          unitNumber: '123-A',
          category: 'Test',
          subCategory: 'Test',
          description: 'Test',
          status: ReportStatus.pending,
          submittedAt: DateTime.now(),
          tenantName: 'Test',
        ),
        Report(
          id: 'R002',
          unitNumber: '123-B',
          category: 'Test',
          subCategory: 'Test',
          description: 'Test',
          status: ReportStatus.inProgress,
          submittedAt: DateTime.now(),
          tenantName: 'Test',
        ),
        Report(
          id: 'R003',
          unitNumber: '123-C',
          category: 'Test',
          subCategory: 'Test',
          description: 'Test',
          status: ReportStatus.resolved,
          submittedAt: DateTime.now(),
          tenantName: 'Test',
        ),
      ];
      
      final stats = controller.getReportsStatistics(reports);
      
      expect(stats['total'], equals(3));
      expect(stats['pending'], equals(1));
      expect(stats['inProgress'], equals(1));
      expect(stats['resolved'], equals(1));
      expect(stats['closed'], equals(0));
    });

    test('should filter reports by status correctly', () {
      final controller = ReportsController();
      final reports = [
        Report(
          id: 'R001',
          unitNumber: '123-A',
          category: 'Test',
          subCategory: 'Test',
          description: 'Test',
          status: ReportStatus.pending,
          submittedAt: DateTime.now(),
          tenantName: 'Test',
        ),
        Report(
          id: 'R002',
          unitNumber: '123-B',
          category: 'Test',
          subCategory: 'Test',
          description: 'Test',
          status: ReportStatus.inProgress,
          submittedAt: DateTime.now(),
          tenantName: 'Test',
        ),
        Report(
          id: 'R003',
          unitNumber: '123-C',
          category: 'Test',
          subCategory: 'Test',
          description: 'Test',
          status: ReportStatus.pending,
          submittedAt: DateTime.now(),
          tenantName: 'Test',
        ),
      ];

      final pendingReports = controller.getReportsByStatus(reports, ReportStatus.pending);
      expect(pendingReports.length, equals(2));
      expect(pendingReports.every((r) => r.status == ReportStatus.pending), isTrue);

      final inProgressReports = controller.getReportsByStatus(reports, ReportStatus.inProgress);
      expect(inProgressReports.length, equals(1));
      expect(inProgressReports.first.id, equals('R002'));
    });

    test('report copyWith should work correctly', () {
      final originalReport = Report(
        id: 'TEST001',
        unitNumber: '123-A',
        category: 'Test Category',
        subCategory: 'Test Sub-category',
        description: 'Test description',
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenantName: 'Test User',
      );

      final updatedReport = originalReport.copyWith(
        status: ReportStatus.resolved,
        resolvedAt: DateTime.now(),
      );

      expect(updatedReport.id, equals(originalReport.id));
      expect(updatedReport.unitNumber, equals(originalReport.unitNumber));
      expect(updatedReport.status, equals(ReportStatus.resolved));
      expect(updatedReport.resolvedAt, isNotNull);
      expect(originalReport.resolvedAt, isNull); // Original should be unchanged
    });
  });
}