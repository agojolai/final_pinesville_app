# Firebase Cloud Messaging (FCM) Implementation

## Overview
The Pinesville app uses Firebase Cloud Messaging to send push notifications to users and admins for real-time updates on critical events like bill payments, ticket replies, and system alerts.

## Architecture

### Components
1. **FCMService** (`lib/src/core/services/fcm_service.dart`)
   - Handles FCM initialization and token management
   - Manages notification permissions
   - Processes foreground, background, and terminated state messages
   - Displays local notifications when app is in foreground

2. **NotificationService** (`lib/src/core/services/notification_service.dart`)
   - Helper methods for all 11 notification use cases
   - Creates notification documents in Firestore
   - Queues topic-based notifications for Cloud Functions

3. **FCM Token Storage**
   - Stored in `Users/{userId}/account/fcmToken` field
   - Automatically saved on login and registration
   - Updated on token refresh

## Notification Use Cases

### Tenant Notifications
1. **Application Status** - Approval/rejection of rental application
2. **Payment Status** - Payment proof verification results
3. **New Bills** - New bill generation alerts
4. **Payment Reminders** - 3-day reminder before due date
5. **Late Fees** - Late fee application alerts
6. **Ticket Updates** - Support ticket replies
7. **Announcements** - Property-wide or app-wide announcements

### Admin Notifications
8. **New Applications** - New tenant registration requests
9. **Payment Submissions** - Payment proof uploads
10. **New Tickets** - Support ticket creation
11. **System Alerts** - Urgent events (evictions, security, etc.)

## Setup Instructions

### 1. Firebase Console Configuration
1. Go to Firebase Console  Project Settings
2. Navigate to Cloud Messaging tab
3. Download `google-services.json` and place in `android/app/`
4. Enable Firebase Cloud Messaging API in Google Cloud Console

### 2. Android Configuration (Already Done )
- `android/app/src/main/AndroidManifest.xml`:
  - POST_NOTIFICATIONS permission added
  - FCM service declaration
  - Notification click intent filter
  - Default channel metadata

### 3. iOS Configuration (Future)
- Add APNs certificate to Firebase Console
- Configure capabilities in Xcode
- Request notification permissions

## How to Send Notifications

### Option 1: Firebase Console (Manual Testing)
1. Go to Firebase Console  Cloud Messaging
2. Click "Send your first message"
3. **Notification:**
   - Title: "Payment Verified "
   - Text: "Your payment has been applied to your bill"
4. **Target:**
   - Select "Single device"
   - Paste FCM token from Firestore Users collection
5. **Additional Options:**
   - Custom data: `{"screen": "/billing/BILL_ID"}`
6. Click "Send"

### Option 2: Programmatic (In-App)
```dart
// Example: Notify tenant about bill
await NotificationService.notifyNewBill(
  userId: 'USER_ID',
  billId: 'BILL_ID',
  totalAmount: 5000.0,
  dueDate: DateTime.now().add(Duration(days: 7)),
);
```

### Option 3: Cloud Functions (Production - Not Yet Implemented)
```javascript
// Firebase Cloud Function to send FCM
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendNotificationOnNewBill = functions.firestore
  .document('Notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('Users')
      .doc(notification.userId)
      .get();
    
    const fcmToken = userDoc.data().account.fcmToken;
    
    // Send notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        screen: notification.screen,
        type: notification.type,
      },
    });
  });
```

## Testing FCM Implementation

### 1. Check FCM Initialization
Run the app and check logs:
```
[INFO] Initializing FCM Service...
[INFO] Notification permission: AuthorizationStatus.authorized
[INFO] FCM Token: [TOKEN_HERE]
[INFO] FCM Service initialized successfully
```

### 2. Verify Token Storage
After login/registration, check Firestore:
```
Users/[USER_ID]/
   account/
       fcmToken: "eXaMpLe_ToKeN_123"
```

### 3. Test Foreground Notifications
1. Send test message from Firebase Console
2. App should display local notification while in foreground
3. Check logs:
```
[INFO] Foreground message received: [MESSAGE_ID]
```

### 4. Test Background Notifications
1. Put app in background (press home button)
2. Send test message from Firebase Console
3. Notification should appear in system tray
4. Tap notification  app opens and navigates to specified screen

### 5. Test Terminated State
1. Force close the app (swipe away from recent apps)
2. Send test message from Firebase Console
3. Notification appears in system tray
4. Tap notification  app opens and navigates to screen

## Firestore Structure

### Notifications Collection (For User-Specific)
```
Notifications/{notificationId}/
 userId: string
 title: string
 body: string
 screen: string (e.g., "/billing/BILL_ID")
 type: string (e.g., "new_bill", "payment_status")
 read: boolean
 createdAt: timestamp
```

### NotificationQueue Collection (For Topics/Broadcasts)
```
NotificationQueue/{queueId}/
 type: string
 topic: string (e.g., "admins", "all_tenants", "property_X")
 title: string
 body: string
 screen: string
 priority: string (optional, "high" for urgent)
 createdAt: timestamp
```

## Topics

### Available Topics
- `all_users` - All app users (tenants + admins)
- `tenants` - All tenants
- `admins` - All administrators
- `property_{propertyId}` - Property-specific (e.g., "property_PROP123")

### Subscribe to Topics
```dart
// Subscribe admin to admin topic on login
await FCMService.subscribeToTopic('admins');

// Subscribe tenant to property topic
await FCMService.subscribeToTopic('property_${user.propertyId}');
```

### Unsubscribe from Topics
```dart
// Unsubscribe on logout or role change
await FCMService.unsubscribeFromTopic('admins');
```

## Integration with Existing Features

### Billing System
```dart
// In BillingRepository.createBill()
final bill = await createBill(...);

// Send notification
await NotificationService.notifyNewBill(
  userId: userId,
  billId: bill.id!,
  totalAmount: bill.totalAmount,
  dueDate: bill.dueDate,
);
```

### Payment Verification
```dart
// In AdminPaymentController.verifyPayment()
await repository.verifyPayment(paymentId);

// Notify tenant
await NotificationService.notifyPaymentStatus(
  userId: payment.userId,
  billId: payment.billId,
  isVerified: true,
);
```

### Support Tickets
```dart
// In TicketRepository.replyToTicket()
await addReply(ticketId, replyText);

// Notify tenant
await NotificationService.notifyTicketUpdate(
  userId: ticket.userId,
  ticketId: ticketId,
  updateMessage: 'Admin replied to your ticket',
);
```

## Troubleshooting

### Token is null
- Check if notification permissions are granted
- Verify FCM initialization runs before login
- Check `main.dart` - `FCMService.initialize()` should be called

### Notifications not appearing
- **Foreground**: Check `_handleForegroundMessage()` logs
- **Background**: Verify `_firebaseMessagingBackgroundHandler` is top-level
- **Terminated**: Check if app has notification permissions

### Token not saving to Firestore
- Check if user is logged in when token is generated
- Verify `saveTokenToFirestore()` is called in login/registration
- Check Firestore security rules allow token updates

### Navigation not working on tap
- Implement global navigator key
- Add navigation logic in `_handleNotificationTap()`
- Use named routes or route builders

## Security Considerations

### Firestore Security Rules
```javascript
// Allow users to update their own FCM token
match /Users/{userId} {
  allow update: if request.auth.uid == userId &&
                request.resource.data.diff(resource.data).affectedKeys()
                .hasOnly(['account.fcmToken']);
}

// Allow creating notifications (from authenticated users/admins)
match /Notifications/{notificationId} {
  allow create: if request.auth != null;
  allow read: if request.auth.uid == resource.data.userId;
  allow update: if request.auth.uid == resource.data.userId &&
                request.resource.data.diff(resource.data).affectedKeys()
                .hasOnly(['read']);
}
```

## Performance Considerations

1. **Token Refresh**: Tokens can change on app reinstall or device reset
2. **Batch Updates**: Group notifications where possible
3. **Rate Limiting**: Avoid sending too many notifications rapidly
4. **Topic Scaling**: Topics can handle millions of subscribers

## Future Enhancements

1. **In-App Notification Center**
   - Display notification history
   - Mark as read functionality
   - Clear all notifications

2. **Notification Preferences**
   - Allow users to customize notification types
   - Quiet hours settings
   - Email fallback for critical alerts

3. **Rich Notifications**
   - Images (payment proof thumbnails)
   - Action buttons (Pay Now, View Bill)
   - Progress bars (payment status)

4. **Analytics**
   - Track notification open rates
   - Delivery success metrics
   - User engagement data

## References

- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [flutter_local_notifications Package](https://pub.dev/packages/flutter_local_notifications)
- [firebase_messaging Package](https://pub.dev/packages/firebase_messaging)

---

**Implementation Status**:  Complete (Phase 1 - Basic FCM)
**Last Updated**: November 2025
**Next Phase**: Cloud Functions for automated notification sending
