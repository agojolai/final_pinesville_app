import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';
import '../../../../core/exceptions/firebase_exceptions.dart' as custom_firebase;
import '../../../../core/exceptions/format_exceptions.dart' as custom_format;
import '../../../../core/exceptions/platform_exceptions.dart' as custom_platform;
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/notification_service.dart';

class ReportRepository {
  static ReportRepository? _instance;
  static ReportRepository get instance => _instance ??= ReportRepository._();
  
  ReportRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Collection name for reports
  static const String _collection = 'reports';

  /// Storage path for report attachments
  static const String _storagePath = 'reports';

  /// Submit a new report
  Future<ReportModel> submitReport({
    required String unitNumber,
    required String propertyName,
    required String category,
    required String subCategory,
    required String description,
    required String tenantUserId,
    required String tenantName,
    List<XFile>? attachmentFiles,
  }) async {
    try {
      // Generate report ID
      final reportId = 'R${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      // Upload attachments if any
      List<String> attachmentUrls = [];
      if (attachmentFiles != null && attachmentFiles.isNotEmpty) {
        attachmentUrls = await _uploadAttachments(reportId, attachmentFiles);
      }

      // Create initial report update
      final initialUpdate = ReportUpdate(
        message: 'Report received. Maintenance team has been notified.',
        timestamp: DateTime.now(),
        isAdmin: true,
      );

      // Create report model
      final report = ReportModel(
        id: reportId,
        unitNumber: unitNumber,
        propertyName: propertyName,
        category: category,
        subCategory: subCategory,
        description: description,
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenant: TenantInfo(
          userId: tenantUserId,
          name: tenantName,
        ),
        attachments: attachmentUrls,
        updates: [initialUpdate],
      );

      // Save to Firestore
      await _db.collection(_collection)
          .doc(reportId)
          .set(report.toJson());
      
      // Send notification to admins about new ticket
      try {
        await NotificationService.notifyNewTicket(
          tenantName: tenantName,
          ticketId: reportId,
          subject: '$category - $subCategory',
        );
      } catch (e) {
        AppLogger.error('Failed to send new ticket notification: $e');
      }

      return report;
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

  /// Get reports for a specific tenant (excludes closed reports for performance)
  Future<List<ReportModel>> getTenantReports(String tenantUserId) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('tenant.userId', isEqualTo: tenantUserId)
          .where('status', whereNotIn: [ReportStatus.closed.name])
          .get();

      final reports = querySnapshot.docs
          .map((doc) => ReportModel.fromSnapshot(doc))
          .toList();
      
      // Sort by submittedAt descending (newest first)
      reports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      
      return reports;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching tenant reports: $e');
    }
  }

  /// Get all reports (admin function)
  Future<List<ReportModel>> getAllReports() async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReportModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching all reports: $e');
    }
  }

  /// Stream tenant reports in real-time (excludes closed reports for performance)
  Stream<List<ReportModel>> streamTenantReports(String tenantUserId) {
    return _db
        .collection(_collection)
        .where('tenant.userId', isEqualTo: tenantUserId)
        .where('status', whereNotIn: [ReportStatus.closed.name])
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs
              .map((doc) => ReportModel.fromSnapshot(doc))
              .toList();
          
          // Sort by submittedAt descending (newest first)
          reports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          
          return reports;
        });
  }

  /// Stream all reports in real-time (admin function)
  Stream<List<ReportModel>> streamAllReports() {
    return _db
        .collection(_collection)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromSnapshot(doc))
            .toList());
  }

  /// Get a specific report by ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _db.collection(_collection).doc(reportId).get();
      
      if (doc.exists) {
        return ReportModel.fromSnapshot(doc);
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

  /// Update report status (admin function)
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? message,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };

      // Add resolved timestamp if status is resolved or closed
      if (status == ReportStatus.resolved || status == ReportStatus.closed) {
        updates['resolvedAt'] = DateTime.now().toIso8601String();
      }

      // Add update message if provided
      if (message != null && message.isNotEmpty) {
        final report = await getReportById(reportId);
        if (report != null) {
          final newUpdate = ReportUpdate(
            message: message,
            timestamp: DateTime.now(),
            isAdmin: true,
          );
          final updatedUpdates = [...report.updates, newUpdate];
          updates['updates'] = updatedUpdates.map((u) => u.toJson()).toList();
        }
      }

      await _db.collection(_collection).doc(reportId).update(updates);
      
      // Send notification to tenant about status change
      try {
        final report = await getReportById(reportId);
        if (report != null) {
          String updateMessage;
          switch (status) {
            case ReportStatus.inProgress:
              updateMessage = 'Your ticket is now being processed by our team.';
              break;
            case ReportStatus.resolved:
              updateMessage = 'Your ticket has been resolved. Please check the details.';
              break;
            case ReportStatus.closed:
              updateMessage = 'Your ticket has been closed.';
              break;
            default:
              updateMessage = message ?? 'Your ticket status has been updated.';
          }
          
          await NotificationService.notifyTicketUpdate(
            userId: report.tenant.userId,
            ticketId: reportId,
            updateMessage: updateMessage,
          );
        }
      } catch (e) {
        AppLogger.error('Failed to send ticket status notification: $e');
      }
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

  /// Add update/message to report (admin function)
  Future<void> addReportUpdate({
    required String reportId,
    required String message,
    bool isAdmin = true,
  }) async {
    try {
      final report = await getReportById(reportId);
      if (report == null) {
        throw 'Report not found';
      }

      final newUpdate = ReportUpdate(
        message: message,
        timestamp: DateTime.now(),
        isAdmin: isAdmin,
      );

      final updatedUpdates = [...report.updates, newUpdate];

      await _db.collection(_collection).doc(reportId).update({
        'updates': updatedUpdates.map((u) => u.toJson()).toList(),
      });
      
      // Send notification to tenant about new update (only if from admin)
      if (isAdmin) {
        try {
          await NotificationService.notifyTicketUpdate(
            userId: report.tenant.userId,
            ticketId: reportId,
            updateMessage: message,
          );
        } catch (e) {
          AppLogger.error('Failed to send ticket update notification: $e');
        }
      }
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

  /// Add feedback to resolved report (tenant function)
  Future<void> addReportFeedback({
    required String reportId,
    required int rating,
    required String comment,
  }) async {
    try {
      final feedback = ReportFeedback(
        rating: rating,
        comment: comment,
      );

      await _db.collection(_collection).doc(reportId).update({
        'feedback': feedback.toJson(),
      });
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error adding feedback: $e');
    }
  }

  /// Upload multiple attachments to Firebase Storage
  Future<List<String>> _uploadAttachments(String reportId, List<XFile> files) async {
    try {
      final List<String> urls = [];
      
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = '${reportId}_attachment_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.${file.name.split('.').last}';
        final ref = _storage.ref().child(_storagePath).child(reportId).child(fileName);
        
        await ref.putFile(File(file.path));
        final url = await ref.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Error uploading attachments: $e');
    }
  }

  /// Delete attachment from Storage (admin function)
  Future<void> deleteAttachment(String attachmentUrl) async {
    try {
      final ref = _storage.refFromURL(attachmentUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Error deleting attachment: $e');
    }
  }

  /// Admin utility: Delete all reports (for testing)
  Future<void> deleteAllReports() async {
    try {
      final snapshot = await _db.collection(_collection).get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      AppLogger.info('All reports deleted successfully');
    } catch (e) {
      throw Exception('Error deleting all reports: $e');
    }
  }
}