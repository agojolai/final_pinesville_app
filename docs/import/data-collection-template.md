# Historical Data Import - Simplified Template

## What You Have:
-  6 months of water & electricity consumption data
-  6 months of paid bill details

## Simplified Data Collection Template

### For Each Tenant - Past 6 Months

Use this template to organize your existing data:

---

### Tenant Information (Fill once per tenant):
- **userId**: _________________ (Get from Firebase Users collection)
- **userEmail**: _________________
- **userName**: _________________
- **unitId**: _________________
- **propertyId**: _________________

---

### Month 1 (Oldest) - Example: April 2024

**Billing Period:**
- Start Date: 2024-04-01
- End Date: 2024-04-30
- Due Date: 2024-05-07

**Rent:**
- Base Rent: _________

**Electricity:**
- Previous Reading: _________ kWh
- Current Reading: _________ kWh
- Consumption: _________ kWh (auto-calculated: Current - Previous)
- Rate per kWh: _________
- Total Amount: _________
- Meter Number: _________________
- Reading Date: 2024-04-30

**Water:**
- Previous Reading: _________ m
- Current Reading: _________ m
- Consumption: _________ m (auto-calculated: Current - Previous)
- Rate per m: _________
- Total Amount: _________
- Meter Number: _________________
- Reading Date: 2024-04-30

**Fixed Charges:**
- Trash: _________
- Wifi: _________
- Parking: _________

**Additional Charges (if any):**
- Amount: _________
- Description: _________________

**Totals:**
- Subtotal: _________ (sum of all above)
- Discount: _________ (if any)
- Late Fee: _________ (if any, 150/week)
- **TOTAL BILL: _________**

**Payment Details:**
- Payment Date: 2024-__-__ __:__:__
- Amount Paid: _________
- Payment Method: [gcash / bdo / gotyme / cash]
- Reference Number: _________________
- Status: verified

---

### Month 2 - Example: May 2024

**Billing Period:**
- Start Date: 2024-05-01
- End Date: 2024-05-31
- Due Date: 2024-06-07

** IMPORTANT:** Electricity Previous Reading = April's Current Reading
** IMPORTANT:** Water Previous Reading = April's Current Reading

**Rent:**
- Base Rent: _________

**Electricity:**
- Previous Reading: _________ kWh  MUST match Month 1 current
- Current Reading: _________ kWh
- Consumption: _________ kWh
- Rate per kWh: _________
- Total Amount: _________
- Meter Number: _________________ (same as Month 1)
- Reading Date: 2024-05-31

**Water:**
- Previous Reading: _________ m  MUST match Month 1 current
- Current Reading: _________ m
- Consumption: _________ m
- Rate per m: _________
- Total Amount: _________
- Meter Number: _________________ (same as Month 1)
- Reading Date: 2024-05-31

**Fixed Charges:**
- Trash: _________
- Wifi: _________
- Parking: _________

**Additional Charges (if any):**
- Amount: _________
- Description: _________________

**Totals:**
- Subtotal: _________
- Discount: _________
- Late Fee: _________
- **TOTAL BILL: _________**

**Payment Details:**
- Payment Date: 2024-__-__ __:__:__
- Amount Paid: _________
- Payment Method: [gcash / bdo / gotyme / cash]
- Reference Number: _________________
- Status: verified

---

### Month 3 - Example: June 2024
[Repeat same structure as Month 2]

### Month 4 - Example: July 2024
[Repeat same structure]

### Month 5 - Example: August 2024
[Repeat same structure]

### Month 6 (Most Recent) - Example: September 2024
[Repeat same structure]

** CRITICAL:** Month 6 current readings become the unit's lastReadings for next bill!

---

## Quick Validation Checklist:

Before importing, verify:
- [ ] Each month's previous reading = previous month's current reading
- [ ] All consumption values = current - previous reading
- [ ] All payment amounts = bill totals (all bills paid)
- [ ] All dates are chronological
- [ ] All meter numbers are consistent across months
- [ ] Month 6 (latest) readings will be unit's lastReadings

---

## Data Entry Tips:

1. **Start with oldest month** (Month 1 = 6 months ago)
2. **Work chronologically** forward to most recent (Month 6 = last month)
3. **Double-check meter continuity** after each month
4. **Use consistent date format**: YYYY-MM-DD for dates, YYYY-MM-DDTHH:MM:SS for datetime
5. **All amounts in Pesos** (no currency symbols in CSV)
6. **Whole numbers only** for meter readings and consumption

---

## Example: Completed 6-Month Data

**Tenant:** Juan Dela Cruz (UNIT_101)

| Month | Elec Prev | Elec Curr | Elec Cons | Water Prev | Water Curr | Water Cons | Total Bill | Paid |
|-------|-----------|-----------|-----------|------------|------------|------------|------------|------|
| Apr   | 1000      | 1130      | 130       | 700        | 775        | 75         | 29,950    |    |
| May   | 1130      | 1250      | 120       | 775        | 850        | 75         | 29,750    |    |
| Jun   | 1250      | 1370      | 120       | 850        | 920        | 70         | 29,650    |    |
| Jul   | 1370      | 1510      | 140       | 920        | 1000       | 80         | 30,250    |    |
| Aug   | 1510      | 1640      | 130       | 1000       | 1070       | 70         | 29,850    |    |
| Sep   | 1640      | 1750      | 110       | 1070       | 1135       | 65         | 29,175    |    |

**Unit lastReadings after import:** Electricity: 1750, Water: 1135

---

**Need Help?** This template helps organize your existing data before converting to CSV for import.

