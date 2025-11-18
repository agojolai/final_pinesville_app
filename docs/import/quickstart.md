# Quick Start: Import Your 6 Months of Historical Data

##  What You Have:
-  6 months of water & electricity consumption data
-  6 months of paid bill details

##  Import Process (3 Steps)

### Step 1: Organize Your Data (1-2 hours per property)

Use **DATA_COLLECTION_TEMPLATE.md** to organize your existing data:

For each tenant, collect:
- **Tenant Info**: userId, email, name, unitId, propertyId
- **6 Months of Meter Readings**: 
  - Electricity: previous, current, consumption
  - Water: previous, current, consumption
- **6 Months of Bill Details**: rent, utilities, charges, totals
- **6 Months of Payment Records**: dates, amounts, methods

**Key Rule**: Each month's previous reading = previous month's current reading

---

### Step 2: Fill CSV Templates (2-4 hours per property)

Two files to create:

#### A) Bills CSV (ills_6months_template.csv)
- 6 rows per tenant (one for each month)
- 39 columns total
- Start with oldest month (e.g., April 2024)
- End with most recent month (e.g., September 2024)

#### B) Payments CSV (payments_6months_template.csv)
- 6 rows per tenant (one payment per bill)
- 19 columns total
- Match billId to payment
- Include allocations (rent, electricity, water, trash, wifi, parking, additional)

**Example**: See the template files for properly formatted sample data

---

### Step 3: Import to Firebase (30 mins - 2 hours)

#### Option A: Small Property (< 20 units) - Firebase Console
1. Convert CSV to JSON (use online tool: https://csvjson.com/csv2json)
2. Open Firebase Console  Firestore Database
3. Import Bills collection from JSON
4. Import Payments collection from JSON
5. Manually update unit lastReadings for each unit

#### Option B: Medium/Large Property (20+ units) - Custom Script
Need help? I can create an automated import tool with:
- CSV parser
- Data validator
- Batch Firebase import
- Auto-update unit lastReadings
- Progress tracking
- Error reporting

---

##  Post-Import Checklist

After importing, verify:

### 1. Data Validation
- [ ] All 6 bills appear for each tenant in Firebase Bills collection
- [ ] All 6 payments appear in Firebase Payments collection
- [ ] Meter readings are continuous (no gaps between months)
- [ ] Payment allocations match bill totals

### 2. Unit Updates
- [ ] Update each unit's lastReadings with Month 6 (most recent) current readings
  `
  Properties/{propertyId}/Units/{unitId}/lastReadings = {
    electricity: {month6CurrentReading},
    water: {month6CurrentReading}
  }
  `

### 3. App Testing (Tenant View)
- [ ] Login as tenant
- [ ] Home screen shows consumption charts with 6 months of data
- [ ] Billing screen lists all 6 historical bills
- [ ] Payment history shows all 6 payments
- [ ] Consumption chart displays correct values

### 4. App Testing (Admin View)
- [ ] Login as admin
- [ ] Unit analytics show 6 months of consumption
- [ ] Can create NEW bill (should use updated lastReadings)
- [ ] New bill's previous readings = Month 6 current readings

---

##  Expected Results

After import, each tenant will have:
- **6 historical bills** (April - September 2024)
- **6 payment records** (all verified)
- **6 months of consumption data** visible in charts
- **Updated unit lastReadings** for next bill creation

---

##  Need Help?

### Common Issues:

**Issue**: Meter readings don't match month-to-month
**Fix**: Each month's electricityPreviousReading must equal previous month's electricityCurrentReading

**Issue**: Payment allocations don't sum correctly
**Fix**: Ensure llocRent + allocElectricity + allocWater + allocTrash + allocWifi + allocParking + allocAdditional = total payment amount

**Issue**: Consumption charts don't show data after import
**Fix**: Verify bills have utilities.electricity.consumption and utilities.water.consumption fields

**Issue**: Can't create new bill after import
**Fix**: Ensure unit's lastReadings were updated with Month 6 current readings

---

##  Want Automated Import Tool?

If you have many tenants (50+), I can build a custom import tool:

**Features**:
-  CSV file picker
-  Data validation with error reporting
-  Preview before import
-  Batch import with progress bar
-  Auto-update unit lastReadings
-  Success summary with statistics

**Time to build**: 4-6 hours
**Time to use**: 15-30 minutes for any property size

Let me know if you want this! 

---

**Files Created**:
-  HISTORICAL_DATA_IMPORT_GUIDE.md (comprehensive guide)
-  DATA_COLLECTION_TEMPLATE.md (data organization template)
-  bills_6months_template.csv (sample CSV with 6 months)
-  payments_6months_template.csv (sample CSV with 6 months)
-  IMPORT_QUICKSTART.md (this file)

---

**Last Updated**: October 17, 2025
