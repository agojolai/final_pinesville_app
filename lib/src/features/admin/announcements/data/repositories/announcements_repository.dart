import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/template_model.dart';
import '../models/property_model.dart';
import '../../../../../core/services/notification_service.dart';
import '../../../../../core/utils/app_logger.dart';

class AnnouncementsRepository {
  final FirebaseFirestore _firestore;

  AnnouncementsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== ANNOUNCEMENTS ====================

  /// Stream active announcements (TENANT USE - with 7-day filter for efficiency)
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

  /// Get paginated announcements (ADMIN USE - load 10 at a time for efficiency)
  /// 
  /// [archived] - Whether to fetch from archived or active collection
  /// [limit] - Number of announcements to fetch (default: 10)
  /// [startAfterDoc] - Document to start after for pagination (null for first page)
  Future<QuerySnapshot> getPaginatedAnnouncements({
    bool archived = false,
    int limit = 10,
    DocumentSnapshot? startAfterDoc,
  }) async {
    final docPath = archived ? 'announcements_archived' : 'announcements_main';
    
    Query query = _firestore
        .collection('announcements')
        .doc(docPath)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);
    
    // Add pagination cursor if provided
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }
    
    return await query.get();
  }

  /// Create a new announcement
  Future<void> createAnnouncement({
    required String title,
    required String message,
    required List<String> recipients,
  }) async {
    try {
      // Create announcement document
      final announcementRef = await _firestore
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
      
      final announcementId = announcementRef.id;
      
      AppLogger.info('📢 Created announcement: $announcementId with recipients: $recipients');
      
      // Send push notifications to recipients
      if (recipients.contains('all')) {
        // Send to all tenants
        final usersSnapshot = await _firestore.collection('Users').get();
        
        AppLogger.info('📢 Sending to all users: ${usersSnapshot.docs.length} users found');
        
        int notificationsSent = 0;
        for (final userDoc in usersSnapshot.docs) {
          try {
            await NotificationService.notifyPropertyAnnouncement(
              userId: userDoc.id,
              announcementId: announcementId,
              title: title,
              message: message,
            );
            notificationsSent++;
          } catch (e) {
            AppLogger.error('📢 Failed to send notification to user ${userDoc.id}: $e');
          }
        }
        
        AppLogger.info('📢 Sent announcement notifications to all tenants ($notificationsSent users)');
      } else {
        // Send to specific property or individual users
        int notificationsSent = 0;
        
        for (final recipient in recipients) {
          if (recipient != 'all' && !recipient.contains('@')) {
            // Property-specific announcement - send to all tenants in that property
            final propertyName = recipient;
            
            AppLogger.info('📢 Querying users for property: $propertyName');
            
            // Get all users and filter by propertyName in nested structure
            final usersSnapshot = await _firestore.collection('Users').get();
            
            for (final userDoc in usersSnapshot.docs) {
              try {
                final userData = userDoc.data();
                
                // Check nested property.propertyName structure
                final userPropertyName = userData['property']?['propertyName'];
                
                AppLogger.info('📢 User ${userDoc.id} has propertyName: $userPropertyName');
                
                if (userPropertyName == propertyName) {
                  await NotificationService.notifyPropertyAnnouncement(
                    userId: userDoc.id,
                    announcementId: announcementId,
                    title: title,
                    message: message,
                  );
                  notificationsSent++;
                  AppLogger.info('📢 Sent notification to user ${userDoc.id} in property $propertyName');
                }
              } catch (e) {
                AppLogger.error('📢 Error processing user ${userDoc.id}: $e');
              }
            }
            
            AppLogger.info('📢 Sent announcement to property $propertyName ($notificationsSent users)');
          } else {
            // Individual user announcement
            try {
              await NotificationService.notifyPropertyAnnouncement(
                userId: recipient,
                announcementId: announcementId,
                title: title,
                message: message,
              );
              notificationsSent++;
              AppLogger.info('📢 Sent notification to individual user $recipient');
            } catch (e) {
              AppLogger.error('📢 Failed to send notification to user $recipient: $e');
            }
          }
        }
        
        AppLogger.info('📢 Total announcement notifications sent: $notificationsSent');
      }
    } catch (e) {
      AppLogger.error('📢 Failed to create announcement: $e');
      rethrow;
    }
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
