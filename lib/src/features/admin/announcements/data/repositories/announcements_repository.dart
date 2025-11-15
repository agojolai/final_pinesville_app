import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/template_model.dart';
import '../models/property_model.dart';

class AnnouncementsRepository {
  final FirebaseFirestore _firestore;

  AnnouncementsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== ANNOUNCEMENTS ====================

  /// Stream active announcements
  /// 
  /// [archived] - Whether to fetch from archived or active collection
  /// [lastNDays] - Optional filter to only fetch announcements from the last N days
  ///               Defaults to 7 days for active announcements (null for archived)
  ///               Set to null to fetch all announcements regardless of date
  Stream<QuerySnapshot> getAnnouncementsStream({
    bool archived = false,
    int? lastNDays,
  }) {
    final docPath = archived ? 'announcements_archived' : 'announcements_main';
    
    // Default to 7 days for active announcements only (reduce reads)
    final daysFilter = lastNDays ?? (archived ? null : 7);
    
    Query query = _firestore
        .collection('announcements')
        .doc(docPath)
        .collection('messages')
        .orderBy('timestamp', descending: true);
    
    // Add time filter if specified
    if (daysFilter != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysFilter));
      query = query.where(
        'timestamp',
        isGreaterThan: Timestamp.fromDate(cutoffDate),
      );
    }
    
    return query.snapshots();
  }

  /// Create a new announcement
  Future<void> createAnnouncement({
    required String title,
    required String message,
    required List<String> recipients,
  }) async {
    await _firestore
        .collection('announcements')
        .doc('announcements_main')
        .collection('messages')
        .add({
      'title': title,
      'message': message,
      'recipients': recipients,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
  }

  /// Update an existing announcement
  Future<void> updateAnnouncement({
    required String announcementId,
    required String title,
    required String message,
    required List<String> recipients,
  }) async {
    await _firestore
        .collection('announcements')
        .doc('announcements_main')
        .collection('messages')
        .doc(announcementId)
        .update({
      'title': title,
      'message': message,
      'recipients': recipients,
    });
  }

  /// Archive an announcement
  Future<void> archiveAnnouncement(String announcementId) async {
    final docRef = _firestore
        .collection('announcements')
        .doc('announcements_main')
        .collection('messages')
        .doc(announcementId);

    final doc = await docRef.get();

    if (doc.exists) {
      // Copy to archived collection
      await _firestore
          .collection('announcements')
          .doc('announcements_archived')
          .collection('messages')
          .doc(announcementId)
          .set(doc.data()!);

      // Remove from current collection
      await docRef.delete();
    }
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String announcementId,
      {bool archived = false}) async {
    final docPath = archived ? 'announcements_archived' : 'announcements_main';
    await _firestore
        .collection('announcements')
        .doc(docPath)
        .collection('messages')
        .doc(announcementId)
        .delete();
  }

  // ==================== TEMPLATES ====================

  /// Get all templates
  Future<List<TemplateModel>> getTemplates() async {
    final snapshot = await _firestore
        .collection('announcements')
        .doc('announcements_templates')
        .collection('templates')
        .get();

    return snapshot.docs
        .map((doc) => TemplateModel.fromFirestore(doc))
        .toList();
  }

  /// Stream templates
  Stream<QuerySnapshot> getTemplatesStream() {
    return _firestore
        .collection('announcements')
        .doc('announcements_templates')
        .collection('templates')
        .snapshots();
  }

  /// Create a new template
  Future<void> createTemplate({
    required String subject,
    required String message,
    required List<String> recipients,
  }) async {
    await _firestore
        .collection('announcements')
        .doc('announcements_templates')
        .collection('templates')
        .add({
      'subject': subject,
      'message': message,
      'recipients': recipients,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a template
  Future<void> deleteTemplate(String templateId) async {
    await _firestore
        .collection('announcements')
        .doc('announcements_templates')
        .collection('templates')
        .doc(templateId)
        .delete();
  }

  // ==================== PROPERTIES ====================

  /// Get all properties
  Future<List<PropertyModel>> getProperties() async {
    final snapshot = await _firestore.collection('Property').get();
    return snapshot.docs
        .map((doc) => PropertyModel.fromFirestore(doc))
        .toList();
  }

  /// Stream properties
  Stream<QuerySnapshot> getPropertiesStream() {
    return _firestore.collection('Property').snapshots();
  }
}
