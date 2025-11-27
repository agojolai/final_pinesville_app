import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import '../utils/app_logger.dart';

/// Service to send automated lease renewal reminders
/// This should be called by a scheduled Cloud Function or cron job
class LeaseReminderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send lease renewal reminders to tenants whose lease is ending in 2 months
  /// This method should be triggered daily by a Cloud Function
  static Future<void> sendTwoMonthReminders() async {
    try {
      AppLogger.info('Starting 2-month lease renewal reminder check...');
      
      // Calculate date range for leases ending in 2 months (59-61 days from now)
      final now = DateTime.now();
      final twoMonthsFromNow = DateTime(now.year, now.month + 2, now.day);
      final startDate = DateTime(twoMonthsFromNow.year, twoMonthsFromNow.month, twoMonthsFromNow.day);
      final endDate = startDate.add(Duration(days: 2)); // 2-day window for timing flexibility
      
      AppLogger.info('Checking leases ending between $startDate and $endDate');
      
      // Query all users to check their lease end dates
      final usersSnapshot = await _firestore
          .collection('Users')
          .get();
      
      int remindersSent = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          final userId = userDoc.id;
          
          // Get the latest lease from subcollection
          final leaseSnapshot = await _firestore
              .collection('Users')
              .doc(userId)
              .collection('leases')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          
          if (leaseSnapshot.docs.isEmpty) {
            continue;
          }
          
          final leaseData = leaseSnapshot.docs.first.data();
          final renewalOptions = leaseData['renewalOptions'];
          
          // Skip if tenant already submitted decision
          if (renewalOptions != null) {
            AppLogger.info('User $userId already submitted lease decision, skipping');
            continue;
          }
          
          // Parse lease end date (supports both String and Timestamp)
          DateTime? leaseEndDate;
          final endDate = leaseData['leaseEndDate'];
          
          if (endDate is String && endDate.isNotEmpty) {
            leaseEndDate = DateTime.tryParse(endDate);
          } else if (endDate is Timestamp) {
            leaseEndDate = endDate.toDate();
          }
          
          if (leaseEndDate == null) {
            AppLogger.warning('User $userId has no valid lease end date');
            continue;
          }
          
          // Check if lease ends in approximately 2 months
          final daysUntilExpiry = leaseEndDate.difference(now).inDays;
          
          if (daysUntilExpiry >= 59 && daysUntilExpiry <= 61) {
            await NotificationService.notifyLeaseRenewalTwoMonths(
              userId: userId,
              leaseEndDate: leaseEndDate,
            );
            
            remindersSent++;
            AppLogger.info('Sent 2-month reminder to user $userId (lease ends on $leaseEndDate)');
          }
        } catch (e) {
          AppLogger.error('Failed to process user ${userDoc.id}: $e');
        }
      }
      
      AppLogger.info('2-month lease renewal reminder check completed. Sent $remindersSent reminders');
    } catch (e) {
      AppLogger.error('Error in 2-month lease reminder service: $e');
      rethrow;
    }
  }

  /// Send lease renewal reminders to tenants whose lease is ending in 1 month
  /// This method should be triggered daily by a Cloud Function
  static Future<void> sendOneMonthReminders() async {
    try {
      AppLogger.info('Starting 1-month lease renewal reminder check...');
      
      // Calculate date range for leases ending in 1 month (29-31 days from now)
      final now = DateTime.now();
      final oneMonthFromNow = DateTime(now.year, now.month + 1, now.day);
      final startDate = DateTime(oneMonthFromNow.year, oneMonthFromNow.month, oneMonthFromNow.day);
      final endDate = startDate.add(Duration(days: 2)); // 2-day window for timing flexibility
      
      AppLogger.info('Checking leases ending between $startDate and $endDate');
      
      // Query all users to check their lease end dates
      final usersSnapshot = await _firestore
          .collection('Users')
          .get();
      
      int remindersSent = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          final userId = userDoc.id;
          
          // Get the latest lease from subcollection
          final leaseSnapshot = await _firestore
              .collection('Users')
              .doc(userId)
              .collection('leases')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          
          if (leaseSnapshot.docs.isEmpty) {
            continue;
          }
          
          final leaseData = leaseSnapshot.docs.first.data();
          final renewalOptions = leaseData['renewalOptions'];
          
          // Skip if tenant already submitted decision
          if (renewalOptions != null) {
            AppLogger.info('User $userId already submitted lease decision, skipping');
            continue;
          }
          
          // Parse lease end date (supports both String and Timestamp)
          DateTime? leaseEndDate;
          final endDate = leaseData['leaseEndDate'];
          
          if (endDate is String && endDate.isNotEmpty) {
            leaseEndDate = DateTime.tryParse(endDate);
          } else if (endDate is Timestamp) {
            leaseEndDate = endDate.toDate();
          }
          
          if (leaseEndDate == null) {
            AppLogger.warning('User $userId has no valid lease end date');
            continue;
          }
          
          // Check if lease ends in approximately 1 month
          final daysUntilExpiry = leaseEndDate.difference(now).inDays;
          
          if (daysUntilExpiry >= 29 && daysUntilExpiry <= 31) {
            await NotificationService.notifyLeaseRenewalOneMonth(
              userId: userId,
              leaseEndDate: leaseEndDate,
            );
            
            remindersSent++;
            AppLogger.info('Sent 1-month reminder to user $userId (lease ends on $leaseEndDate)');
          }
        } catch (e) {
          AppLogger.error('Failed to process user ${userDoc.id}: $e');
        }
      }
      
      AppLogger.info('1-month lease renewal reminder check completed. Sent $remindersSent reminders');
    } catch (e) {
      AppLogger.error('Error in 1-month lease reminder service: $e');
      rethrow;
    }
  }

  /// Combined method to run both reminder checks
  /// Can be called from a single Cloud Function
  static Future<void> sendAllLeaseReminders() async {
    AppLogger.info('========================================');
    AppLogger.info('Starting lease renewal reminder service');
    AppLogger.info('========================================');
    
    await sendTwoMonthReminders();
    await sendOneMonthReminders();
    
    AppLogger.info('========================================');
    AppLogger.info('Lease renewal reminder service completed');
    AppLogger.info('========================================');
  }
}
