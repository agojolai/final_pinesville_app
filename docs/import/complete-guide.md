# Historical Data Import Guide - Phase 2

**Date**: October 17, 2025  
**Purpose**: Import 6 months of historical billing, payment, and consumption data for existing tenants

---

## 📋 Overview

This guide covers importing **6 months of historical data** for tenants who are already in the system. You have:
- ✅ 6 months of water & electricity meter readings/consumption
- ✅ 6 months of paid bill details (amounts, dates, payments)

### What You'll Import:
1. **Bills** (monthly billing statements with utility readings) - **6 months**
2. **Payments** (payment records for those bills) - **6 months**
3. **Consumption Data** (automatically extracted from bills)

---

##  Prerequisites

### Required Information About Tenants

Before importing, you must have:

#### 1. Tenant Must Already Exist in System
`
- userId (Firebase UID from Users collection)
- userEmail
- userName (full name)
- unitId (which unit they occupy)
- propertyId (which property)
- Current tenant status (active)
`

**How to verify**: Check Firebase Users collection  ensure tenant exists with account.status = 'active'

#### 2. Property & Unit Setup Must Be Complete
`
- Property document exists in Properties collection
- Unit document exists in Properties/{propertyId}/Units/{unitId}
- Utility rates configured (electricity, water)
- Fixed charges configured (trash, wifi, parking)
`

---

##  Data Preparation

### Excel/CSV Template Structure

Create a spreadsheet with the following columns for each historical month:

#### **Sheet 1: Historical Bills Data**

| Column | Required | Format | Example | Notes |
|--------|----------|--------|---------|-------|
| userId |  | Text | USER_abc123 | Firebase user ID |
| userEmail |  | Email | juan.delacruz@email.com | Tenant email |
| userName |  | Text | Juan Dela Cruz | Full name |
| unitId |  | Text | UNIT_101 | Unit identifier |
| propertyId |  | Text | PROPERTY_001 | Property identifier |
| billingMonth |  | Number (1-12) | 9 | September |
| billingYear |  | Number | 2023 | Year of bill |
| startDate |  | Date | 2023-09-01 | Billing period start |
| endDate |  | Date | 2023-09-30 | Billing period end |
| dueDate |  | Date | 2023-10-07 | Payment due date |
| baseRent |  | Number | 25000 | Monthly rent amount |
| electricityPreviousReading |  | Number | 1250 | Previous meter reading (whole number) |
| electricityCurrentReading |  | Number | 1380 | Current meter reading (whole number) |
| electricityConsumption |  | Number | 130 | kWh consumed (auto-calculated) |
| electricityRatePerUnit |  | Number | 12.50 | Rate per kWh |
| electricityAmount |  | Number | 1625.00 | Total electricity cost |
| electricityMeterNumber |  | Text | ELEC-101-001 | Meter ID |
| electricityReadingDate |  | Date | 2023-09-30 | When meter was read |
| waterPreviousReading |  | Number | 850 | Previous water reading (whole number) |
| waterCurrentReading |  | Number | 925 | Current water reading (whole number) |
| waterConsumption |  | Number | 75 | m consumed (auto-calculated) |
| waterRatePerUnit |  | Number | 35.00 | Rate per m |
| waterAmount |  | Number | 2625.00 | Total water cost |
| waterMeterNumber |  | Text | WATER-101-001 | Meter ID |
| waterReadingDate |  | Date | 2023-09-30 | When meter was read |
| trashAmount |  | Number | 200 | Fixed trash fee |
| wifiAmount |  | Number | 500 | Fixed wifi fee |
| parkingAmount |  | Number | 1000 | Fixed parking fee |
| additionalChargesAmount |  | Number | 0 | Any extra charges |
| additionalChargesDescription |  | Text | Late penalty | Description of extra charges |
| subtotal |  | Number | 29750 | Sum before fees |
| discount |  | Number | 0 | Any discount given |
| discountReason |  | Text | | Why discount given |
| lateFee |  | Number | 0 | Late payment fee |
| lateFeeWeeks |  | Number | 0 | Weeks overdue |
| total |  | Number | 29750 | Final bill amount |
| isPaid |  | Boolean | TRUE/FALSE | Bill payment status |
| amountPaid |  | Number | 29750 | Amount paid (if any) |
| balance |  | Number | 0 | Remaining balance |

#### **Sheet 2: Historical Payments Data** (If bill is paid)

| Column | Required | Format | Example | Notes |
|--------|----------|--------|---------|-------|
| paymentId |  | Text | PAY_2023_09_USER123 | Unique payment ID |
| billId |  | Text | BILL_2023_09_USER123 | Associated bill ID |
| userId |  | Text | USER_abc123 | Tenant ID |
| paymentDate |  | DateTime | 2023-10-05T14:30:00 | When paid |
| amount |  | Number | 29750 | Payment amount |
| paymentMethod |  | Text | gcash | gcash, bdo, gotyme, cash |
| referenceNumber |  | Text | GC123456789 | Transaction ref |
| proofOfPaymentUrl |  | URL | https://... | Image URL if available |
| status |  | Text | verified | pending, verified, rejected |
| verifiedBy |  | Text | ADMIN_001 | Admin who verified |
| verifiedAt |  | DateTime | 2023-10-05T15:00:00 | Verification time |
| notes |  | Text | Paid on time | Any notes |

**Payment Allocations** (for partial payments):

| Column | Required | Format | Example | Notes |
|--------|----------|--------|---------|-------|
| allocRent |  | Number | 25000 | Amount for rent |
| allocElectricity |  | Number | 1625 | Amount for electricity |
| allocWater |  | Number | 2625 | Amount for water |
| allocTrash |  | Number | 200 | Amount for trash |
| allocWifi |  | Number | 500 | Amount for wifi |
| allocParking |  | Number | 1000 | Amount for parking |
| allocAdditional |  | Number | 0 | Amount for additional charges |

---

##  Example Data Rows

### Example 1: Fully Paid Bill (September 2023)

`csv
userId,userEmail,userName,unitId,propertyId,billingMonth,billingYear,startDate,endDate,dueDate,baseRent,electricityPreviousReading,electricityCurrentReading,electricityConsumption,electricityRatePerUnit,electricityAmount,electricityMeterNumber,electricityReadingDate,waterPreviousReading,waterCurrentReading,waterConsumption,waterRatePerUnit,waterAmount,waterMeterNumber,waterReadingDate,trashAmount,wifiAmount,parkingAmount,additionalChargesAmount,additionalChargesDescription,subtotal,discount,discountReason,lateFee,lateFeeWeeks,total,isPaid,amountPaid,balance
USER_abc123,juan.cruz@email.com,Juan Dela Cruz,UNIT_101,PROPERTY_001,9,2023,2023-09-01,2023-09-30,2023-10-07,25000,1250,1380,130,12.50,1625,ELEC-101-001,2023-09-30,850,925,75,35.00,2625,WATER-101-001,2023-09-30,200,500,1000,0,,29950,0,,0,0,29950,TRUE,29950,0
`

### Example 2: Unpaid Bill with Late Fee (August 2023)

`csv
userId,userEmail,userName,unitId,propertyId,billingMonth,billingYear,startDate,endDate,dueDate,baseRent,electricityPreviousReading,electricityCurrentReading,electricityConsumption,electricityRatePerUnit,electricityAmount,electricityMeterNumber,electricityReadingDate,waterPreviousReading,waterCurrentReading,waterConsumption,waterRatePerUnit,waterAmount,waterMeterNumber,waterReadingDate,trashAmount,wifiAmount,parkingAmount,additionalChargesAmount,additionalChargesDescription,subtotal,discount,discountReason,lateFee,lateFeeWeeks,total,isPaid,amountPaid,balance
USER_abc123,juan.cruz@email.com,Juan Dela Cruz,UNIT_101,PROPERTY_001,8,2023,2023-08-01,2023-08-31,2023-09-07,25000,1120,1250,130,12.50,1625,ELEC-101-001,2023-08-31,775,850,75,35.00,2625,WATER-101-001,2023-08-31,200,500,1000,300,Late payment from July,30250,0,,300,2,30550,FALSE,0,30550
`

### Example 3: Partial Payment (July 2023)

Payment record:
`csv
paymentId,billId,userId,paymentDate,amount,paymentMethod,referenceNumber,proofOfPaymentUrl,status,verifiedBy,verifiedAt,notes,allocRent,allocElectricity,allocWater,allocTrash,allocWifi,allocParking,allocAdditional
PAY_2023_07_USER123,BILL_2023_07_USER123,USER_abc123,2023-07-15T10:30:00,15000,gcash,GC987654321,,verified,ADMIN_001,2023-07-15T11:00:00,Partial payment,15000,0,0,0,0,0,0
`

---

##  Import Process Options

### Option 1: Manual Firebase Import (Small Dataset)

**Best for**: < 50 bills

1. Convert Excel to JSON using online tools
2. Use Firebase Console  Firestore  Import/Export
3. Import Bills collection
4. Import Payments collection
5. Verify data in Firebase console

### Option 2: Custom Import Script (Recommended)

**Best for**: 50+ bills, automated process

Create lib/src/features/data_import/ folder with:

#### Import Repository Structure:
`dart
// import_repository.dart
class DataImportRepository {
  Future<void> importBillsFromCSV(String csvPath) async {}
  Future<void> importPaymentsFromCSV(String csvPath) async {}
  Future<void> validateImportData(List<Map> data) async {}
  Future<void> updateUnitLastReadings(String unitId, Map readings) async {}
}
`

#### Key Functions Needed:
1. **CSV Parser** - Read Excel/CSV files
2. **Data Validator** - Check required fields, formats
3. **Bill Creator** - Create bill documents in Firebase
4. **Payment Creator** - Create payment documents in Firebase
5. **Unit Updater** - Update lastReadings in unit documents
6. **Progress Tracker** - Show import progress
7. **Error Handler** - Log and report failures

### Option 3: Firebase Admin SDK Script (Best for Bulk)

**Best for**: 100+ bills, one-time migration

Run Node.js script with Firebase Admin SDK:

`javascript
// import-historical-data.js
const admin = require('firebase-admin');
const csv = require('csv-parser');
const fs = require('fs');

async function importBills(csvPath) {
  const bills = [];
  
  fs.createReadStream(csvPath)
    .pipe(csv())
    .on('data', (row) => {
      const bill = transformRowToBill(row);
      bills.push(bill);
    })
    .on('end', async () => {
      // Batch write to Firestore
      const batch = admin.firestore().batch();
      bills.forEach(bill => {
        const ref = admin.firestore().collection('Bills').doc(bill.billId);
        batch.set(ref, bill);
      });
      await batch.commit();
    });
}
`

---

##  Critical Considerations

### 1. **Meter Reading Continuity**

**IMPORTANT**: Ensure meter readings are continuous month-to-month:
`
July 2023:     Previous: 1000  Current: 1120 (120 kWh)
August 2023:   Previous: 1120  Current: 1250 (130 kWh)   Must match July's current
September 2023: Previous: 1250  Current: 1380 (130 kWh)   Must match August's current
`

### 2. **Bill ID Format**

Use consistent format:
`
BILL_{year}_{month}_{userId}
Example: BILL_2023_09_USER_abc123
`

### 3. **Due Date Calculation**

Current system: **Due date = Bill creation + 7 days**

For historical data:
- If importing old paid bills  Use actual historical due dates
- If recreating missing bills  Use 7-day rule from start date

### 4. **Late Fee Calculation**

**CRITICAL**: If bill is overdue:
- 150 per week after due date
- Use lateFeeWeeks to track weeks overdue
- **Late fees freeze when next bill is created**

### 5. **Payment Allocations**

For **partial payments**, allocations must:
- Sum to total payment amount
- Match bill's paymentBreakdown structure
- Have 7 categories: rent, electricity, water, trash, wifi, parking, additionalCharges

### 6. **Unit Last Readings Update**

**MUST DO**: After importing bills, update unit's lastReadings:
`
Properties/{propertyId}/Units/{unitId}/lastReadings = {
  electricity: {mostRecentCurrentReading},
  water: {mostRecentCurrentReading}
}
`

This ensures next bill creation uses correct previous readings.

---

##  Import Checklist

### Pre-Import:
- [ ] All tenants exist in Firebase Users collection
- [ ] All properties and units are set up
- [ ] Utility rates configured for each property
- [ ] Fixed charges configured (trash, wifi, parking)
- [ ] Historical data collected and organized in Excel
- [ ] Meter readings are continuous (no gaps)
- [ ] Bill IDs follow naming convention
- [ ] Payment allocations add up correctly

### During Import:
- [ ] Start with oldest bills first (chronological order)
- [ ] Import one property/unit at a time
- [ ] Validate each bill before saving
- [ ] Check for duplicate bill IDs
- [ ] Verify payment allocations sum correctly
- [ ] Log any errors or skipped records

### Post-Import:
- [ ] Update unit lastReadings with most recent values
- [ ] Verify consumption data appears in charts
- [ ] Test tenant can see their historical bills
- [ ] Test admin can view unit consumption history
- [ ] Verify payment history displays correctly
- [ ] Check transaction list shows all payments
- [ ] Run test: Create new bill (should use lastReadings)

---

##  Testing After Import

### 1. Tenant View Tests:
`
 Home screen shows consumption charts with real data
 Billing screen lists all historical bills
 Payment history shows all past payments
 Transaction section shows historical transactions
 Consumption charts display correct months
`

### 2. Admin View Tests:
`
 Tenant management shows accurate billing history
 Unit consumption analytics includes historical data
 Can create new bill using updated lastReadings
 Payment verification shows correct allocations
`

### 3. Data Integrity Tests:
`
 Meter readings are continuous (no gaps)
 Payment allocations match bill amounts
 Late fees calculated correctly
 Consumption values match (current - previous)
 All dates are chronological
`

---

##  Sample Import Timeline

**For 6 months of data per tenant**:

### Small Property (10 units):
- Data preparation: 2-3 hours
- CSV/Excel creation: 1-2 hours
- Import execution: 15-30 minutes
- Validation: 30 minutes - 1 hour
**Total: 4-7 hours (half day)**

### Medium Property (50 units):
- Data preparation: 4-6 hours
- CSV/Excel creation: 3-4 hours
- Import execution: 1-2 hours
- Validation: 2-3 hours
**Total: 1-2 working days**

### Large Property (100+ units):
- Data preparation: 1-2 days
- CSV/Excel creation: 1 day
- Import execution: 2-4 hours
- Validation: 4-6 hours
**Total: 2-4 working days**

---

##  Recommended Approach

### Phase 1: Pilot Import (2-3 days)
1. Select 2-3 test tenants
2. Prepare their 6 months of data
3. Import using Firebase Console or custom script
4. Validate thoroughly
5. Fix any issues

### Phase 2: Batch Import (1 week)
1. Prepare all tenant data (6 months each)
2. Create import script (if needed)
3. Import property by property
4. Validate after each property
5. Document any edge cases

### Phase 3: Validation & Cleanup (2-3 days)
1. Test all tenant accounts
2. Verify consumption analytics show 6 months
3. Update unit lastReadings
4. Run full test suite
5. Get user acceptance

---

##  Need Custom Import Tool?

If you want me to create a custom import tool, I can build:

1. **CSV Import Screen** (Admin only)
   - File upload interface
   - Progress indicator
   - Error reporting
   - Success summary

2. **Import Repository**
   - CSV parser
   - Data validator
   - Batch bill creator
   - Payment creator
   - Unit updater

3. **Import Validator**
   - Check required fields
   - Validate formats
   - Check continuity
   - Detect duplicates

Let me know if you want me to implement the import tool! 

---

**Last Updated**: October 15, 2025  
**Status**: Guide Complete - Ready for Implementation
