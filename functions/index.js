const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

admin.initializeApp();

// Firestore trigger: Send notification to specific user
exports.send_notification_to_user = onDocumentCreated('Notifications/{notificationId}', async (event) => {
  try {
    const notification = event.data.data();
    const userId = notification.userId;
    const title = notification.title;
    const body = notification.body;
    const screen = notification.screen || '/home';
    const type = notification.type || 'general';

    console.log('Processing notification for user: ' + userId);

    // Get user''s FCM token
    const userDoc = await admin.firestore().collection('Users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.warn('User document not found: ' + userId);
      return null;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.account?.fcmToken;

    if (!fcmToken) {
      console.warn('No FCM token found for user: ' + userId);
      return null;
    }

    // Create FCM message
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        screen: screen,
        type: type,
        userId: userId,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'pinesville_default_channel',
          icon: '@mipmap/ic_launcher',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Send notification
    const response = await admin.messaging().send(message);
    console.log('Notification sent successfully: ' + response);
    
    return null;
  } catch (error) {
    console.error('Error sending notification: ' + error);
    return null;
  }
});

// Firestore trigger: Send notification to topic
exports.send_notification_to_topic = onDocumentCreated('NotificationQueue/{queueId}', async (event) => {
  try {
    const notification = event.data.data();
    const topic = notification.topic;
    const title = notification.title;
    const body = notification.body;
    const screen = notification.screen || '/home';
    const type = notification.type || 'general';
    const priority = notification.priority || 'normal';

    console.log('Processing topic notification for: ' + topic);

    // Create FCM message
    const message = {
      topic: topic,
      notification: {
        title: title,
        body: body,
      },
      data: {
        screen: screen,
        type: type,
      },
      android: {
        priority: priority === 'high' ? 'high' : 'normal',
        notification: {
          channelId: 'pinesville_default_channel',
          icon: '@mipmap/ic_launcher',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Send notification
    const response = await admin.messaging().send(message);
    console.log('Topic notification sent successfully: ' + response);

    // Delete from queue after successful send
    await event.data.ref.delete();
    console.log('Deleted notification from queue: ' + event.params.queueId);
    
    return null;
  } catch (error) {
    console.error('Error sending topic notification: ' + error);
    return null;
  }
});

// Scheduled function: Daily payment reminders (9:00 AM Manila time)
exports.send_daily_payment_reminders = onSchedule({
  schedule: '0 9 * * *',
  timeZone: 'Asia/Manila',
}, async (event) => {
  try {
    console.log('Starting daily payment reminder check...');
    
    // Calculate date range for bills due in 3 days
    const threeDaysFromNow = new Date();
    threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);
    threeDaysFromNow.setHours(0, 0, 0, 0);
    
    const endOfDay = new Date(threeDaysFromNow);
    endOfDay.setDate(endOfDay.getDate() + 1);

    // Query unpaid bills due in 3 days
    const billsSnapshot = await admin.firestore()
      .collection('Bills')
      .where('isPaid', '==', false)
      .where('billingPeriod.dueDate', '>=', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
      .where('billingPeriod.dueDate', '<', admin.firestore.Timestamp.fromDate(endOfDay))
      .get();

    let count = 0;
    for (const billDoc of billsSnapshot.docs) {
      try {
        const bill = billDoc.data();
        const userId = bill.userId;
        const balance = bill.summary?.balance || 0;
        const dueDate = bill.billingPeriod?.dueDate?.toDate();

        if (!dueDate) continue;

        const month = String(dueDate.getMonth() + 1).padStart(2, '0');
        const day = String(dueDate.getDate()).padStart(2, '0');
        const year = dueDate.getFullYear();
        const formattedDate = month + '/' + day + '/' + year;

        // Create notification document
        await admin.firestore().collection('Notifications').add({
          userId: userId,
          title: 'Payment Reminder ',
          body: 'Your bill of ' + balance.toFixed(2) + ' is due on ' + formattedDate + '. Pay soon to avoid late fees.',
          screen: '/billing/' + billDoc.id,
          type: 'payment_reminder',
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        count++;
        console.log('Queued reminder for bill ' + billDoc.id + ' to user ' + userId);
      } catch (error) {
        console.error('Error processing bill ' + billDoc.id + ': ' + error);
      }
    }

    console.log('Payment reminder check complete. Sent ' + count + ' reminders.');
    return null;
  } catch (error) {
    console.error('Error in scheduled payment reminders: ' + error);
    return null;
  }
});

// Scheduled function: Daily late fee updates (12:00 AM Manila time)
exports.update_late_fees_daily = onSchedule({
  schedule: '0 0 * * *',
  timeZone: 'Asia/Manila',
}, async (event) => {
  try {
    console.log('Starting daily late fee update...');

    // Get all overdue unpaid bills
    const billsSnapshot = await admin.firestore()
      .collection('Bills')
      .where('isPaid', '==', false)
      .where('isOverdue', '==', true)
      .get();

    let count = 0;
    for (const billDoc of billsSnapshot.docs) {
      try {
        const bill = billDoc.data();
        const userId = bill.userId;
        const propertyId = bill.propertyId;
        const unitId = bill.unitId;
        const billingPeriod = bill.billingPeriod || {};
        
        const dueDateTimestamp = billingPeriod.dueDate;
        if (!dueDateTimestamp) continue;

        const dueDate = dueDateTimestamp.toDate();
        
        // Check for next bill (to freeze late fees)
        let nextBillCreatedAt = null;
        const nextMonth = (billingPeriod.month % 12) + 1;
        const nextYear = billingPeriod.month === 12 ? billingPeriod.year + 1 : billingPeriod.year;

        const nextBillSnapshot = await admin.firestore()
          .collection('Bills')
          .where('userId', '==', userId)
          .where('propertyId', '==', propertyId)
          .where('unitId', '==', unitId)
          .where('billingPeriod.month', '==', nextMonth)
          .where('billingPeriod.year', '==', nextYear)
          .limit(1)
          .get();

        if (!nextBillSnapshot.empty) {
          const nextBill = nextBillSnapshot.docs[0].data();
          nextBillCreatedAt = nextBill.createdAt ? new Date(nextBill.createdAt) : null;
        }

        // Calculate late fee
        const now = new Date();
        const calculationEnd = nextBillCreatedAt || now;

        if (calculationEnd > dueDate) {
          const daysOverdue = Math.floor((calculationEnd - dueDate) / (1000 * 60 * 60 * 24));
          const weeksOverdue = Math.ceil(daysOverdue / 7);
          const totalLateFee = weeksOverdue * 150.0;

          // Get current late fee
          const currentLateFee = bill.lateFeeDetails?.totalLateFee || 0;

          // Only update if late fee changed
          if (totalLateFee !== currentLateFee) {
            const subtotal = bill.summary?.subtotal || 0;
            const amountPaid = bill.summary?.amountPaid || 0;
            const newTotal = subtotal + totalLateFee;
            const newBalance = newTotal - amountPaid;

            // Update bill
            await billDoc.ref.update({
              lateFeeDetails: {
                isLate: true,
                weeksOverdue: weeksOverdue,
                lateFeePerWeek: 150.0,
                totalLateFee: totalLateFee,
                lateFeeAppliedAt: calculationEnd.toISOString(),
                gracePeriodEnd: dueDate.toISOString(),
                lastCalculated: now.toISOString(),
              },
              'summary.lateFee': totalLateFee,
              'summary.total': newTotal,
              'summary.balance': newBalance,
              updatedAt: now.toISOString(),
            });

            count++;
            console.log('Updated late fee for bill ' + billDoc.id + ': ' + currentLateFee.toFixed(2) + '  ' + totalLateFee.toFixed(2));
          }
        }
      } catch (error) {
        console.error('Error updating bill ' + billDoc.id + ': ' + error);
      }
    }

    console.log('Late fee update complete. Updated ' + count + ' bills.');
    return null;
  } catch (error) {
    console.error('Error in scheduled late fee update: ' + error);
    return null;
  }
});

// Scheduled function: Daily late fee notifications (10:00 AM Manila time)
exports.send_daily_late_fee_notifications = onSchedule({
  schedule: '0 10 * * *',
  timeZone: 'Asia/Manila',
}, async (event) => {
  try {
    console.log('Starting daily late fee notification check...');

    // Query overdue bills
    const billsSnapshot = await admin.firestore()
      .collection('Bills')
      .where('isOverdue', '==', true)
      .where('isPaid', '==', false)
      .get();

    let count = 0;
    for (const billDoc of billsSnapshot.docs) {
      try {
        const bill = billDoc.data();
        const userId = bill.userId;
        const lateFeeDetails = bill.lateFeeDetails || {};

        if (!lateFeeDetails || !lateFeeDetails.lastCalculated) continue;

        const lastCalculated = new Date(lateFeeDetails.lastCalculated);
        const hoursSince = (new Date() - lastCalculated) / (1000 * 60 * 60);

        // Only notify if late fee was calculated in the last 24 hours
        if (hoursSince <= 24) {
          const lateFeeAmount = lateFeeDetails.totalLateFee || 0;
          const totalBalance = bill.summary?.balance || 0;

          // Create notification document
          await admin.firestore().collection('Notifications').add({
            userId: userId,
            title: 'Late Fee Applied ',
            body: 'A late fee of ' + lateFeeAmount.toFixed(2) + ' has been added. Total balance now ' + totalBalance.toFixed(2),
            screen: '/billing/' + billDoc.id,
            type: 'late_fee',
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          count++;
          console.log('Queued late fee notification for bill ' + billDoc.id);
        }
      } catch (error) {
        console.error('Error processing bill ' + billDoc.id + ': ' + error);
      }
    }

    console.log('Late fee notification check complete. Sent ' + count + ' notifications.');
    return null;
  } catch (error) {
    console.error('Error in scheduled late fee notifications: ' + error);
    return null;
  }
});
