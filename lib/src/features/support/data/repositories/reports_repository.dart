import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../../../core/exceptions/firebase_exceptions.dart' as custom_firebase;
import '../../../../core/exceptions/format_exceptions.dart' as custom_format;
import '../../../../core/exceptions/platform_exceptions.dart' as custom_platform;
import '../../../../core/repositories/auth_repository.dart';
import '../models/report_model.dart';

/// Repository for managing reports data in Firestore
class ReportsRepository {
  static ReportsRepository? _instance;
  static ReportsRepository get instance => _instance ??= ReportsRepository._();
  
  ReportsRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String get _currentUserId => AuthRepository.instance.authUser?.uid ?? '';

  /// Collection reference for reports
  CollectionReference<Map<String, dynamic>> get _reportsCollection {
    if (_currentUserId.isEmpty) {
      throw Exception('User not authenticated. Please log in to access reports.');
    }
    return _db.collection('Users').doc(_currentUserId).collection('Reports');
  }

  /// Submit a new report to Firestore
  Future<void> submitReport(Report report) async {
    try {
      await _reportsCollection
          .doc(report.id)
          .set(report.toJson());
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error submitting report: $e');
    }
  }

  /// Fetch all reports for the current user
  Future<List<Report>> fetchUserReports() async {
    try {
      final querySnapshot = await _reportsCollection
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Report.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  /// Get real-time stream of user reports
  Stream<List<Report>> streamUserReports() {
    try {
      return _reportsCollection
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Report.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw Exception('Error streaming reports: $e');
    }
  }

  /// Get a specific report by ID
  Future<Report?> getReportById(String reportId) async {
    try {
      final docSnapshot = await _reportsCollection.doc(reportId).get();
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return Report.fromJson(docSnapshot.data()!);
      }
      return null;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching report: $e');
    }
  }

  /// Update an existing report
  Future<void> updateReport(Report report) async {
    try {
      await _reportsCollection
          .doc(report.id)
          .update(report.toJson());
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error updating report: $e');
    }
  }

  /// Delete a report (archive)
  Future<void> deleteReport(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).delete();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error deleting report: $e');
    }
  }

  /// Add an update to a report
  Future<void> addReportUpdate(String reportId, ReportUpdate update) async {
    try {
      final reportDoc = _reportsCollection.doc(reportId);
      await reportDoc.update({
        'updates': FieldValue.arrayUnion([update.toJson()])
      });
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error adding report update: $e');
    }
  }

  /// Update report status
  Future<void> updateReportStatus(String reportId, ReportStatus status, {DateTime? resolvedAt}) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status.name,
      };

      if (resolvedAt != null) {
        updateData['resolvedAt'] = resolvedAt.toIso8601String();
      }

      await _reportsCollection.doc(reportId).update(updateData);
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error updating report status: $e');
    }
  }

  /// Generate a unique report ID
  String generateReportId() {
    return 'R${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  // ADMIN UTILITIES METHODS

  /// Fetch all reports across all users (for admin use)
  Future<List<Report>> fetchAllReports() async {
    try {
      final usersCollection = _db.collection('Users');
      final userSnapshots = await usersCollection.get();
      
      List<Report> allReports = [];
      
      for (final userDoc in userSnapshots.docs) {
        final reportsSnapshot = await userDoc.reference
            .collection('Reports')
            .orderBy('submittedAt', descending: true)
            .get();
        
        final userReports = reportsSnapshot.docs
            .map((doc) => Report.fromJson(doc.data()))
            .toList();
        
        allReports.addAll(userReports);
      }
      
      // Sort all reports by submission date
      allReports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      
      return allReports;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching all reports: $e');
    }
  }

  /// Get reports statistics across all users (for admin dashboard)
  Future<Map<String, int>> fetchGlobalReportsStatistics() async {
    try {
      final allReports = await fetchAllReports();
      
      return {
        'total': allReports.length,
        'pending': allReports.where((r) => r.status == ReportStatus.pending).length,
        'inProgress': allReports.where((r) => r.status == ReportStatus.inProgress).length,
        'resolved': allReports.where((r) => r.status == ReportStatus.resolved).length,
        'closed': allReports.where((r) => r.status == ReportStatus.closed).length,
      };
    } catch (e) {
      throw Exception('Error fetching global statistics: $e');
    }
  }

  /// Stream all reports across all users (for admin real-time monitoring)
  Stream<List<Report>> streamAllReports() {
    try {
      return _db.collectionGroup('Reports')
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Report.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw Exception('Error streaming all reports: $e');
    }
  }

  /// Update any report by admin (cross-user access)
  Future<void> adminUpdateReport(String userId, Report report) async {
    try {
      await _db
          .collection('Users')
          .doc(userId)
          .collection('Reports')
          .doc(report.id)
          .update(report.toJson());
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } catch (e) {
      throw Exception('Error updating report as admin: $e');
    }
  }

  /// Add sample data for testing
  Future<void> createSampleReports() async {
    try {
      final sampleReports = _getSampleReports();
      
      for (final report in sampleReports) {
        await _reportsCollection.doc(report.id).set(report.toJson());
      }
    } catch (e) {
      throw Exception('Error creating sample reports: $e');
    }
  }

  /// Delete all reports (for testing)
  Future<void> clearAllReports() async {
    try {
      final querySnapshot = await _reportsCollection.get();
      final batch = _db.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Error clearing reports: $e');
    }
  }

  /// Get sample reports data
  List<Report> _getSampleReports() {
    return [
      Report(
        id: 'R001',
        unitNumber: '204-B',
        category: 'Maintenance / Repairs',
        subCategory: 'Plumbing (leaks, clogs, water issues)',
        description: 'Kitchen sink is clogged and water is backing up',
        status: ReportStatus.inProgress,
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
        tenantName: 'Caleb Anderson',
        attachments: [],
        updates: [
          ReportUpdate(
            message: 'Report received. Maintenance team has been notified.',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            isAdmin: true,
          ),
          ReportUpdate(
            message: 'Plumber scheduled for tomorrow morning.',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            isAdmin: true,
          ),
        ],
      ),
      Report(
        id: 'R002',
        unitNumber: '204-B',
        category: 'Billing & Payment',
        subCategory: 'Incorrect billing amount',
        description: 'Monthly rent charged includes utilities but I handle my own utilities',
        status: ReportStatus.resolved,
        submittedAt: DateTime.now().subtract(const Duration(days: 7)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 3)),
        tenantName: 'Caleb Anderson',
        attachments: [],
        updates: [
          ReportUpdate(
            message: 'Report received. Checking billing records.',
            timestamp: DateTime.now().subtract(const Duration(days: 7)),
            isAdmin: true,
          ),
          ReportUpdate(
            message: 'Billing error confirmed. Adjustment will appear on next statement.',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            isAdmin: true,
          ),
        ],
      ),
      Report(
        id: 'R003',
        unitNumber: '204-B',
        category: 'Complaints / Concerns',
        subCategory: 'Noise disturbance',
        description: 'Upstairs neighbor is consistently loud during late night hours',
        status: ReportStatus.pending,
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
        tenantName: 'Caleb Anderson',
        attachments: [],
        updates: [],
      ),
    ];
  }
}