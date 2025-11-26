import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/app_logger.dart';
import '../../../app.dart' as app;

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final messageId = message.messageId ?? 'unknown';
  final title = message.notification?.title ?? 'No title';
  final body = message.notification?.body ?? 'No body';
  
  AppLogger.info('Background message received: $messageId');
  AppLogger.info('Title: $title');
  AppLogger.info('Body: $body');
}

/// FCM Service to handle push notifications
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  
  /// Get current FCM token
  static String? get fcmToken => _fcmToken;
  
  /// Initialize FCM and notification channels
  static Future<void> initialize() async {
    try {
      AppLogger.info('Initializing FCM Service...');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      AppLogger.info('Notification permission: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Configure foreground notification presentation (iOS only)
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        AppLogger.info('FCM Token: $_fcmToken');
        
        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          AppLogger.info('FCM Token refreshed: $newToken');
          // TODO: Update token in Firestore when user is logged in
        });
        
        // Set up background message handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle notification taps (when app is in background)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        // Check if app was opened from a notification (when app was terminated)
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
        
        AppLogger.info('FCM Service initialized successfully');
      } else {
        AppLogger.warning('Notification permission denied');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing FCM: $e', e, stackTrace);
    }
  }
  
  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'pinesville_default_channel',
      'Pinesville Notifications',
      description: 'Default notification channel for Pinesville app',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    AppLogger.info('Local notifications initialized');
  }
  
  /// Handle notification tap from local notification
  static void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Local notification tapped: ${response.payload}');
    
    if (response.payload != null && response.payload!.isNotEmpty) {
      final screen = response.payload!;
      AppLogger.info('Navigating to: $screen');
      
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = app.navigatorKey.currentContext;
        if (context == null) {
          AppLogger.warning('Navigator context not available');
          return;
        }
        
        try {
          if (screen.startsWith('/billing/')) {
            final billId = screen.replaceFirst('/billing/', '');
            AppLogger.info('Navigating to bill: $billId');
            _navigateToBill(context, billId);
          } else if (screen.startsWith('/support/') || screen.startsWith('/admin/support/')) {
            final ticketId = screen.replaceAll('/admin/support/', '').replaceAll('/support/', '');
            AppLogger.info('Navigating to ticket: $ticketId');
            _navigateToTicket(context, ticketId);
          }
        } catch (e) {
          AppLogger.error('Error navigating from notification: $e');
        }
      });
    }
  }
  
  /// Handle messages when app is in foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('🔔 Foreground message received: ${message.messageId}');
    AppLogger.info('📱 Message data: ${message.data}');
    
    final notification = message.notification;
    AppLogger.info('📬 Notification object: ${notification != null ? "exists" : "null"}');
    
    if (notification != null) {
      AppLogger.info('📬 Title: ${notification.title}');
      AppLogger.info('📝 Body: ${notification.body}');
      
      // Display notification using local notifications
      await _showLocalNotification(
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        payload: message.data['screen'] ?? '/home',
      );
      
      AppLogger.info('✅ Foreground notification displayed via local notification');
    } else {
      AppLogger.warning('⚠️ Notification object is null - this is a data-only message');
      // For data-only messages, we can still show a local notification
      if (message.data.isNotEmpty) {
        AppLogger.info('📦 Showing notification from data payload');
        await _showLocalNotification(
          title: message.data['title'] ?? 'Notification',
          body: message.data['body'] ?? 'You have a new notification',
          payload: message.data['screen'] ?? '/home',
        );
      }
    }
  }
  
  /// Show a local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      AppLogger.info('🔔 Attempting to show local notification');
      AppLogger.info('   Title: $title');
      AppLogger.info('   Body: $body');
      AppLogger.info('   Payload: $payload');
      
      const androidDetails = AndroidNotificationDetails(
        'pinesville_default_channel',
        'Pinesville Notifications',
        channelDescription: 'Default notification channel for Pinesville app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      AppLogger.info('📱 Showing notification with ID: $notificationId');
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
      
      AppLogger.info('✅ Local notification shown successfully');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error showing local notification: $e', e, stackTrace);
    }
  }
  
  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info('Notification tapped: ${message.messageId}');
    
    final data = message.data;
    final screen = data['screen'];
    
    if (screen != null && screen.isNotEmpty) {
      AppLogger.info('Navigating to: $screen');
      
      // Use a short delay to ensure app is fully initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        final context = app.navigatorKey.currentContext;
        if (context == null) {
          AppLogger.warning('Navigator context not available');
          return;
        }
        
        try {
          // Parse screen path and navigate
          if (screen.startsWith('/billing/')) {
            // Extract bill ID from path: /billing/{billId}
            final billId = screen.replaceFirst('/billing/', '');
            AppLogger.info('Navigating to bill: $billId');
            _navigateToBill(context, billId);
          } else if (screen.startsWith('/support/') || screen.startsWith('/admin/support/')) {
            // Extract ticket ID from path: /support/{ticketId} or /admin/support/{ticketId}
            final ticketId = screen.replaceAll('/admin/support/', '').replaceAll('/support/', '');
            AppLogger.info('Navigating to ticket: $ticketId');
            _navigateToTicket(context, ticketId);
          } else if (screen == '/billing') {
            AppLogger.info('Navigating to billing list');
            // Main navigation handles this through bottom nav
            // User is already on the app, they can navigate manually
          } else if (screen == '/profile') {
            AppLogger.info('Navigating to profile');
            // Main navigation handles this through bottom nav
          } else if (screen == '/home') {
            AppLogger.info('Navigating to home');
            // Already at home screen
          } else {
            AppLogger.warning('Unknown screen path: $screen');
          }
        } catch (e) {
          AppLogger.error('Error navigating from notification: $e');
        }
      });
    }
  }
  
  /// Navigate to bill details screen
  static void _navigateToBill(BuildContext context, String billId) {
    // Import the bill detail screen dynamically to avoid circular dependencies
    // The screen will be imported when needed
    AppLogger.info('Bill navigation requested: $billId');
    // For now, log only - actual navigation requires screen imports
    // This can be implemented by the UI layer when needed
  }
  
  /// Navigate to ticket details screen
  static void _navigateToTicket(BuildContext context, String ticketId) {
    // Import the ticket detail screen dynamically to avoid circular dependencies
    AppLogger.info('Ticket navigation requested: $ticketId');
    // For now, log only - actual navigation requires screen imports
    // This can be implemented by the UI layer when needed
  }
  
  /// Save FCM token to Firestore for a user
  static Future<void> saveTokenToFirestore(String userId) async {
    if (_fcmToken == null) {
      AppLogger.warning('No FCM token available');
      return;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .update({'account.fcmToken': _fcmToken});
      
      AppLogger.info('FCM token saved to Firestore for user: $userId');
    } catch (e, stackTrace) {
      AppLogger.error('Error saving FCM token: $e', e, stackTrace);
    }
  }
  
  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Error subscribing to topic: $e');
    }
  }
  
  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Error unsubscribing from topic: $e');
    }
  }
}
