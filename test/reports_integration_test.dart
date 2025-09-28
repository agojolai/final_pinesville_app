// Integration test for the reports feature
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/features/support/data/models/report_model.dart';
import '../lib/src/features/support/controllers/reports_controller.dart';

void main() {
  group('Reports Integration Tests', () {
    test('complete workflow should work correctly', () {
      // Create controller
      final controller = ReportsController();
      
      // Create a report
      final report = Report(
        id: controller.generateReportId(),
        unitNumber: '123-A',
        category: 'Maintenance / Repairs',
        subCategory: 'Plumbing (leaks, clogs, water issues)',
        description: 'Kitchen sink is clogged and water is backing up',
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenantName: 'Test User',
        attachments: ['photo1.jpg'],
        updates: [],
      );

      // Validate report creation
      expect(report.id.startsWith('R'), isTrue);
      expect(report.status, equals(ReportStatus.pending));
      expect(report.attachments.length, equals(1));

      // Test serialization roundtrip
      final json = report.toJson();
      final deserializedReport = Report.fromJson(json);
      
      expect(deserializedReport.id, equals(report.id));
      expect(deserializedReport.unitNumber, equals(report.unitNumber));
      expect(deserializedReport.category, equals(report.category));
      expect(deserializedReport.status, equals(report.status));
      expect(deserializedReport.attachments.length, equals(1));
      expect(deserializedReport.attachments.first, equals('photo1.jpg'));

      // Test report updates
      final update = ReportUpdate(
        message: 'Report received and assigned to maintenance team',
        timestamp: DateTime.now().add(Duration(hours: 1)),
        isAdmin: true,
      );

      final updatedReport = deserializedReport.copyWith(
        status: ReportStatus.inProgress,
        updates: [...deserializedReport.updates, update],
      );

      expect(updatedReport.status, equals(ReportStatus.inProgress));
      expect(updatedReport.updates.length, equals(1));
      expect(updatedReport.updates.first.isAdmin, isTrue);

      // Test final resolution
      final resolvedReport = updatedReport.copyWith(
        status: ReportStatus.resolved,
        resolvedAt: DateTime.now().add(Duration(days: 2)),
      );

      expect(resolvedReport.status, equals(ReportStatus.resolved));
      expect(resolvedReport.resolvedAt, isNotNull);
      
      // Test statistics calculation
      final testReports = [report, updatedReport, resolvedReport];
      final stats = controller.getReportsStatistics(testReports);
      
      expect(stats['total'], equals(3));
      expect(stats['pending'], equals(1));
      expect(stats['inProgress'], equals(1));
      expect(stats['resolved'], equals(1));
    });

    test('edge cases should be handled properly', () {
      // Test empty report list
      final controller = ReportsController();
      final emptyStats = controller.getReportsStatistics([]);
      
      expect(emptyStats['total'], equals(0));
      expect(emptyStats['pending'], equals(0));

      // Test report with minimal data
      final minimalReport = Report(
        id: 'MIN001',
        unitNumber: '999-Z',
        category: 'Test',
        subCategory: '',
        description: 'Minimal test',
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenantName: 'Test User',
      );

      // Should serialize/deserialize without issues
      final json = minimalReport.toJson();
      final deserializedMinimal = Report.fromJson(json);
      
      expect(deserializedMinimal.id, equals('MIN001'));
      expect(deserializedMinimal.subCategory, equals(''));
      expect(deserializedMinimal.attachments, isEmpty);
      expect(deserializedMinimal.updates, isEmpty);
      expect(deserializedMinimal.resolvedAt, isNull);
    });
  });
}