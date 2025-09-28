// Basic test for the reports and tickets feature
import 'package:test/test.dart';
import '../lib/src/features/support/data/models/report_model.dart';
import '../lib/src/features/support/controllers/reports_controller.dart';

void main() {
  group('Reports and Tickets Feature Tests', () {
    late ReportsController controller;

    setUp(() {
      controller = ReportsController();
    });

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

    test('controller should manage reports correctly', () {
      final initialCount = controller.reports.length;
      
      final newReport = Report(
        id: 'TEST002',
        unitNumber: '123-B',
        category: 'Test Category',
        subCategory: 'Test Sub-category',
        description: 'Test description 2',
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenantName: 'Test User 2',
      );

      controller.addReport(newReport);
      expect(controller.reports.length, equals(initialCount + 1));
      
      final retrieved = controller.getReportById('TEST002');
      expect(retrieved, isNotNull);
      expect(retrieved!.tenantName, equals('Test User 2'));

      controller.removeReport('TEST002');
      expect(controller.reports.length, equals(initialCount));
    });

    test('controller should provide correct statistics', () {
      final stats = controller.getReportsStatistics();
      
      expect(stats.containsKey('total'), isTrue);
      expect(stats.containsKey('pending'), isTrue);
      expect(stats.containsKey('inProgress'), isTrue);
      expect(stats.containsKey('resolved'), isTrue);
      expect(stats.containsKey('closed'), isTrue);
    });

    test('should generate unique report IDs', () {
      final id1 = controller.generateReportId();
      final id2 = controller.generateReportId();
      
      expect(id1, isNot(equals(id2)));
      expect(id1.startsWith('R'), isTrue);
      expect(id2.startsWith('R'), isTrue);
    });
  });
}