# Billing Database Structure for Pinesville App

## Overview
This document outlines the Firebase Firestore database structure for the billing and payment system.

**Last Updated:** October 2025  
**Recent Changes:**
- Removed `additionalCharges` array from bill storage (data now only in `paymentBreakdown`)
- Added optional `description` field to `paymentBreakdown.additionalCharges` 
- Unified fixed charges (trash, wifi, parking) at property level in `fixedCharges` map
- Removed unit-level parking references

---

## Collections Structure

### 1. **Bills** Collection
**Path:** Bills/{billId}

Each bill document represents a monthly billing statement for a tenant.

\\\json
{
  "billId": "BILL_2025_09_USER123",
  "userId": "USER123",
  "userEmail": "john.doe@example.com",
  "userName": "John Doe",
  "unitId": "UNIT_101",
  "propertyId": "PROPERTY_001",
  
  // Billing Period
  "billingPeriod": {
    "month": 9,
    "year": 2025,
    "startDate": "2025-09-01T00:00:00Z",
    "endDate": "2025-09-30T23:59:59Z",
    "dueDate": "2025-10-05T23:59:59Z",
    "billingCycle": "monthly"
  },
  
  // Rent Charges
  "rent": {
    "baseRent": 25000.00,
    "description": "Monthly rent for Unit 101"
  },
  
  // Utility Readings and Charges
  "utilities": {
    "electricity": {
      "previousReading": 1250.50,
      "currentReading": 1380.75,
      "consumption": 130.25,
      "unit": "kWh",
      "ratePerUnit": 12.50,
      "amount": 1628.13,
      "meterNumber": "ELEC-101-001",
      "readingDate": "2025-09-30T10:00:00Z"
    },
    "water": {
      "previousReading": 850.00,
      "currentReading": 925.00,
      "consumption": 75.00,
      "unit": "cubic meters",
      "ratePerUnit": 35.00,
      "amount": 2625.00,
      "meterNumber": "WATER-101-001",
      "readingDate": "2025-09-30T10:30:00Z"
    }
  },
  
  // Additional Charges (DEPRECATED - October 2025)
  // This field is no longer stored in new bills. Data is now only in paymentBreakdown.
  // Kept in BillModel for backward compatibility with old bills.
  // "additionalCharges": [],  // Always empty for new bills
  
  // Bill Summary
  "summary": {
    "subtotal": 29753.13,
    "discount": 0.00,
    "discountReason": "",
    "lateFee": 0.00,
    "lateFeeWeeks": 0,
    "tax": 0.00,
    "total": 29753.13,
    "amountPaid": 0.00,
    "balance": 29753.13
  },
  
  // Late Fee Tracking
  "lateFeeDetails": {
    "isLate": false,
    "weeksOverdue": 0,
    "lateFeePerWeek": 150.00,
    "totalLateFee": 0.00,
    "lateFeeAppliedAt": null,
    "gracePeriodEnd": "2025-10-12T23:59:59Z"
  },
  
  // Partial Payment Tracking (Expanded for individual tracking)
  "paymentBreakdown": {
    "rent": {
      "amount": 25000.00,
      "amountPaid": 0.00,
      "balance": 25000.00,
      "isPaid": false,
      "paidAt": null
    },
    "electricity": {
      "amount": 1628.13,
      "amountPaid": 0.00,
      "balance": 1628.13,
      "isPaid": false,
      "paidAt": null
    },
    "water": {
      "amount": 2625.00,
      "amountPaid": 0.00,
      "balance": 2625.00,
      "isPaid": false,
      "paidAt": null
    },
    "trash": {
      "amount": 200.00,
      "amountPaid": 0.00,
      "balance": 200.00,
      "isPaid": false,
      "paidAt": null
    },
    "wifi": {
      "amount": 500.00,
      "amountPaid": 0.00,
      "balance": 500.00,
      "isPaid": false,
      "paidAt": null
    },
    "parking": {
      "amount": 1000.00,
      "amountPaid": 0.00,
      "balance": 1000.00,
      "isPaid": false,
      "paidAt": null
    },
    "additionalCharges": {
      "amount": 300.00,
      "amountPaid": 0.00,
      "balance": 300.00,
      "isPaid": false,
      "paidAt": null,
      "description": "Late payment penalty"  // Optional: Admin-provided description
    }
  },
  
  // Bill Status
  "status": "pending", // pending, partially_paid, paid, overdue, cancelled
  "isPaid": false,
  "isOverdue": false,
  "isPartiallyPaid": false,
  
  // Timestamps
  "createdAt": "2025-09-30T15:00:00Z",
  "updatedAt": "2025-09-30T15:00:00Z",
  "paidAt": null,
  
  // Receipt Generation
  "receiptGenerated": false,
  "receiptUrl": null,
  "receiptGeneratedAt": null,
  
  // Metadata
  "generatedBy": "ADMIN_USER_ID",
  "notes": "",
  "attachments": []
}
\\\

---

### 1.1 **Property** Collection (Property-Specific Configuration)
**Path:** Property/{propertyId}

Each property has its own utility rates and fixed charges.

```json
{
  "propertyId": "PROP_001",
  "propertyName": "Pinesville Tower A",
  "address": "123 Main Street, City",
  
  // Property-Specific Rates
  "utilityRates": {
    "electricity": {
      "ratePerKwh": 12.50,
      "effectiveDate": "2025-01-01T00:00:00Z",
      "currency": "PHP"
    },
    "water": {
      "ratePerCubicMeter": 35.00,
      "effectiveDate": "2025-01-01T00:00:00Z",
      "currency": "PHP"
    }
  },
  
  // Fixed Charges per Property
  "fixedCharges": {
    "trash": {
      "amount": 200.00,
      "enabled": true,
      "description": "Trash Collection"
    },
    "wifi": {
      "amount": 500.00,
      "enabled": true,
      "description": "WiFi Service"
    },
    "parking": {
      "amount": 1000.00,
      "enabled": true,
      "description": "Parking Fee"
    }
  },
  
  "createdAt": "2025-01-01T00:00:00Z",
  "updatedAt": "2025-01-01T00:00:00Z"
}
```

---

### 1.2 **Units** Subcollection (Property Units with Last Readings)
**Path:** Property/{propertyId}/Units/{unitId}

Each unit stores the last meter readings for the next billing cycle.

```json
{
  "unitId": "UNIT_101",
  "unitNumber": "101",
  "floor": 1,
  "propertyId": "PROP_001",
  
  // Rental Information
  "rental": {
    "monthlyRent": 25000.00,
    "status": "occupied",
    "tenantId": "USER123"
  },
  
  // Parking (DEPRECATED - October 2025)
  // Parking is now managed at property level in fixedCharges.
  // This field may exist in legacy units but is no longer used for billing.
  
  // Last Meter Readings (used as previous reading for next billing)
  "lastReadings": {
    "electricity": {
      "reading": 1380.75,
      "readingDate": "2025-09-30T10:00:00Z",
      "meterNumber": "ELEC-101-001"
    },
    "water": {
      "reading": 925.00,
      "readingDate": "2025-09-30T10:30:00Z",
      "meterNumber": "WATER-101-001"
    }
  },
  
  "createdAt": "2025-01-01T00:00:00Z",
  "updatedAt": "2025-09-30T15:00:00Z"
}
```

---

### 2. **Payments** Collection (Transaction History)
**Path:** Payments/{paymentId}

Each document represents a payment transaction made by a tenant.

\\\json
{
  "paymentId": "PAY_20250930_123456",
  "billId": "BILL_2025_09_USER123",
  "userId": "USER123",
  "userEmail": "john.doe@example.com",
  "userName": "John Doe",
  "unitId": "UNIT_101",
  
  // Payment Details
  "amount": 25000.00,
  "paymentType": "partial", // full, partial
  "paymentMethod": "gcash", // gcash, bdo, cash, bank_transfer, credit_card
  "paymentMethodDetails": {
    "provider": "GCash",
    "accountNumber": "09171234567",
    "referenceNumber": "GCASH-2025-09-30-789456"
  },
  
  // Payment Allocation (for partial payments - expanded categories)
  "paymentAllocation": {
    "rent": {
      "amount": 25000.00,
      "appliedAt": "2025-09-30T16:30:00Z"
    },
    "electricity": {
      "amount": 0.00,
      "appliedAt": null
    },
    "water": {
      "amount": 0.00,
      "appliedAt": null
    },
    "trash": {
      "amount": 0.00,
      "appliedAt": null
    },
    "wifi": {
      "amount": 0.00,
      "appliedAt": null
    },
    "parking": {
      "amount": 0.00,
      "appliedAt": null
    },
    "additionalCharges": {
      "amount": 0.00,
      "appliedAt": null
    }
  },
  
  // What this payment covers
  "paidFor": ["rent"], // Array: rent, electricity, water, trash, wifi, parking, additionalCharges
  
  // Transaction Info
  "transactionDate": "2025-09-30T16:30:00Z",
  "transactionId": "TXN_789456123",
  "receiptNumber": "REC_2025_09_0001",
  
  // Status
  "status": "completed", // pending, completed, failed, refunded
  "paymentStatus": "verified", // pending_verification, verified, rejected
  
  // Verification
  "verifiedBy": "ADMIN_USER_ID",
  "verifiedAt": "2025-09-30T17:00:00Z",
  
  // Proof of Payment
  "proofOfPayment": {
    "imageUrl": "https://storage.googleapis.com/.../payment_proof.jpg",
    "uploadedAt": "2025-09-30T16:25:00Z"
  },
  
  // Timestamps
  "createdAt": "2025-09-30T16:30:00Z",
  "updatedAt": "2025-09-30T17:00:00Z",
  
  // Metadata
  "notes": "Payment for September 2025 bill",
  "adminNotes": "Verified and approved"
}
\\\

---

### 3. **MeterReadings** Collection (Historical Readings)
**Path:** MeterReadings/{readingId}

Stores all meter readings for electricity and water consumption tracking.

\\\json
{
  "readingId": "READING_2025_09_ELEC_USER123",
  "userId": "USER123",
  "unitId": "UNIT_101",
  "propertyId": "PROPERTY_001",
  
  // Meter Information
  "meterType": "electricity", // electricity, water
  "meterNumber": "ELEC-101-001",
  
  // Reading Details
  "reading": 1380.75,
  "previousReading": 1250.50,
  "consumption": 130.25,
  "unit": "kWh",
  
  // Reading Period
  "readingDate": "2025-09-30T10:00:00Z",
  "billingPeriod": {
    "month": 9,
    "year": 2025
  },
  
  // Reading Source
  "recordedBy": "ADMIN_USER_ID",
  "recordedByName": "Admin User",
  "readingMethod": "manual", // manual, automatic, estimated
  
  // Photos/Proof
  "meterPhoto": {
    "imageUrl": "https://storage.googleapis.com/.../meter_reading.jpg",
    "uploadedAt": "2025-09-30T10:05:00Z"
  },
  
  // Timestamps
  "createdAt": "2025-09-30T10:00:00Z",
  "updatedAt": "2025-09-30T10:00:00Z",
  
  // Status
  "status": "confirmed", // pending, confirmed, disputed
  "notes": ""
}
\\\

---

### 4. **ConsumptionAnalytics** Collection (Monthly Comparison)
**Path:** Users/{userId}/ConsumptionAnalytics/{year}

Aggregated consumption data for analytics and comparison.

\\\json
{
  "userId": "USER123",
  "year": 2025,
  "unitId": "UNIT_101",
  
  // Monthly Breakdown
  "monthlyData": {
    "january": {
      "month": 1,
      "electricity": {
        "consumption": 125.50,
        "cost": 1568.75,
        "previousReading": 1000.00,
        "currentReading": 1125.50
      },
      "water": {
        "consumption": 68.00,
        "cost": 2380.00,
        "previousReading": 700.00,
        "currentReading": 768.00
      },
      "totalUtilityCost": 3948.75,
      "totalBill": 29448.75
    },
    "february": {
      "month": 2,
      "electricity": {
        "consumption": 118.00,
        "cost": 1475.00,
        "previousReading": 1125.50,
        "currentReading": 1243.50
      },
      "water": {
        "consumption": 72.00,
        "cost": 2520.00,
        "previousReading": 768.00,
        "currentReading": 840.00
      },
      "totalUtilityCost": 3995.00,
      "totalBill": 29495.00
    },
    // ... continues for all months
    "september": {
      "month": 9,
      "electricity": {
        "consumption": 130.25,
        "cost": 1628.13,
        "previousReading": 1250.50,
        "currentReading": 1380.75
      },
      "water": {
        "consumption": 75.00,
        "cost": 2625.00,
        "previousReading": 850.00,
        "currentReading": 925.00
      },
      "totalUtilityCost": 4253.13,
      "totalBill": 29753.13
    }
  },
  
  // Year Summary
  "yearSummary": {
    "totalElectricityConsumption": 1150.75,
    "totalElectricityCost": 14384.38,
    "totalWaterConsumption": 650.00,
    "totalWaterCost": 22750.00,
    "totalUtilityCost": 37134.38,
    "totalBillsAmount": 267134.38,
    "averageMonthlyElectricity": 127.86,
    "averageMonthlyWater": 72.22,
    "averageMonthlyBill": 29681.60
  },
  
  // Comparison Stats
  "trends": {
    "electricityTrend": "increasing", // increasing, decreasing, stable
    "waterTrend": "stable",
    "percentageChangeElectricity": 3.8,
    "percentageChangeWater": 0.5
  },
  
  // Timestamps
  "lastUpdated": "2025-09-30T15:00:00Z"
}
\\\

---

### 5. **BillingSettings** Collection (Configuration)
**Path:** BillingSettings/config

Global billing configuration and utility rates.

\\\json
{
  // Utility Rates
  "utilityRates": {
    "electricity": {
      "ratePerKwh": 12.50,
      "currency": "PHP",
      "effectiveDate": "2025-01-01T00:00:00Z",
      "previousRate": 12.00
    },
    "water": {
      "ratePerCubicMeter": 35.00,
      "currency": "PHP",
      "effectiveDate": "2025-01-01T00:00:00Z",
      "previousRate": 33.00
    }
  },
  
  // Billing Configuration
  "billingConfig": {
    "billingCycle": "monthly",
    "dueAfterDays": 7,
    "lateFeeAmount": 150.00,
    "lateFeeIntervalDays": 7,
    "lateFeeGracePeriod": 7,
    "maxLateFeeWeeks": 4,
    "sendReminderDaysBefore": 3,
    "autoGenerateBills": true,
    "billGenerationDay": 30,
    "autoEvictionAfterMonths": 2
  },
  
  // Payment Methods
  "paymentMethods": [
    {
      "method": "gcash",
      "enabled": true,
      "accountName": "Pinesville Property",
      "accountNumber": "09171234567",
      "qrCodeUrl": "https://storage.googleapis.com/.../gcash_qr.png"
    },
    {
      "method": "bdo",
      "enabled": true,
      "accountName": "Pinesville Property Management",
      "accountNumber": "1234567890",
      "branch": "Makati Branch"
    },
    {
      "method": "cash",
      "enabled": true,
      "officeHours": "Mon-Fri 9AM-5PM",
      "location": "Admin Office, Ground Floor"
    }
  ],
  
  // Additional Charges Templates
  "standardCharges": [
    {
      "chargeId": "ASSOC_DUES",
      "description": "Association Dues",
      "amount": 500.00,
      "category": "association_fees",
      "applyToAll": true
    },
    {
      "chargeId": "PARKING",
      "description": "Parking Fee",
      "amount": 1000.00,
      "category": "parking",
      "applyToAll": false
    }
  ],
  
  "lastUpdated": "2025-01-01T00:00:00Z"
}
\\\

---

## Firestore Security Rules Example

\\\javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Bills - Users can read their own bills, admins can read/write all
    match /Bills/{billId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases//documents/Users/).data.account.role == 'admin');
      allow create, update, delete: if request.auth != null && 
        get(/databases//documents/Users/).data.account.role == 'admin';
    }
    
    // Payments - Users can read/create their own, admins can manage all
    match /Payments/{paymentId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases//documents/Users/).data.account.role == 'admin');
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth != null && 
        get(/databases//documents/Users/).data.account.role == 'admin';
    }
    
    // Meter Readings - Read only for users, admin can manage
    match /MeterReadings/{readingId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases//documents/Users/).data.account.role == 'admin');
      allow create, update, delete: if request.auth != null && 
        get(/databases//documents/Users/).data.account.role == 'admin';
    }
    
    // Consumption Analytics - Users can read their own
    match /Users/{userId}/ConsumptionAnalytics/{analyticsId} {
      allow read: if request.auth != null && 
        (request.auth.uid == userId || 
         get(/databases//documents/Users/).data.account.role == 'admin');
      allow write: if request.auth != null && 
        get(/databases//documents/Users/).data.account.role == 'admin';
    }
    
    // Billing Settings - Admin only
    match /BillingSettings/{doc} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases//documents/Users/).data.account.role == 'admin';
    }
  }
}
\\\

---

## Query Examples

### Get User's Bills (Sorted by Date)
\\\dart
final bills = await firestore
  .collection('Bills')
  .where('userId', isEqualTo: userId)
  .orderBy('billingPeriod.year', descending: true)
  .orderBy('billingPeriod.month', descending: true)
  .limit(12)
  .get();
\\\

### Get Payment History
\\\dart
final payments = await firestore
  .collection('Payments')
  .where('userId', isEqualTo: userId)
  .where('status', isEqualTo: 'completed')
  .orderBy('transactionDate', descending: true)
  .get();
\\\

### Get Meter Readings for a Period
\\\dart
final readings = await firestore
  .collection('MeterReadings')
  .where('userId', isEqualTo: userId)
  .where('billingPeriod.year', isEqualTo: 2025)
  .where('billingPeriod.month', isEqualTo: 9)
  .get();
\\\

### Get Consumption Analytics
\\\dart
final analytics = await firestore
  .collection('Users')
  .doc(userId)
  .collection('ConsumptionAnalytics')
  .doc('2025')
  .get();
\\\

### Get Overdue Bills
\\\dart
final overdueBills = await firestore
  .collection('Bills')
  .where('userId', isEqualTo: userId)
  .where('isOverdue', isEqualTo: true)
  .where('isPaid', isEqualTo: false)
  .get();
\\\

---

## Indexes Required

Create these composite indexes in Firebase Console:

1. **Bills Collection**
   - userId (Ascending) + billingPeriod.year (Descending) + billingPeriod.month (Descending)
   - userId (Ascending) + status (Ascending) + billingPeriod.year (Descending)
   - userId (Ascending) + isOverdue (Ascending) + isPaid (Ascending)

2. **Payments Collection**
   - userId (Ascending) + transactionDate (Descending)
   - userId (Ascending) + status (Ascending) + transactionDate (Descending)
   - billId (Ascending) + status (Ascending)

3. **MeterReadings Collection**
   - userId (Ascending) + meterType (Ascending) + billingPeriod.year (Ascending) + billingPeriod.month (Ascending)
   - userId (Ascending) + readingDate (Descending)

---

## Features Supported

 **Bill Breakdown per Month**
- Complete itemization of rent, utilities, and additional charges
- Monthly bill generation with detailed line items

 **Utility Readings & Consumption**
- Previous and current meter readings
- Automatic consumption calculation
- Separate tracking for electricity and water
- Rate per unit and total amount calculation

 **Transaction History**
- Complete payment records with verification status
- Multiple payment methods support
- Receipt numbers and transaction IDs
- Proof of payment storage

 **Monthly Consumption Comparison**
- Year-over-year analytics
- Month-to-month comparison
- Trend analysis (increasing/decreasing/stable)
- Average consumption calculations
- Visual data for charts and graphs

 **Additional Features**
- Late fee calculation
- Overdue bill tracking
- Payment verification workflow
- Multiple payment methods
- Meter reading photos
- Admin notes and tenant notes
- **Partial payment support** (pay rent first, utilities later)
- **Payment allocation tracking** (see exactly what was paid and what's remaining)

---

## Partial Payment Examples

### Example 1: User Pays Rent First (₱25,000)

**Step 1: Create Payment for Rent Only**
\\\json
{
  "paymentId": "PAY_20250930_123456",
  "billId": "BILL_2025_09_USER123",
  "userId": "USER123",
  "amount": 25000.00,
  "paymentType": "partial",
  "paymentAllocation": {
    "rent": {
      "amount": 25000.00,
      "appliedAt": "2025-09-30T16:30:00Z"
    },
    "electricity": { "amount": 0.00, "appliedAt": null },
    "water": { "amount": 0.00, "appliedAt": null },
    "additionalCharges": { "amount": 0.00, "appliedAt": null }
  },
  "paidFor": ["rent"],
  "status": "completed",
  "transactionDate": "2025-09-30T16:30:00Z"
}
\\\

**Step 2: Update Bill Document**
\\\json
{
  "billId": "BILL_2025_09_USER123",
  "summary": {
    "total": 29753.13,
    "amountPaid": 25000.00,
    "balance": 4753.13
  },
  "paymentBreakdown": {
    "rent": {
      "amount": 25000.00,
      "amountPaid": 25000.00,
      "balance": 0.00,
      "isPaid": true,
      "paidAt": "2025-09-30T16:30:00Z"
    },
    "electricity": {
      "amount": 1628.13,
      "amountPaid": 0.00,
      "balance": 1628.13,
      "isPaid": false,
      "paidAt": null
    },
    "water": {
      "amount": 2625.00,
      "amountPaid": 0.00,
      "balance": 2625.00,
      "isPaid": false,
      "paidAt": null
    },
    "additionalCharges": {
      "amount": 1500.00,
      "amountPaid": 0.00,
      "balance": 1500.00,
      "isPaid": false,
      "paidAt": null
    }
  },
  "status": "partially_paid",
  "isPaid": false,
  "isPartiallyPaid": true
}
\\\

### Example 2: User Later Pays Utilities (₱4,753.13)

**Step 1: Create Second Payment for Utilities**
\\\json
{
  "paymentId": "PAY_20251005_654321",
  "billId": "BILL_2025_09_USER123",
  "userId": "USER123",
  "amount": 4753.13,
  "paymentType": "partial",
  "paymentAllocation": {
    "rent": { "amount": 0.00, "appliedAt": null },
    "electricity": {
      "amount": 1628.13,
      "appliedAt": "2025-10-05T14:20:00Z"
    },
    "water": {
      "amount": 2625.00,
      "appliedAt": "2025-10-05T14:20:00Z"
    },
    "additionalCharges": {
      "amount": 1500.00,
      "appliedAt": "2025-10-05T14:20:00Z"
    }
  },
  "paidFor": ["electricity", "water", "additionalCharges"],
  "status": "completed",
  "transactionDate": "2025-10-05T14:20:00Z"
}
\\\

**Step 2: Update Bill Document to Fully Paid**
\\\json
{
  "billId": "BILL_2025_09_USER123",
  "summary": {
    "total": 29753.13,
    "amountPaid": 29753.13,
    "balance": 0.00
  },
  "paymentBreakdown": {
    "rent": {
      "amount": 25000.00,
      "amountPaid": 25000.00,
      "balance": 0.00,
      "isPaid": true,
      "paidAt": "2025-09-30T16:30:00Z"
    },
    "electricity": {
      "amount": 1628.13,
      "amountPaid": 1628.13,
      "balance": 0.00,
      "isPaid": true,
      "paidAt": "2025-10-05T14:20:00Z"
    },
    "water": {
      "amount": 2625.00,
      "amountPaid": 2625.00,
      "balance": 0.00,
      "isPaid": true,
      "paidAt": "2025-10-05T14:20:00Z"
    },
    "additionalCharges": {
      "amount": 1500.00,
      "amountPaid": 1500.00,
      "balance": 0.00,
      "isPaid": true,
      "paidAt": "2025-10-05T14:20:00Z"
    }
  },
  "status": "paid",
  "isPaid": true,
  "isPartiallyPaid": false,
  "paidAt": "2025-10-05T14:20:00Z"
}
\\\

### Example 3: User Pays Only Water First (₱2,625)

\\\json
{
  "paymentId": "PAY_20251001_111111",
  "billId": "BILL_2025_09_USER123",
  "userId": "USER123",
  "amount": 2625.00,
  "paymentType": "partial",
  "paymentAllocation": {
    "rent": { "amount": 0.00, "appliedAt": null },
    "electricity": { "amount": 0.00, "appliedAt": null },
    "water": {
      "amount": 2625.00,
      "appliedAt": "2025-10-01T10:00:00Z"
    },
    "additionalCharges": { "amount": 0.00, "appliedAt": null }
  },
  "paidFor": ["water"],
  "status": "completed"
}
\\\

**Bill Update:**
\\\json
{
  "summary": {
    "total": 29753.13,
    "amountPaid": 2625.00,
    "balance": 27128.13
  },
  "paymentBreakdown": {
    "rent": {
      "amount": 25000.00,
      "amountPaid": 0.00,
      "balance": 25000.00,
      "isPaid": false
    },
    "water": {
      "amount": 2625.00,
      "amountPaid": 2625.00,
      "balance": 0.00,
      "isPaid": true,
      "paidAt": "2025-10-01T10:00:00Z"
    }
    // ... other charges remain unpaid
  },
  "status": "partially_paid",
  "isPartiallyPaid": true
}
\\\

---

## Query Examples for Partial Payments

### Get Partially Paid Bills
\\\dart
final partiallyPaidBills = await firestore
  .collection('Bills')
  .where('userId', isEqualTo: userId)
  .where('isPartiallyPaid', isEqualTo: true)
  .where('isPaid', isEqualTo: false)
  .get();
\\\

### Get Payment History for a Bill
\\\dart
final billPayments = await firestore
  .collection('Payments')
  .where('billId', isEqualTo: billId)
  .where('status', isEqualTo: 'completed')
  .orderBy('transactionDate', ascending: true)
  .get();
\\\

### Check What's Unpaid in a Bill
\\\dart
Future<Map<String, double>> getUnpaidBreakdown(String billId) async {
  final billDoc = await firestore.collection('Bills').doc(billId).get();
  final breakdown = billDoc.data()!['paymentBreakdown'] as Map<String, dynamic>;
  
  Map<String, double> unpaid = {};
  
  breakdown.forEach((key, value) {
    if (value['isPaid'] == false && value['balance'] > 0) {
      unpaid[key] = value['balance'];
    }
  });
  
  return unpaid;
}
\\\

### Get Bills with Unpaid Rent
\\\dart
final billsWithUnpaidRent = await firestore
  .collection('Bills')
  .where('userId', isEqualTo: userId)
  .where('paymentBreakdown.rent.isPaid', isEqualTo: false)
  .where('paymentBreakdown.rent.balance', isGreaterThan: 0)
  .get();
\\\

---

## Business Logic for Partial Payments

### Cloud Function: Process Partial Payment

\\\dart
// Example Cloud Function or Repository Method
Future<void> processPartialPayment({
  required String billId,
  required String userId,
  required double amount,
  required List<String> payFor, // ['rent'], ['water', 'electricity'], etc.
  required String paymentMethod,
  required Map<String, dynamic> paymentDetails,
}) async {
  final billRef = firestore.collection('Bills').doc(billId);
  final billSnapshot = await billRef.get();
  final billData = billSnapshot.data()!;
  
  // Calculate allocation
  Map<String, double> allocation = {};
  double totalAllocated = 0.0;
  
  for (String category in payFor) {
    final categoryData = billData['paymentBreakdown'][category];
    final balance = categoryData['balance'] as double;
    allocation[category] = balance;
    totalAllocated += balance;
  }
  
  // Verify amount matches
  if (totalAllocated != amount) {
    throw Exception('Payment amount does not match selected items');
  }
  
  // Create payment document
  final paymentId = 'PAY_${DateTime.now().millisecondsSinceEpoch}';
  final paymentAllocation = {
    'rent': {
      'amount': allocation['rent'] ?? 0.0,
      'appliedAt': payFor.contains('rent') ? FieldValue.serverTimestamp() : null,
    },
    'electricity': {
      'amount': allocation['electricity'] ?? 0.0,
      'appliedAt': payFor.contains('electricity') ? FieldValue.serverTimestamp() : null,
    },
    'water': {
      'amount': allocation['water'] ?? 0.0,
      'appliedAt': payFor.contains('water') ? FieldValue.serverTimestamp() : null,
    },
    'additionalCharges': {
      'amount': allocation['additionalCharges'] ?? 0.0,
      'appliedAt': payFor.contains('additionalCharges') ? FieldValue.serverTimestamp() : null,
    },
  };
  
  await firestore.collection('Payments').doc(paymentId).set({
    'paymentId': paymentId,
    'billId': billId,
    'userId': userId,
    'amount': amount,
    'paymentType': 'partial',
    'paymentMethod': paymentMethod,
    'paymentMethodDetails': paymentDetails,
    'paymentAllocation': paymentAllocation,
    'paidFor': payFor,
    'status': 'pending',
    'paymentStatus': 'pending_verification',
    'transactionDate': FieldValue.serverTimestamp(),
    'createdAt': FieldValue.serverTimestamp(),
  });
  
  // Update bill breakdown
  Map<String, dynamic> updates = {};
  double newTotalPaid = billData['summary']['amountPaid'] + amount;
  double newBalance = billData['summary']['balance'] - amount;
  
  for (String category in payFor) {
    final categoryBalance = allocation[category]!;
    updates['paymentBreakdown.$category.amountPaid'] = FieldValue.increment(categoryBalance);
    updates['paymentBreakdown.$category.balance'] = FieldValue.increment(-categoryBalance);
    updates['paymentBreakdown.$category.isPaid'] = true;
    updates['paymentBreakdown.$category.paidAt'] = FieldValue.serverTimestamp();
  }
  
  updates['summary.amountPaid'] = newTotalPaid;
  updates['summary.balance'] = newBalance;
  
  // Determine bill status
  if (newBalance == 0) {
    updates['status'] = 'paid';
    updates['isPaid'] = true;
    updates['isPartiallyPaid'] = false;
    updates['paidAt'] = FieldValue.serverTimestamp();
  } else {
    updates['status'] = 'partially_paid';
    updates['isPaid'] = false;
    updates['isPartiallyPaid'] = true;
  }
  
  updates['updatedAt'] = FieldValue.serverTimestamp();
  
  await billRef.update(updates);
}
\\\

---

## Migration Path from Old Structure

If you have existing data, follow this migration:

1. Create new collections
2. Write migration scripts to transform old data
3. Run parallel systems during transition
4. Validate data integrity
5. Switch to new structure
6. Archive old data

---

## Next Steps

1. ✅ Review and approve this structure
2. ✅ Create data models in Flutter
3. ✅ Build repository layer  
4. ✅ Create Riverpod providers
5. ⏳ Create Firebase indexes
6. ⏳ Implement security rules in Firebase Console
7. ⏳ Implement UI screens
8. ⏳ Add analytics and reporting
9. ⏳ Test partial payment workflows
10. ⏳ Deploy to production

---

**Last Updated:** October 7, 2025  
**Version:** 1.2  
**Status:** Database Schema Reference ✅

**Changelog:**
- v1.2 (Oct 2025): Removed `additionalCharges` array, added description field, unified fixed charges at property level
- v1.1 (Sep 2025): Added comprehensive partial payment support with payment breakdown tracking
- v1.0: Initial database structure
