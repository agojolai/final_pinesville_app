import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

/// Notification Service to send targeted push notifications
/// via Firestore triggers (requires Cloud Functions backend)
class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ============ TENANT NOTIFICATIONS ============
  
  /// 1. Notify tenant about application status
  /// Use Cases: Application approved or rejected
  static Future<void> notifyApplicationStatus({
    required String userId,
    required bool isApproved,
    String? rejectionReason,
  }) async {
    try {
      await _createNotificationDocument(
        userId: userId,
        title: isApproved ? 'Application Approved! ' : 'Application Update',
        body: isApproved 
            ? 'Your tenant application has been approved. Welcome to Pinesville!'
            : 'Your application was not approved. ${rejectionReason ?? "Please contact admin for details."}',
        screen: '/profile',
        type: 'application_status',
      );
    } catch (e) {
      AppLogger.error('Error sending application status notification: $e');
    }
  }
  
  /// 2. Notify tenant about payment verification status
  /// Use Cases: Payment proof approved or rejected
  static Future<void> notifyPaymentStatus({
    required String userId,
    required String billId,
    required bool isVerified,
    String? rejectionReason,
  }) async {
    try {
      await _createNotificationDocument(
        userId: userId,
        title: isVerified ? 'Payment Verified ' : 'Payment Update',
        body: isVerified
            ? 'Your payment has been verified and applied to your bill.'
            : 'Payment verification failed. ${rejectionReason ?? "Please resubmit."}',
        screen: '/billing/$billId',
        type: 'payment_status',
      );
    } catch (e) {
      AppLogger.error('Error sending payment status notification: $e');
    }
  }
  
  /// 3. Notify tenant about new bill
  /// Use Case: Admin creates a new bill for tenant
  static Future<void> notifyNewBill({
    required String userId,
    required String billId,
    required double totalAmount,
    required DateTime dueDate,
  }) async {
    try {
      final formattedAmount = totalAmount.toStringAsFixed(2);
      final formattedDate = '${dueDate.month}/${dueDate.day}/${dueDate.year}';
      
      await _createNotificationDocument(
        userId: userId,
        title: 'New Bill Available ',
        body: 'Your new bill of $formattedAmount is ready. Due on $formattedDate',
        screen: '/billing/$billId',
        type: 'new_bill',
      );
    } catch (e) {
      AppLogger.error('Error sending new bill notification: $e');
    }
  }
  
  /// 4. Notify tenant about upcoming payment due date
  /// Use Case: 3 days before due date reminder
  static Future<void> notifyPaymentReminder({
    required String userId,
    required String billId,
    required double balanceDue,
    required DateTime dueDate,
  }) async {
    try {
      final formattedAmount = balanceDue.toStringAsFixed(2);
      final formattedDate = '${dueDate.month}/${dueDate.day}/${dueDate.year}';
      
      await _createNotificationDocument(
        userId: userId,
        title: 'Payment Reminder ',
        body: 'Your bill of $formattedAmount is due on $formattedDate. Pay soon to avoid late fees.',
        screen: '/billing/$billId',
        type: 'payment_reminder',
      );
    } catch (e) {
      AppLogger.error('Error sending payment reminder notification: $e');
    }
  }
  
  /// 5. Notify tenant about late fees
  /// Use Case: Late fees added to bill
  static Future<void> notifyLateFee({
    required String userId,
    required String billId,
    required double lateFeeAmount,
    required double totalBalance,
  }) async {
    try {
      final formattedFee = lateFeeAmount.toStringAsFixed(2);
      final formattedTotal = totalBalance.toStringAsFixed(2);
      
      await _createNotificationDocument(
        userId: userId,
        title: 'Late Fee Applied ',
        body: 'A late fee of $formattedFee has been added. Total balance now $formattedTotal',
        screen: '/billing/$billId',
        type: 'late_fee',
      );
    } catch (e) {
      AppLogger.error('Error sending late fee notification: $e');
    }
  }
  
  /// 6. Notify tenant about support ticket updates
  /// Use Cases: Admin replies to ticket, ticket status changes
  static Future<void> notifyTicketUpdate({
    required String userId,
    required String ticketId,
    required String updateMessage,
  }) async {
    try {
      await _createNotificationDocument(
        userId: userId,
        title: 'Support Ticket Update ',
        body: updateMessage,
        screen: '/support/$ticketId',
        type: 'ticket_update',
      );
    } catch (e) {
      AppLogger.error('Error sending ticket update notification: $e');
    }
  }
  
  /// 7. Send announcement to all tenants or specific property
  /// Use Case: Property-wide or building-wide announcements
  static Future<void> sendAnnouncement({
    String? userId,
    String? propertyId,
    required String title,
    required String message,
  }) async {
    try {
      if (userId != null) {
        await _createNotificationDocument(
          userId: userId,
          title: title,
          body: message,
          screen: '/home',
          type: 'announcement',
        );
      } else {
        await _firestore.collection('NotificationQueue').add({
          'type': 'announcement',
          'topic': propertyId != null ? 'property_$propertyId' : 'all_tenants',
          'title': title,
          'body': message,
          'screen': '/home',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        AppLogger.info('Announcement queued for topic');
      }
    } catch (e) {
      AppLogger.error('Error sending announcement: $e');
    }
  }
  
  // ============ ADMIN NOTIFICATIONS ============
  
  /// 8. Notify admins about new tenant application
  static Future<void> notifyNewApplication({
    required String applicantName,
    required String applicantEmail,
  }) async {
    try {
      await _firestore.collection('NotificationQueue').add({
        'type': 'new_application',
        'topic': 'admins',
        'title': 'New Tenant Application ',
        'body': '$applicantName ($applicantEmail) submitted a new application.',
        'screen': '/admin/applications',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('New application notification queued for admins');
    } catch (e) {
      AppLogger.error('Error notifying admins about new application: $e');
    }
  }
  
  /// 9. Notify admins about new payment submission
  static Future<void> notifyNewPayment({
    required String tenantName,
    required String billId,
    required double amount,
  }) async {
    try {
      final formattedAmount = amount.toStringAsFixed(2);
      
      await _firestore.collection('NotificationQueue').add({
        'type': 'new_payment',
        'topic': 'admins',
        'title': 'Payment Proof Submitted ',
        'body': '$tenantName submitted payment of $formattedAmount for verification.',
        'screen': '/admin/payments/$billId',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('New payment notification queued for admins');
    } catch (e) {
      AppLogger.error('Error notifying admins about new payment: $e');
    }
  }
  
  /// 10. Notify admins about new support ticket
  static Future<void> notifyNewTicket({
    required String tenantName,
    required String ticketId,
    required String subject,
  }) async {
    try {
      await _firestore.collection('NotificationQueue').add({
        'type': 'new_ticket',
        'topic': 'admins',
        'title': 'New Support Ticket ',
        'body': 'Ticket from $tenantName - $subject',
        'screen': '/admin/support/$ticketId',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      AppLogger.info('New ticket notification queued for admins');
    } catch (e) {
      AppLogger.error('Error notifying admins about new ticket: $e');
    }
  }
  
  /// 11. Send urgent system alert to admins
  static Future<void> sendAdminAlert({
    required String title,
    required String message,
    String? screen,
  }) async {
    try {
      await _firestore.collection('NotificationQueue').add({
        'type': 'admin_alert',
        'topic': 'admins',
        'title': ' $title',
        'body': message,
        'screen': screen ?? '/admin/dashboard',
        'createdAt': FieldValue.serverTimestamp(),
        'priority': 'high',
      });
      
      AppLogger.info('Admin alert notification queued');
    } catch (e) {
      AppLogger.error('Error sending admin alert: $e');
    }
  }
  
  // ============ HELPER METHODS ============
  
  static Future<void> _createNotificationDocument({
    required String userId,
    required String title,
    required String body,
    required String screen,
    required String type,
  }) async {
    await _firestore.collection('Notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'screen': screen,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    AppLogger.info('Notification created for user $userId');
  }
}
