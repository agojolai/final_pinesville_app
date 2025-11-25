"""
Cloud Functions for Pinesville App - Push Notification Triggers
Automatically sends FCM notifications when Firestore documents are created
Also includes scheduled functions for payment reminders
"""

from firebase_functions import firestore_fn, logger, scheduler_fn
from firebase_admin import initialize_app, messaging, firestore
from datetime import datetime, timedelta

# Initialize Firebase Admin SDK
initialize_app()

@firestore_fn.on_document_created(document="Notifications/{notificationId}")
def send_notification_to_user(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """
    Triggers when a new document is created in the Notifications collection.
    Sends FCM push notification to specific user.
    """
    try:
        # Get notification data
        notification_data = event.data.to_dict()
        user_id = notification_data.get("userId")
        title = notification_data.get("title")
        body = notification_data.get("body")
        screen = notification_data.get("screen", "/home")
        notification_type = notification_data.get("type", "general")
        
        logger.info(f"Processing notification for user: {user_id}")
        
        # Get user's FCM token from Firestore
        db = firestore.client()
        user_ref = db.collection("Users").document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            logger.warning(f"User document not found: {user_id}")
            return
        
        user_data = user_doc.to_dict()
        account = user_data.get("account", {})
        fcm_token = account.get("fcmToken")
        
        if not fcm_token:
            logger.warning(f"No FCM token found for user: {user_id}")
            return
        
        # Create FCM message
        message = messaging.Message(
            token=fcm_token,
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={
                "screen": screen,
                "type": notification_type,
                "userId": user_id,
            },
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="pinesville_default_channel",
                    icon="@mipmap/ic_launcher",
                    sound="default",
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound="default",
                        badge=1,
                    ),
                ),
            ),
        )
        
        # Send notification
        response = messaging.send(message)
        logger.info(f"Notification sent successfully: {response}")
        
    except Exception as e:
        logger.error(f"Error sending notification: {str(e)}")


@firestore_fn.on_document_created(document="NotificationQueue/{queueId}")
def send_notification_to_topic(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """
    Triggers when a new document is created in the NotificationQueue collection.
    Sends FCM push notification to a topic (group of users).
    Topics: admins, all_tenants, property_{propertyId}
    """
    try:
        # Get notification data
        notification_data = event.data.to_dict()
        topic = notification_data.get("topic")
        title = notification_data.get("title")
        body = notification_data.get("body")
        screen = notification_data.get("screen", "/home")
        notification_type = notification_data.get("type", "general")
        priority = notification_data.get("priority", "normal")
        
        logger.info(f"Processing topic notification for: {topic}")
        
        # Create FCM message
        message = messaging.Message(
            topic=topic,
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={
                "screen": screen,
                "type": notification_type,
            },
            android=messaging.AndroidConfig(
                priority="high" if priority == "high" else "normal",
                notification=messaging.AndroidNotification(
                    channel_id="pinesville_default_channel",
                    icon="@mipmap/ic_launcher",
                    sound="default",
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound="default",
                        badge=1,
                    ),
                ),
            ),
        )
        
        # Send notification
        response = messaging.send(message)
        logger.info(f"Topic notification sent successfully: {response}")
        
        # Delete from queue after successful send
        event.data.reference.delete()
        queue_id = event.params.get("queueId")
        logger.info(f"Deleted notification from queue: {queue_id}")
        
    except Exception as e:
        logger.error(f"Error sending topic notification: {str(e)}")


@scheduler_fn.on_schedule(schedule="0 9 * * *", timezone="Asia/Manila")
def send_daily_payment_reminders(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function that runs daily at 9:00 AM Manila time.
    Sends payment reminders for bills due in 3 days.
    """
    try:
        logger.info("Starting daily payment reminder check...")
        db = firestore.client()
        
        # Calculate date range for bills due in exactly 3 days
        three_days_from_now = datetime.now() + timedelta(days=3)
        start_of_day = datetime(
            three_days_from_now.year,
            three_days_from_now.month,
            three_days_from_now.day,
            0, 0, 0
        )
        end_of_day = start_of_day + timedelta(days=1)
        
        # Query unpaid bills due in 3 days
        bills_ref = db.collection("Bills")
        bills = bills_ref.where("isPaid", "==", False) \\
                        .where("billingPeriod.dueDate", ">=", start_of_day) \\
                        .where("billingPeriod.dueDate", "<", end_of_day) \\
                        .stream()
        
        count = 0
        for bill in bills:
            try:
                bill_data = bill.to_dict()
                user_id = bill_data.get("userId")
                balance = bill_data.get("summary", {}).get("balance", 0.0)
                due_date = bill_data.get("billingPeriod", {}).get("dueDate")
                
                # Create notification document (will trigger send_notification_to_user)
                db.collection("Notifications").add({
                    "userId": user_id,
                    "title": "Payment Reminder 🔔",
                    "body": f"Your bill of ₱{balance:.2f} is due on {due_date.strftime('%m/%d/%Y')}. Pay soon to avoid late fees.",
                    "screen": f"/billing/{bill.id}",
                    "type": "payment_reminder",
                    "read": False,
                    "createdAt": firestore.SERVER_TIMESTAMP,
                })
                
                count += 1
                logger.info(f"Queued reminder for bill {bill.id} to user {user_id}")
                
            except Exception as e:
                logger.error(f"Error processing bill {bill.id}: {str(e)}")
        
        logger.info(f"Payment reminder check complete. Sent {count} reminders.")
        
    except Exception as e:
        logger.error(f"Error in scheduled payment reminders: {str(e)}")


@scheduler_fn.on_schedule(schedule="0 10 * * *", timezone="Asia/Manila")
def send_daily_late_fee_notifications(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function that runs daily at 10:00 AM Manila time.
    Sends notifications for newly applied late fees.
    """
    try:
        logger.info("Starting daily late fee notification check...")
        db = firestore.client()
        
        # Query overdue bills
        bills_ref = db.collection("Bills")
        bills = bills_ref.where("isOverdue", "==", True) \\
                        .where("isPaid", "==", False) \\
                        .stream()
        
        count = 0
        for bill in bills:
            try:
                bill_data = bill.to_dict()
                user_id = bill_data.get("userId")
                late_fee_details = bill_data.get("lateFeeDetails", {})
                
                if not late_fee_details:
                    continue
                
                last_calculated = late_fee_details.get("lastCalculated")
                if not last_calculated:
                    continue
                
                # Only notify if late fee was calculated in the last 24 hours
                hours_since = (datetime.now() - last_calculated).total_seconds() / 3600
                
                if hours_since <= 24:
                    late_fee_amount = late_fee_details.get("totalLateFee", 0.0)
                    total_balance = bill_data.get("summary", {}).get("balance", 0.0)
                    
                    # Create notification document
                    db.collection("Notifications").add({
                        "userId": user_id,
                        "title": "Late Fee Applied ⚠️",
                        "body": f"A late fee of ₱{late_fee_amount:.2f} has been added. Total balance now ₱{total_balance:.2f}",
                        "screen": f"/billing/{bill.id}",
                        "type": "late_fee",
                        "read": False,
                        "createdAt": firestore.SERVER_TIMESTAMP,
                    })
                    
                    count += 1
                    logger.info(f"Queued late fee notification for bill {bill.id}")
                    
            except Exception as e:
                logger.error(f"Error processing bill {bill.id}: {str(e)}")
        
        logger.info(f"Late fee notification check complete. Sent {count} notifications.")
        
    except Exception as e:
        logger.error(f"Error in scheduled late fee notifications: {str(e)}")


@scheduler_fn.on_schedule(schedule="0 0 * * *", timezone="Asia/Manila")
def update_late_fees_daily(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function that runs daily at midnight Manila time.
    Recalculates and updates late fees for all overdue bills.
    """
    try:
        logger.info("Starting daily late fee update...")
        db = firestore.client()
        
        # Get all overdue unpaid bills
        bills_ref = db.collection("Bills")
        bills = bills_ref.where("isPaid", "==", False) \
                        .where("isOverdue", "==", True) \
                        .stream()
        
        count = 0
        for bill_doc in bills:
            try:
                bill_data = bill_doc.to_dict()
                bill_id = bill_doc.id
                user_id = bill_data.get("userId")
                property_id = bill_data.get("propertyId")
                unit_id = bill_data.get("unitId")
                
                billing_period = bill_data.get("billingPeriod", {})
                due_date_str = billing_period.get("dueDate")
                if not due_date_str:
                    continue
                
                due_date = datetime.fromisoformat(due_date_str.replace('Z', '+00:00'))
                
                # Check for next bill (to freeze late fees)
                next_bill_created_at = None
                next_month = billing_period.get("month") + 1
                next_year = billing_period.get("year")
                
                if next_month > 12:
                    next_month = 1
                    next_year += 1
                
                next_bills = bills_ref.where("userId", "==", user_id) \
                                    .where("propertyId", "==", property_id) \
                                    .where("unitId", "==", unit_id) \
                                    .where("billingPeriod.month", "==", next_month) \
                                    .where("billingPeriod.year", "==", next_year) \
                                    .limit(1) \
                                    .get()
                
                if next_bills:
                    next_bill_data = next_bills[0].to_dict()
                    created_at_str = next_bill_data.get("createdAt")
                    if created_at_str:
                        next_bill_created_at = datetime.fromisoformat(created_at_str.replace('Z', '+00:00'))
                
                # Calculate late fee
                calculation_end = next_bill_created_at or datetime.now()
                
                if calculation_end > due_date:
                    days_overdue = (calculation_end - due_date).days
                    weeks_overdue = (days_overdue // 7) + (1 if days_overdue % 7 > 0 else 0)
                    total_late_fee = weeks_overdue * 150.0
                    
                    # Get current values
                    current_late_fee_details = bill_data.get("lateFeeDetails", {})
                    current_late_fee = current_late_fee_details.get("totalLateFee", 0.0)
                    
                    # Only update if late fee changed
                    if total_late_fee != current_late_fee:
                        subtotal = bill_data.get("summary", {}).get("subtotal", 0.0)
                        amount_paid = bill_data.get("summary", {}).get("amountPaid", 0.0)
                        new_total = subtotal + total_late_fee
                        new_balance = new_total - amount_paid
                        
                        # Update bill
                        bill_doc.reference.update({
                            "lateFeeDetails": {
                                "isLate": True,
                                "weeksOverdue": weeks_overdue,
                                "lateFeePerWeek": 150.0,
                                "totalLateFee": total_late_fee,
                                "lateFeeAppliedAt": calculation_end.isoformat(),
                                "gracePeriodEnd": due_date.isoformat(),
                                "lastCalculated": datetime.now().isoformat(),
                            },
                            "summary.lateFee": total_late_fee,
                            "summary.total": new_total,
                            "summary.balance": new_balance,
                            "updatedAt": datetime.now().isoformat(),
                        })
                        
                        count += 1
                        logger.info(f"Updated late fee for bill {bill_id}: ₱{current_late_fee:.2f} → ₱{total_late_fee:.2f}")
                        
            except Exception as e:
                logger.error(f"Error updating bill {bill_doc.id}: {str(e)}")
        
        logger.info(f"Late fee update complete. Updated {count} bills.")
        
    except Exception as e:
        logger.error(f"Error in scheduled late fee update: {str(e)}")
