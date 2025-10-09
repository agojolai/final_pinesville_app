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
```

### Formula
```dart
daysOverdue = currentDate - dueDate
weeksOverdue = ceil(daysOverdue / 7)  // Always rounds up
lateFee = weeksOverdue × 150
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
```

### Example Scenario
```
October Bill (created Oct 15, due Oct 22):
 Status: Overdue (unpaid as of Nov 10)

November Bill (created Nov 15, due Nov 22):
 October bill still unpaid
 November bill reaches due date (Nov 22)
    
Nov 23: EVICTION NOTICE TRIGGERED 
 Reason: 2 consecutive months unpaid
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
//  UPDATED: Removed grace period logic
static LateFeeDetails calculate({
  required DateTime dueDate,
  required int gracePeriodDays, // Ignored, kept for compatibility
  required double lateFeePerWeek,
}) {
  final now = DateTime.now();
  
  // NO GRACE PERIOD - immediate late fee after due date
  if (now.isBefore(dueDate) || now.isAtSameMomentAs(dueDate)) {
    return LateFeeDetails(isLate: false, ...);
  }
  
  // Calculate weeks from due date (not grace period end)
  final daysOverdue = now.difference(dueDate).inDays;
  final weeksOverdue = (daysOverdue / 7).ceil();
  
  return LateFeeDetails(
    isLate: true,
    weeksOverdue: weeksOverdue,
    totalLateFee: weeksOverdue * lateFeePerWeek,
    gracePeriodEnd: dueDate, // No grace period
  );
}
```

#### 2. billing_repository.dart
```dart
//  UPDATED: Due date from creation date
Future<String> createBillFromInput({...}) async {
  final now = DateTime.now();
  
  // NEW: Due date = 7 days after bill creation
  final dueDate = now.add(const Duration(days: 7));
  
  final billingPeriod = BillingPeriod(
    month: month,
    year: year,
    startDate: DateTime(year, month, 1),
    endDate: DateTime(year, month + 1, 0),
    dueDate: dueDate, // 7 days from NOW
  );
  
  final lateFeeDetails = LateFeeDetails(
    isLate: false,
    weeksOverdue: 0,
    lateFeePerWeek: 150.00,
    totalLateFee: 0.0,
    gracePeriodEnd: dueDate, // Same as due date
  );
  
  // ... rest of bill creation
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

All 27 unit tests passing with updated logic:

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

All 27 tests passed!
```

---

##  Business Rules

### Core Rules
1.  Due date = Creation date + 7 days
2.  NO grace period
3.  Late fees = 150/week (rounds up)
4.  Late fees start day after due date
5.  Eviction = 2 consecutive months unpaid
6.  Payment priority: Rent first, late fees last

### Hard-Coded Values
- Late fee per week: 150
- Days until due: 7 days
- Eviction threshold: 2 consecutive months
- Week rounding: Always ceil (round up)

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

**Status:**  Core logic updated and tested  
**Next:** Update UI components to reflect new workflow

