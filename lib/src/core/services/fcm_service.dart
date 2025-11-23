import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

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
  
  static String? _fcmToken;
  
  /// Get current FCM token
  static String? get fcmToken => _fcmToken;
  
  /// Initialize FCM and notification channels
  static Future<void> initialize() async {
    try {
      AppLogger.info('Initializing FCM Service...');
      
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
      AppLogger.error('Error initializing FCM: $e', stackTrace);
    }
  }
  
  /// Handle messages when app is in foreground
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('Foreground message received: ${message.messageId}');
    
    final notification = message.notification;
    if (notification != null) {
      AppLogger.info('Title: ${notification.title}');
      AppLogger.info('Body: ${notification.body}');
      // FCM will automatically display the notification on Android
      // iOS notification display is configured via setForegroundNotificationPresentationOptions
    }
  }
  
  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info('Notification tapped: ${message.messageId}');
    
    final screen = message.data['screen'];
    if (screen != null) {
      AppLogger.info('Navigate to: $screen');
      // TODO: Implement navigation logic based on screen parameter
      // Example: navigatorKey.currentState?.pushNamed(screen);
    }
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
      AppLogger.error('Error saving FCM token: $e', stackTrace);
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
