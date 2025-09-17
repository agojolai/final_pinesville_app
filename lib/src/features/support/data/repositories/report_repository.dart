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

class ReportRepository {
  static ReportRepository? _instance;
  static ReportRepository get instance => _instance ??= ReportRepository._();
  
  ReportRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  // Collection reference
  CollectionReference get _reportsCollection => _db.collection('reports');

  // Function to save report to firestore
  Future<String> saveReport(ReportModel report) async {
    try {
      final docRef = await _reportsCollection.add(report.toJson());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error saving report: $e');
    }
  }

  // Function to fetch a specific report by ID
  Future<ReportModel> fetchReport(String reportId) async {
    try {
      final documentSnapshot = await _reportsCollection.doc(reportId).get();
      if (documentSnapshot.exists) {
        return ReportModel.fromSnapshot(
          documentSnapshot as DocumentSnapshot<Map<String, dynamic>>
        );
      } else {
        return ReportModel.empty();
      }
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

  // Function to fetch all reports for a specific user
  Future<List<ReportModel>> fetchUserReports(String userId) async {
    try {
      final querySnapshot = await _reportsCollection
          .where('tenant.userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ReportModel.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching user reports: $e');
    }
  }

  // Function to fetch reports for a specific unit
  Future<List<ReportModel>> fetchUnitReports(String unitNumber) async {
    try {
      final querySnapshot = await _reportsCollection
          .where('unitNumber', isEqualTo: unitNumber)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ReportModel.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error fetching unit reports: $e');
    }
  }

  // Function to update report status
  Future<void> updateReportStatus(String reportId, ReportStatus status, {DateTime? resolvedAt}) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
      };
      
      if (status == ReportStatus.resolved || status == ReportStatus.closed) {
        updateData['resolvedAt'] = (resolvedAt ?? DateTime.now()).toIso8601String();
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

  // Function to add update to a report
  Future<void> addReportUpdate(String reportId, ReportUpdate update) async {
    try {
      await _reportsCollection.doc(reportId).update({
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

  // Function to add feedback to a resolved report
  Future<void> addReportFeedback(String reportId, ReportFeedback feedback) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'feedback': feedback.toJson(),
      });
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error adding report feedback: $e');
    }
  }

  // Function to upload attachment to Firebase Storage
  Future<String> uploadAttachment(String reportId, XFile file) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final String path = 'reports/$reportId/attachments/$fileName';
      
      final ref = _storage.ref().child(path);
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error uploading attachment: $e');
    }
  }

  // Function to upload multiple attachments
  Future<List<String>> uploadAttachments(String reportId, List<XFile> files) async {
    try {
      final List<String> urls = [];
      
      for (final file in files) {
        final url = await uploadAttachment(reportId, file);
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Error uploading attachments: $e');
    }
  }

  // Function to delete a report (admin only)
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

  // Function to get reports stream for real-time updates
  Stream<List<ReportModel>> getUserReportsStream(String userId) {
    try {
      return _reportsCollection
          .where('tenant.userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ReportModel.fromSnapshot(
                  doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList());
    } catch (e) {
      throw Exception('Error getting user reports stream: $e');
    }
  }

  // Function to get a specific report stream for real-time updates
  Stream<ReportModel> getReportStream(String reportId) {
    try {
      return _reportsCollection
          .doc(reportId)
          .snapshots()
          .map((snapshot) => ReportModel.fromSnapshot(
              snapshot as DocumentSnapshot<Map<String, dynamic>>));
    } catch (e) {
      throw Exception('Error getting report stream: $e');
    }
  }

  // Admin function to fetch all reports (for admin dashboard)
  Future<List<ReportModel>> fetchAllReports({ReportStatus? status, int? limit}) async {
    try {
      Query query = _reportsCollection.orderBy('submittedAt', descending: true);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => ReportModel.fromSnapshot(
              doc as DocumentSnapshot<Map<String, dynamic>>))
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

  // Helper method to update specific fields in a report
  Future<void> updateReportField(String reportId, Map<String, dynamic> fields) async {
    try {
      await _reportsCollection.doc(reportId).update(fields);
    } on FirebaseException catch (e) {
      throw custom_firebase.FirebaseException(e.code).message;
    } on custom_format.FormatException catch (_) {
      throw const custom_format.FormatException();
    } on PlatformException catch (e) {
      throw custom_platform.PlatformException(e.code).message;
    } catch (e) {
      throw Exception('Error updating report field: $e');
    }
  }
}