# Late Payment System - Updated Workflow
**Date:** October 8, 2025  
**Status:**  UPDATED - No Grace Period System

---

##  Key Changes Summary

### OLD SYSTEM 
- Due date: 7 days after **month end**
- Grace period: 7 days after due date
- Late fees: Applied after grace period
- Total delay: 14 days before penalties

### NEW SYSTEM 
- Due date: 7 days after **bill creation**
- Grace period: **REMOVED** (no grace period)
- Late fees: Applied **immediately** after due date
- Eviction: 2 consecutive months unpaid

---

##  Timeline Example

**Scenario:** Admin creates October bill on October 15

```
Oct 15 (Tuesday)  Bill Created

 Rent Period: October-November (future month)
 Utilities: September consumption (past month)
 Due Date: Oct 22 (7 days after creation)

Oct 15-22  Payment Period (7 days)
Oct 23+  LATE FEES START IMMEDIATELY
```

---

##  Late Fee Calculation

### ⚠️ CRITICAL: Late Fee Freezing When Next Bill Created

**Late fees STOP incrementing when the next billing period starts.**

```
Example Timeline:

Oct 15: Bill 1 created (covers Oct-Nov, due Oct 22)
Oct 23-Nov 14: Late fees increment weekly
Nov 15: Bill 2 created (covers Nov-Dec, due Nov 22)
        → Bill 1 late fee FREEZES at current amount
Nov 16+: Bill 1 late fee stays frozen (no more weekly increments)
Nov 23: If Bill 2 also unpaid → Eviction notice triggered
```

### Why Late Fees Freeze

Once the next billing period starts, the tenant faces a **new bill with a new due date**. To avoid compounding penalties, the previous bill's late fees stop growing and become a fixed amount.

This ensures:
1. ✅ Tenant isn't penalized twice for the same time period
2. ✅ Late fees are capped at reasonable amounts
3. ✅ Eviction logic focuses on consecutive unpaid months, not accumulated fees

### Immediate Application
```
Due Date: Oct 22, 2025 (bill created Oct 15)

Oct 23 (1 day late):
 Days overdue: 1
 Weeks overdue: ceil(1/7) = 1 week
 Late Fee: 150

Oct 29 (7 days late):
 Days overdue: 7
 Weeks overdue: ceil(7/7) = 1 week
 Late Fee: 150

Oct 30 (8 days late):
 Days overdue: 8
 Weeks overdue: ceil(8/7) = 2 weeks
 Late Fee: 300

Nov 6 (15 days late):
 Days overdue: 15
 Weeks overdue: ceil(15/7) = 3 weeks
 Late Fee: 450

Nov 7 (16 days late):
 Days overdue: 16
 Weeks overdue: ceil(16/7) = 3 weeks
 Late Fee: 450

Nov 14 (23 days late):
 Days overdue: 23
 Weeks overdue: ceil(23/7) = 4 weeks
 Late Fee: 600

Nov 15: NEXT BILL CREATED → Late fee FREEZES at 600
Nov 20: Late fee stays 600 (frozen, no increment)
Nov 22: Bill 2 due date
Nov 23: Bill 2 overdue + Bill 1 still unpaid = EVICTION
```

### Real-World Example
```
📅 October 15, 2025
Admin creates Bill 1 (Oct-Nov period)
├─ Due: Oct 22
├─ Amount: 29,753.13
└─ Status: Pending

📅 October 23-November 14
Late fees accumulate weekly:
├─ Week 1 (Oct 23-29): +150 = 150
├─ Week 2 (Oct 30-Nov 5): +150 = 300
├─ Week 3 (Nov 6-12): +150 = 450
└─ Week 4 (Nov 13-14): +150 = 600

📅 November 15, 2025
Admin creates Bill 2 (Nov-Dec period)
├─ Due: Nov 22
├─ Amount: 30,200.00
└─ ⚠️ Bill 1 late fee FREEZES at 600

📅 November 16-22
Bill 1 status:
├─ Original: 29,753.13
├─ Late Fee: 600.00 (FROZEN)
├─ Total: 30,353.13
└─ Status: Overdue + Frozen Late Fee

📅 November 23, 2025
If Bill 2 also unpaid:
🚨 EVICTION NOTICE TRIGGERED
├─ Reason: 2 consecutive months unpaid
├─ Bill 1 Total: 30,353.13 (frozen)
├─ Bill 2 Total: 30,200.00 (now overdue)
└─ Combined: 60,553.13
```

### Formula
```dart
// Without next bill (late fees continue growing)
daysOverdue = currentDate - dueDate
weeksOverdue = ceil(daysOverdue / 7)  // Always rounds up
lateFee = weeksOverdue × 150

// With next bill (late fees freeze)
daysOverdue = nextBillCreatedDate - dueDate  // Capped at next bill
weeksOverdue = ceil(daysOverdue / 7)
lateFee = weeksOverdue × 150  // Frozen amount
```

---

##  Billing Components

### What the Bill Covers
```
October 15 Bill Contains:

 RENT: October-November (future)
  Base Rent: 25,000          
  Description: Monthly rent    

 UTILITIES: September (past)    
  Electricity: Past month used
  Water: Past month used      
  Meter readings recorded      

 FIXED CHARGES:                  
  Trash: 200                  
  WiFi: 500                   
  Parking: 1,000              


Total: 29,753.13
Due: Oct 22 (7 days from creation)
```

---

##  Eviction Notice System

### Trigger Conditions
```
Eviction Notice Issued When:
1. TWO consecutive months unpaid
2. Both bills are past due date
3. Both bills have daysOverdue > 0
4. Previous bill's late fee is FROZEN (next bill exists)
```

### Complete Workflow Timeline
```
Month 1 (October):
├─ Oct 15: Bill 1 created (due Oct 22)
├─ Oct 23: Bill 1 overdue, late fees start
├─ Oct 30: Late fee = 300 (2 weeks)
├─ Nov 6: Late fee = 450 (3 weeks)
└─ Nov 14: Late fee = 600 (4 weeks)

Month 2 (November):
├─ Nov 15: Bill 2 created (due Nov 22)
│           → Bill 1 late fee FREEZES at 600
├─ Nov 16-21: Bill 2 still within due date
│             Bill 1 late fee stays 600 (frozen)
├─ Nov 22: Last day to pay Bill 2
└─ Nov 23: Bill 2 becomes overdue
            
🚨 EVICTION TRIGGERED (Nov 23):
├─ Condition 1: Two consecutive months (Oct + Nov) ✓
├─ Condition 2: Both bills past due date ✓
├─ Condition 3: Bill 1 overdue 32 days, Bill 2 overdue 1 day ✓
└─ Condition 4: Bill 1 frozen at 600, Bill 2 starts at 0 ✓

Result: Eviction notice issued to tenant
```

### Example Scenario
```
October Bill (created Oct 15, due Oct 22):
├─ Status: Overdue (unpaid as of Nov 23)
├─ Late Fee: 600 (FROZEN at Nov 15)
└─ Total Due: 30,353.13

November Bill (created Nov 15, due Nov 22):
├─ Status: Overdue (as of Nov 23)
├─ Late Fee: 0 (just became overdue)
└─ Total Due: 30,200.00
    
Nov 23: EVICTION NOTICE TRIGGERED 
├─ Reason: 2 consecutive months unpaid
├─ Combined Outstanding: 60,553.13
└─ Days to resolve: Varies by property policy
```

### Code Logic
```dart
bool shouldEvict(List<BillModel> allBills) {
  // Must have at least 2 unpaid bills
  final unpaidBills = allBills.where((b) => !b.isPaid && b.isOverdue);
  if (unpaidBills.length < 2) return false;
  
  // Check if consecutive months
  final current = unpaidBills[0];  // Most recent
  final previous = unpaidBills[1]; // Previous month
  
  // Verify consecutive (e.g., OctNov or DecJan)
  final isConsecutive = 
    (current.month == previous.month + 1 && current.year == previous.year) ||
    (current.month == 1 && previous.month == 12 && current.year == previous.year + 1);
  
  return isConsecutive && current.daysOverdue > 0 && previous.daysOverdue > 0;
}
```

---

##  Payment Process

### Payment Allocation Priority
```
When tenant pays, allocation order:
1. Rent (highest priority)
2. Electricity
3. Water
4. Trash
5. WiFi
6. Parking
7. Additional Charges
8. Late Fees (LAST)
```

### Example: Partial Payment with Late Fees
```
Original Bill:
 Rent: 25,000
 Electricity: 1,628
 Water: 2,625
 Fixed: 1,700
 Late Fee: 300 (2 weeks overdue)
Total: 31,253

Tenant Pays: 26,000

Allocation:
 Rent: 25,000 (PAID IN FULL)
 Electricity: 1,000 (partial, 628 remaining)
 Water: 0 (unpaid)
 Fixed: 0 (unpaid)
 Late Fee: 300 (unpaid)

Remaining Balance: 5,253
Status: Partially Paid + Still Overdue
Late Fee: Continues to grow weekly
```

---

##  Status System

### Bill Status Values
```
pending       Not paid, before due date
partiallyPaid Some payment made
paid          Fully paid (balance = 0)
overdue       Past due date, unpaid/partially paid
cancelled     Admin cancelled
```

### Status Determination
```dart
// Calculated dynamically
bool get isOverdue {
  if (isPaid) return false;
  return DateTime.now().isAfter(billingPeriod.dueDate) && balance > 0;
}

// NO GRACE PERIOD CHECK
// Late immediately after due date
```

---

##  User Interface Updates

### Admin View - Bill Creation
```

 Create Bill                    

 Property: Pinesville Tower     
 Unit: 201                      
 Tenant: John Doe               
                                
  Creation Date: Oct 15, 2025
  Due Date: Oct 22, 2025     
    (7 days from today)         
                                
 Rent Period: Oct-Nov 2025      
 Utilities: Sep 2025 consumed   
                                
  NO GRACE PERIOD             
 Late fees apply Oct 23+        

```

### Tenant View - Before Due Date
```
 October 2025 Bill

 Created: Oct 15, 2025          
 Due: Oct 22, 2025              
 Days Remaining: 5 days         
                                
 Amount: 29,753.13             
 Status: Pending                
                                
  Pay by Oct 22 to avoid fees
 [Pay Now]                      

```

### Tenant View - After Due Date
```
 October 2025 Bill - OVERDUE

 Created: Oct 15, 2025          
 Due: Oct 22, 2025 (5 days ago)
 Days Overdue: 5 days           
                                
 Original: 29,753.13           
 Late Fee: 150.00 (1 week)    
 Total Due: 29,903.13          
                                
  LATE FEE ACTIVE             
 Increases by 150 every week   
 [Pay Now]                      

```

### Tenant View - Eviction Warning
```
 EVICTION NOTICE

 TWO CONSECUTIVE MONTHS UNPAID  
                                
 October Bill: 29,903 (overdue)
 November Bill: 30,500 (overdue)
                                
 Total Outstanding: 60,403     
                                
  IMMEDIATE ACTION REQUIRED   
 Contact admin within 3 days    
 [Contact Admin] [Pay Now]      

```

---

##  Database Structure

### Bill Document
```json
{
  "billId": "BILL_2025_10_USER123",
  "userId": "USER123",
  "createdAt": "2025-10-15T10:00:00Z",
  "billingPeriod": {
    "month": 10,
    "year": 2025,
    "startDate": "2025-10-01T00:00:00Z",
    "endDate": "2025-10-31T23:59:59Z",
    "dueDate": "2025-10-22T23:59:59Z"  // 7 days after creation
  },
  "lateFeeDetails": {
    "isLate": false,
    "weeksOverdue": 0,
    "lateFeePerWeek": 150.00,
    "totalLateFee": 0.00,
    "gracePeriodEnd": "2025-10-22T23:59:59Z",  // Same as due date (no grace)
    "lateFeeAppliedAt": null
  },
  "total": 29753.13,
  "balance": 29753.13,
  "isPaid": false,
  "isOverdue": false  // Becomes true on Oct 23
}
```

---

##  Technical Implementation

### Files Changed

#### 1. billing_models.dart
```dart
//  UPDATED: Removed grace period logic + Added late fee freezing
static LateFeeDetails calculate({
  required DateTime dueDate,
  required int gracePeriodDays, // Ignored, kept for compatibility
  required double lateFeePerWeek,
  DateTime? nextBillCreatedAt, // NEW: Freeze late fees when next bill created
}) {
  final now = DateTime.now();
  
  // Determine end date for calculation
  // If next bill exists, freeze at that creation date
  final calculationEndDate = nextBillCreatedAt ?? now;
  
  // NO GRACE PERIOD - immediate late fee after due date
  if (calculationEndDate.isBefore(dueDate) || calculationEndDate.isAtSameMomentAs(dueDate)) {
    return LateFeeDetails(isLate: false, ...);
  }
  
  // Calculate weeks from due date to freeze date (or now)
  final daysOverdue = calculationEndDate.difference(dueDate).inDays;
  final weeksOverdue = (daysOverdue / 7).ceil();
  
  return LateFeeDetails(
    isLate: true,
    weeksOverdue: weeksOverdue,
    totalLateFee: weeksOverdue * lateFeePerWeek,
    gracePeriodEnd: dueDate, // No grace period
    lateFeeAppliedAt: calculationEndDate, // Frozen at this date
  );
}
```

#### 2. billing_repository.dart
```dart
//  UPDATED: Due date from creation date + Late fee freezing logic
Future<void> updateLateFees() async {
  final overdueBills = await firestore
      .collection('Bills')
      .where('isPaid', isEqualTo: false)
      .where('isOverdue', isEqualTo: true)
      .get();

  for (final doc in overdueBills.docs) {
    final bill = BillModel.fromSnapshot(doc);

    // NEW: Check if next bill exists for this user
    DateTime? nextBillCreatedAt;
    final nextMonth = bill.billingPeriod.month + 1;
    final nextYear = nextMonth > 12 ? bill.billingPeriod.year + 1 : bill.billingPeriod.year;
    final adjustedNextMonth = nextMonth > 12 ? 1 : nextMonth;
    
    final nextBillQuery = await firestore
        .collection('Bills')
        .where('userId', isEqualTo: bill.userId)
        .where('propertyId', isEqualTo: bill.propertyId)
        .where('unitId', isEqualTo: bill.unitId)
        .where('billingPeriod.month', isEqualTo: adjustedNextMonth)
        .where('billingPeriod.year', isEqualTo: nextYear)
        .limit(1)
        .get();
    
    if (nextBillQuery.docs.isNotEmpty) {
      final nextBill = BillModel.fromSnapshot(nextBillQuery.docs.first);
      nextBillCreatedAt = nextBill.createdAt;
      // Late fees will freeze at this date
    }

    // Recalculate with freeze date (if next bill exists)
    final newLateFeeDetails = LateFeeDetails.calculate(
      dueDate: bill.billingPeriod.dueDate,
      gracePeriodDays: 0,
      lateFeePerWeek: 150.00,
      nextBillCreatedAt: nextBillCreatedAt, // Freeze here
    );

    // Update if changed
    if (newLateFeeDetails.totalLateFee != bill.lateFeeDetails.totalLateFee) {
      await doc.reference.update({
        'lateFeeDetails': newLateFeeDetails.toMap(),
        'summary.lateFee': newLateFeeDetails.totalLateFee,
        ...
      });
    }
  }
}
```

#### 3. bill_model.dart
```dart
//  UPDATED: Consecutive month check for eviction
bool shouldEvict(List<BillModel> allBills) {
  // Get 2 most recent unpaid bills
  final unpaidBills = allBills
    .where((b) => b.userId == userId && !b.isPaid)
    .toList()
    ..sort((a, b) => /* sort by date descending */);
  
  if (unpaidBills.length < 2) return false;
  
  final current = unpaidBills[0];
  final previous = unpaidBills[1];
  
  // Check if consecutive months
  final isConsecutive = 
    (current.month == previous.month + 1 && current.year == previous.year) ||
    (current.month == 1 && previous.month == 12 && current.year == previous.year + 1);
  
  return isConsecutive && 
         current.isOverdue && 
         previous.isOverdue &&
         current.daysOverdue > 0 && 
         previous.daysOverdue > 0;
}
```

---

##  Testing Results

All 31 unit tests passing with updated logic (including late fee freezing):

```bash
$ flutter test test/unit/billing_models_test.dart
 LateFeeDetails Tests
    should calculate late fee correctly when overdue (NO GRACE PERIOD)
    should not charge late fee before due date

 Late Fee Calculation Edge Cases (NO GRACE PERIOD)
    should not be late on the due date
    should be late one day after due date
    should calculate multiple weeks late correctly
    should round up partial weeks

 Late Fee Freezing When Next Bill Created (NEW)
    should freeze late fee when next bill is created
    should continue growing if no next bill exists
    should freeze at exactly the next bill creation date
    should not charge late fee if next bill created before due date

All 31 tests passed!
```

---

##  Business Rules

### Core Rules
1.  Due date = Creation date + 7 days
2.  NO grace period
3.  Late fees = 150/week (rounds up)
4.  Late fees start day after due date
5.  **Late fees FREEZE when next bill is created** 
6.  Eviction = 2 consecutive months unpaid (both past due)
7.  Payment priority: Rent first, late fees last

### Hard-Coded Values
- Late fee per week: 150
- Days until due: 7 days
- Eviction threshold: 2 consecutive months
- Week rounding: Always ceil (round up)
- **Late fee freeze: When next billing period starts**

### Late Fee Lifecycle
```
Phase 1: Active Growth
├─ Bill created and becomes overdue
├─ Late fees increment weekly
└─ Duration: Until next bill is created

Phase 2: Frozen
├─ Next bill is created
├─ Late fee stops incrementing
├─ Amount becomes fixed
└─ Duration: Until bill is paid or eviction

Phase 3: Resolution
├─ Option A: Tenant pays (bill closed)
├─ Option B: Eviction process begins
└─ Late fee remains part of total owed
```

---

##  What's Next

### Immediate Actions
1. Update admin UI to show new due date logic
2. Update tenant notifications
3. Implement eviction notice system
4. Add eviction status to bill model

### Future Enhancements
1. Automated eviction notice emails
2. Payment plan system for overdue bills
3. Late fee waiver workflow
4. Configurable late fee rates per property

---

##  Key Files Reference

```
lib/src/features/billing/
 domain/
    billing_models.dart           UPDATED (no grace period)
    bill_model.dart               UPDATED (eviction logic)
    payment_model.dart           
 data/
    billing_repository.dart       UPDATED (due date calc)
 presentation/
     view_billing_screen.dart      NEEDS UPDATE (UI)
     admin_create_bill_screen.dart NEEDS UPDATE (UI)

test/unit/
 billing_models_test.dart          UPDATED (all passing)
```

---

**Status:**  Core logic updated and tested - ALL 31 TESTS PASSING  
**Last Updated:** October 10, 2025  
**Changes:**
- ✅ Removed grace period (7 days → 0 days)
- ✅ Due date based on bill creation (not month end)
- ✅ Late fee freezing implemented (stops when next bill created)
- ✅ Eviction logic updated (consecutive months check)
- ✅ All tests updated and passing

**Next:** Update UI components to reflect new workflow and freezing logic

