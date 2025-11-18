# Billing System - Complete Implementation Guide

## Overview
This guide provides step-by-step instructions for implementing the complete billing workflow with partial payments, late fees, and payment validation.

---

## Workflow Summary

### Admin Workflow
1. Select property and unit
2. Input meter readings (electricity/water current)
3. Add additional charges (trash, wifi, parking, etc.)
4. System calculates consumption and amounts
5. Save and publish bill to tenant
6. Validate tenant payments with proof

### Tenant Workflow
1. View balance and bill breakdown
2. Choose payment type (full or partial)
3. Select what to pay (rent, utilities, or specific items)
4. Upload proof of payment
5. Wait for admin validation
6. View updated balance and transaction history
7. Download receipt when fully paid

### Late Fee System
- **Grace Period:** 7 days after due date
- **Late Fee:** 150 per week after grace period
- **Eviction Notice:** If 2 consecutive months unpaid

---

## Database Structure Updates

### 1. Property-Based Utility Rates

\\\json
// Path: Property/{propertyId}
{
  "propertyId": "PROP_001",
  "propertyName": "Pinesville Tower A",
  "address": "...",
  
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
    }
  }
}
\\\

### 2. Unit Details with Last Readings

\\\json
// Path: Property/{propertyId}/Units/{unitId}
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
  
  // Parking
  "parking": {
    "hasParking": true,
    "parkingFee": 1000.00,
    "parkingSlot": "P-101"
  },
  
  // Last Meter Readings (for next billing)
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
\\\

### 3. Enhanced Bill Model with Late Fees

\\\json
{
  "billId": "BILL_2025_09_USER123",
  
  // Late Fee Tracking
  "lateFeeDetails": {
    "isLate": false,
    "weeksOverdue": 0,
    "lateFeePerWeek": 150.00,
    "totalLateFee": 0.00,
    "lateFeeAppliedAt": null,
    "gracePeriodEnd": "2025-10-12T23:59:59Z"
  },
  
  // Payment Breakdown includes individual utility tracking
  "paymentBreakdown": {
    "rent": { "amount": 25000.00, "amountPaid": 0.00, "balance": 25000.00, "isPaid": false },
    "electricity": { "amount": 1628.13, "amountPaid": 0.00, "balance": 1628.13, "isPaid": false },
    "water": { "amount": 2625.00, "amountPaid": 0.00, "balance": 2625.00, "isPaid": false },
    "trash": { "amount": 200.00, "amountPaid": 0.00, "balance": 200.00, "isPaid": false },
    "wifi": { "amount": 500.00, "amountPaid": 0.00, "balance": 500.00, "isPaid": false },
    "parking": { "amount": 1000.00, "amountPaid": 0.00, "balance": 1000.00, "isPaid": false },
    "additionalCharges": { "amount": 300.00, "amountPaid": 0.00, "balance": 300.00, "isPaid": false }
  },
  
  // Receipt Generation
  "receiptGenerated": false,
  "receiptUrl": null,
  "receiptGeneratedAt": null
}
\\\

---

## Implementation Steps

## Phase 1: Database & Models Setup (Day 1-2)

### Step 1.1: Update Property Model

Create \lib/src/features/billing/domain/property_billing_model.dart\:

\\\dart
class PropertyUtilityRates {
  final double electricityRatePerKwh;
  final double waterRatePerCubicMeter;
  final DateTime effectiveDate;
  
  const PropertyUtilityRates({
    required this.electricityRatePerKwh,
    required this.waterRatePerCubicMeter,
    required this.effectiveDate,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'electricity': {
        'ratePerKwh': electricityRatePerKwh,
        'effectiveDate': effectiveDate.toIso8601String(),
        'currency': 'PHP',
      },
      'water': {
        'ratePerCubicMeter': waterRatePerCubicMeter,
        'effectiveDate': effectiveDate.toIso8601String(),
        'currency': 'PHP',
      },
    };
  }
  
  factory PropertyUtilityRates.fromMap(Map<String, dynamic> map) {
    final electricityData = map['electricity'] as Map<String, dynamic>;
    final waterData = map['water'] as Map<String, dynamic>;
    
    return PropertyUtilityRates(
      electricityRatePerKwh: (electricityData['ratePerKwh'] as num).toDouble(),
      waterRatePerCubicMeter: (waterData['ratePerCubicMeter'] as num).toDouble(),
      effectiveDate: DateTime.parse(electricityData['effectiveDate'] as String),
    );
  }
}

class FixedCharge {
  final String category;
  final double amount;
  final bool enabled;
  final String description;
  
  const FixedCharge({
    required this.category,
    required this.amount,
    required this.enabled,
    required this.description,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'enabled': enabled,
      'description': description,
    };
  }
  
  factory FixedCharge.fromMap(String category, Map<String, dynamic> map) {
    return FixedCharge(
      category: category,
      amount: (map['amount'] as num).toDouble(),
      enabled: map['enabled'] as bool,
      description: map['description'] as String,
    );
  }
}
\\\

### Step 1.2: Update Unit Model

Create \lib/src/features/billing/domain/unit_billing_model.dart\:

\\\dart
class LastMeterReading {
  final double reading;
  final DateTime readingDate;
  final String meterNumber;
  
  const LastMeterReading({
    required this.reading,
    required this.readingDate,
    required this.meterNumber,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'reading': reading,
      'readingDate': readingDate.toIso8601String(),
      'meterNumber': meterNumber,
    };
  }
  
  factory LastMeterReading.fromMap(Map<String, dynamic> map) {
    return LastMeterReading(
      reading: (map['reading'] as num).toDouble(),
      readingDate: DateTime.parse(map['readingDate'] as String),
      meterNumber: map['meterNumber'] as String,
    );
  }
}

class UnitBillingInfo {
  final String unitId;
  final String unitNumber;
  final String propertyId;
  final double monthlyRent;
  final String? tenantId;
  final bool hasParking;
  final double parkingFee;
  final LastMeterReading? lastElectricityReading;
  final LastMeterReading? lastWaterReading;
  
  const UnitBillingInfo({
    required this.unitId,
    required this.unitNumber,
    required this.propertyId,
    required this.monthlyRent,
    this.tenantId,
    this.hasParking = false,
    this.parkingFee = 0.0,
    this.lastElectricityReading,
    this.lastWaterReading,
  });
  
  // Add fromSnapshot, toMap, etc.
}
\\\

### Step 1.3: Update Bill Model with Late Fees

Update \lib/src/features/billing/domain/bill_model.dart\:

\\\dart
class LateFeeDetails {
  final bool isLate;
  final int weeksOverdue;
  final double lateFeePerWeek;
  final double totalLateFee;
  final DateTime? lateFeeAppliedAt;
  final DateTime gracePeriodEnd;
  
  const LateFeeDetails({
    required this.isLate,
    required this.weeksOverdue,
    required this.lateFeePerWeek,
    required this.totalLateFee,
    this.lateFeeAppliedAt,
    required this.gracePeriodEnd,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'isLate': isLate,
      'weeksOverdue': weeksOverdue,
      'lateFeePerWeek': lateFeePerWeek,
      'totalLateFee': totalLateFee,
      'lateFeeAppliedAt': lateFeeAppliedAt?.toIso8601String(),
      'gracePeriodEnd': gracePeriodEnd.toIso8601String(),
    };
  }
  
  factory LateFeeDetails.fromMap(Map<String, dynamic> map) {
    return LateFeeDetails(
      isLate: map['isLate'] as bool,
      weeksOverdue: map['weeksOverdue'] as int,
      lateFeePerWeek: (map['lateFeePerWeek'] as num).toDouble(),
      totalLateFee: (map['totalLateFee'] as num).toDouble(),
      lateFeeAppliedAt: map['lateFeeAppliedAt'] != null 
          ? DateTime.parse(map['lateFeeAppliedAt'] as String) 
          : null,
      gracePeriodEnd: DateTime.parse(map['gracePeriodEnd'] as String),
    );
  }
  
  /// Calculate late fee based on current date
  static LateFeeDetails calculate({
    required DateTime dueDate,
    required int gracePeriodDays,
    required double lateFeePerWeek,
  }) {
    final now = DateTime.now();
    final gracePeriodEnd = dueDate.add(Duration(days: gracePeriodDays));
    
    if (now.isBefore(gracePeriodEnd)) {
      // Still within grace period
      return LateFeeDetails(
        isLate: false,
        weeksOverdue: 0,
        lateFeePerWeek: lateFeePerWeek,
        totalLateFee: 0.0,
        gracePeriodEnd: gracePeriodEnd,
      );
    }
    
    // Calculate weeks overdue
    final daysOverdue = now.difference(gracePeriodEnd).inDays;
    final weeksOverdue = (daysOverdue / 7).ceil();
    final totalLateFee = weeksOverdue * lateFeePerWeek;
    
    return LateFeeDetails(
      isLate: true,
      weeksOverdue: weeksOverdue,
      lateFeePerWeek: lateFeePerWeek,
      totalLateFee: totalLateFee,
      lateFeeAppliedAt: now,
      gracePeriodEnd: gracePeriodEnd,
    );
  }
}

// Add to BillModel class:
class BillModel {
  // ... existing fields ...
  
  final LateFeeDetails lateFeeDetails;
  final PaymentBreakdownItem trashBreakdown;
  final PaymentBreakdownItem wifiBreakdown;
  final PaymentBreakdownItem parkingBreakdown;
  final bool receiptGenerated;
  final String? receiptUrl;
  final DateTime? receiptGeneratedAt;
  
  // ... rest of implementation ...
  
  /// Check if tenant should be evicted (2 consecutive months unpaid)
  bool shouldEvict(List<BillModel> allBills) {
    if (isPaid) return false;
    
    // Sort bills by date descending
    final sortedBills = allBills
        .where((b) => b.userId == userId && !b.isPaid)
        .toList()
      ..sort((a, b) => b.billingPeriod.year != a.billingPeriod.year
          ? b.billingPeriod.year.compareTo(a.billingPeriod.year)
          : b.billingPeriod.month.compareTo(a.billingPeriod.month));
    
    if (sortedBills.length < 2) return false;
    
    // Check if current and previous month are both unpaid and overdue
    final currentBill = sortedBills[0];
    final previousBill = sortedBills[1];
    
    return currentBill.isOverdue && 
           previousBill.isOverdue &&
           currentBill.daysOverdue > 0 &&
           previousBill.daysOverdue > 0;
  }
}
\\\

---

## Phase 2: Repository Methods (Day 3-4)

### Step 2.1: Add Property & Unit Queries

Update \lib/src/features/billing/data/billing_repository.dart\:

\\\dart
// ==================== PROPERTY & UNIT QUERIES ====================

/// Get all properties for billing
Stream<List<PropertyModel>> getProperties() {
  return firestore
      .collection('Properties')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => PropertyModel.fromSnapshot(doc))
          .toList());
}

/// Get units for a property
Stream<List<UnitBillingInfo>> getUnitsForProperty(String propertyId) {
  return firestore
      .collection('Properties')
      .doc(propertyId)
      .collection('units')
      .where('rental.status', isEqualTo: 'occupied')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => UnitBillingInfo.fromSnapshot(doc))
          .toList());
}

/// Get unit details
Future<UnitBillingInfo?> getUnitDetails(String propertyId, String unitId) async {
  final doc = await firestore
      .collection('Properties')
      .doc(propertyId)
      .collection('units')
      .doc(unitId)
      .get();
  
  if (!doc.exists) return null;
  return UnitBillingInfo.fromSnapshot(doc);
}

/// Get property utility rates
Future<PropertyUtilityRates?> getPropertyRates(String propertyId) async {
  final doc = await firestore.collection('Properties').doc(propertyId).get();
  if (!doc.exists) return null;
  
  final data = doc.data()!;
  if (!data.containsKey('utilityRates')) return null;
  
  return PropertyUtilityRates.fromMap(data['utilityRates'] as Map<String, dynamic>);
}

// ==================== BILL CREATION ====================

/// Create bill with all calculations
Future<String> createBillFromInput({
  required String propertyId,
  required String unitId,
  required double electricityCurrent,
  required double waterCurrent,
  required Map<String, double> additionalCharges, // {trash: 200, wifi: 500, etc}
  required int month,
  required int year,
}) async {
  // Get unit details
  final unit = await getUnitDetails(propertyId, unitId);
  if (unit == null) throw Exception('Unit not found');
  if (unit.tenantId == null) throw Exception('Unit has no tenant');
  
  // Get property rates
  final rates = await getPropertyRates(propertyId);
  if (rates == null) throw Exception('Property rates not configured');
  
  // Get tenant details
  final tenantDoc = await firestore.collection('Users').doc(unit.tenantId).get();
  if (!tenantDoc.exists) throw Exception('Tenant not found');
  final tenantData = tenantDoc.data()!;
  
  // Calculate electricity
  final electricityPrevious = unit.lastElectricityReading?.reading ?? 0.0;
  final electricityConsumption = electricityCurrent - electricityPrevious;
  final electricityAmount = electricityConsumption * rates.electricityRatePerKwh;
  
  // Calculate water
  final waterPrevious = unit.lastWaterReading?.reading ?? 0.0;
  final waterConsumption = waterCurrent - waterPrevious;
  final waterAmount = waterConsumption * rates.waterRatePerCubicMeter;
  
  // Calculate total
  final subtotal = unit.monthlyRent + 
                  electricityAmount + 
                  waterAmount + 
                  additionalCharges.values.fold(0.0, (sum, amount) => sum + amount);
  
  // Create billing period
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0); // Last day of month
  final dueDate = endDate.add(Duration(days: 7)); // 7 days after month end
  
  final billingPeriod = BillingPeriod(
    month: month,
    year: year,
    startDate: startDate,
    endDate: endDate,
    dueDate: dueDate,
  );
  
  // Create late fee details (initially not late)
  final lateFeeDetails = LateFeeDetails(
    isLate: false,
    weeksOverdue: 0,
    lateFeePerWeek: 150.00,
    totalLateFee: 0.0,
    gracePeriodEnd: dueDate.add(Duration(days: 7)),
  );
  
  // Create bill
  final billId = 'BILL_\_\_\';
  final now = DateTime.now();
  
  final bill = BillModel(
    billId: billId,
    userId: unit.tenantId!,
    userEmail: tenantData['profile']['email'] as String,
    userName: '\ \',
    unitId: unitId,
    propertyId: propertyId,
    billingPeriod: billingPeriod,
    baseRent: unit.monthlyRent,
    rentDescription: 'Monthly rent for Unit \',
    electricity: UtilityCharge(
      previousReading: electricityPrevious,
      currentReading: electricityCurrent,
      consumption: electricityConsumption,
      unit: 'kWh',
      ratePerUnit: rates.electricityRatePerKwh,
      amount: electricityAmount,
      meterNumber: unit.lastElectricityReading?.meterNumber ?? 'N/A',
      readingDate: now,
    ),
    water: UtilityCharge(
      previousReading: waterPrevious,
      currentReading: waterCurrent,
      consumption: waterConsumption,
      unit: 'cubic meters',
      ratePerUnit: rates.waterRatePerCubicMeter,
      amount: waterAmount,
      meterNumber: unit.lastWaterReading?.meterNumber ?? 'N/A',
      readingDate: now,
    ),
    additionalCharges: additionalCharges.entries
        .map((e) => AdditionalCharge(
              chargeId: 'CHARGE_\',
              description: e.key.capitalize(),
              amount: e.value,
              category: e.key,
            ))
        .toList(),
    subtotal: subtotal,
    discount: 0.0,
    discountReason: '',
    lateFee: 0.0,
    tax: 0.0,
    total: subtotal,
    amountPaid: 0.0,
    balance: subtotal,
    rentBreakdown: PaymentBreakdownItem(
      amount: unit.monthlyRent,
      amountPaid: 0.0,
      balance: unit.monthlyRent,
      isPaid: false,
    ),
    electricityBreakdown: PaymentBreakdownItem(
      amount: electricityAmount,
      amountPaid: 0.0,
      balance: electricityAmount,
      isPaid: false,
    ),
    waterBreakdown: PaymentBreakdownItem(
      amount: waterAmount,
      amountPaid: 0.0,
      balance: waterAmount,
      isPaid: false,
    ),
    trashBreakdown: PaymentBreakdownItem(
      amount: additionalCharges['trash'] ?? 0.0,
      amountPaid: 0.0,
      balance: additionalCharges['trash'] ?? 0.0,
      isPaid: false,
    ),
    wifiBreakdown: PaymentBreakdownItem(
      amount: additionalCharges['wifi'] ?? 0.0,
      amountPaid: 0.0,
      balance: additionalCharges['wifi'] ?? 0.0,
      isPaid: false,
    ),
    parkingBreakdown: PaymentBreakdownItem(
      amount: unit.hasParking ? unit.parkingFee : 0.0,
      amountPaid: 0.0,
      balance: unit.hasParking ? unit.parkingFee : 0.0,
      isPaid: false,
    ),
    additionalChargesBreakdown: PaymentBreakdownItem(
      amount: additionalCharges['other'] ?? 0.0,
      amountPaid: 0.0,
      balance: additionalCharges['other'] ?? 0.0,
      isPaid: false,
    ),
    lateFeeDetails: lateFeeDetails,
    status: BillStatus.pending,
    isPaid: false,
    isOverdue: false,
    isPartiallyPaid: false,
    createdAt: now,
    updatedAt: now,
    generatedBy: auth.currentUser!.uid,
    receiptGenerated: false,
  );
  
  await firestore.collection('Bills').doc(billId).set(bill.toMap());
  
  // Update unit's last readings
  await firestore
      .collection('Properties')
      .doc(propertyId)
      .collection('units')
      .doc(unitId)
      .update({
    'lastReadings.electricity': {
      'reading': electricityCurrent,
      'readingDate': now.toIso8601String(),
      'meterNumber': unit.lastElectricityReading?.meterNumber ?? 'ELEC-\',
    },
    'lastReadings.water': {
      'reading': waterCurrent,
      'readingDate': now.toIso8601String(),
      'meterNumber': unit.lastWaterReading?.meterNumber ?? 'WATER-\',
    },
    'updatedAt': now.toIso8601String(),
  });
  
  return billId;
}

// ==================== LATE FEE UPDATES ====================

/// Update late fees for overdue bills (run daily via Cloud Function)
Future<void> updateLateFees() async {
  final now = DateTime.now();
  
  final overdueBills = await firestore
      .collection('Bills')
      .where('isPaid', isEqualTo: false)
      .where('isOverdue', isEqualTo: true)
      .get();
  
  for (final doc in overdueBills.docs) {
    final bill = BillModel.fromSnapshot(doc);
    
    // Recalculate late fee
    final newLateFeeDetails = LateFeeDetails.calculate(
      dueDate: bill.billingPeriod.dueDate,
      gracePeriodDays: 7,
      lateFeePerWeek: 150.00,
    );
    
    if (newLateFeeDetails.totalLateFee != bill.lateFeeDetails.totalLateFee) {
      final newTotal = bill.subtotal + newLateFeeDetails.totalLateFee;
      final newBalance = newTotal - bill.amountPaid;
      
      await doc.reference.update({
        'lateFeeDetails': newLateFeeDetails.toMap(),
        'summary.lateFee': newLateFeeDetails.totalLateFee,
        'summary.total': newTotal,
        'summary.balance': newBalance,
        'updatedAt': now.toIso8601String(),
      });
    }
  }
}

// ==================== RECEIPT GENERATION ====================

/// Generate receipt jpeg for fully paid bill

}
\\\

---

## Phase 3: UI Implementation (Day 5-10)

### Step 3.1: Admin - Create Bill Screen

Create \lib/src/features/billing/presentation/screens/admin_create_bill_screen.dart\:

\\\dart
class AdminCreateBillScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AdminCreateBillScreen> createState() => _AdminCreateBillScreenState();
}

class _AdminCreateBillScreenState extends ConsumerState<AdminCreateBillScreen> {
  String? selectedPropertyId;
  String? selectedUnitId;
  
  final electricityCurrentController = TextEditingController();
  final waterCurrentController = TextEditingController();
  final rentController = TextEditingController();
  final trashController = TextEditingController(text: '200');
  final wifiController = TextEditingController(text: '500');
  final parkingController = TextEditingController(text: '1000');
  final additionalController = TextEditingController(text: '0');
  
  double electricityPrevious = 0.0;
  double waterPrevious = 0.0;
  double electricityRate = 12.50;
  double waterRate = 35.00;
  
  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Create New Bill')),
      body: propertiesAsync.when(
        data: (properties) => _buildForm(properties),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: \')),
      ),
    );
  }
  
  Widget _buildForm(List<PropertyModel> properties) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Dropdown
          DropdownButtonFormField<String>(
            value: selectedPropertyId,
            decoration: InputDecoration(labelText: 'Property'),
            items: properties
                .map((p) => DropdownMenuItem(
                      value: p.propertyId,
                      child: Text(p.propertyName),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedPropertyId = value;
                selectedUnitId = null;
              });
            },
          ),
          SizedBox(height: 16),
          
          // Unit Dropdown (only if property selected)
          if (selectedPropertyId != null) ...[
            Consumer(
              builder: (context, ref, child) {
                final unitsAsync = ref.watch(unitsForPropertyProvider(selectedPropertyId!));
                return unitsAsync.when(
                  data: (units) => DropdownButtonFormField<String>(
                    value: selectedUnitId,
                    decoration: InputDecoration(labelText: 'Unit Number'),
                    items: units
                        .map((u) => DropdownMenuItem(
                              value: u.unitId,
                              child: Text(u.unitNumber),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      setState(() => selectedUnitId = value);
                      if (value != null) await _loadUnitDetails(value);
                    },
                  ),
                  loading: () => LinearProgressIndicator(),
                  error: (e, st) => Text('Error loading units'),
                );
              },
            ),
            SizedBox(height: 24),
          ],
          
          // Show form only if unit selected
          if (selectedUnitId != null) ...[
            Text('Rent', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: rentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monthly Rent',
                prefixText: ' ',
              ),
            ),
            SizedBox(height: 24),
            
            // Electricity Section
            Text('Electricity', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Previous Reading',
                hintText: electricityPrevious.toStringAsFixed(2),
              ),
            ),
            TextField(
              controller: electricityCurrentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Current Reading'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Rate per kWh',
                hintText: ' \',
              ),
            ),
            if (electricityCurrentController.text.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Consumption: \ kWh',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Amount:  \',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
            SizedBox(height: 24),
            
            // Water Section
            Text('Water', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Previous Reading',
                hintText: waterPrevious.toStringAsFixed(2),
              ),
            ),
            TextField(
              controller: waterCurrentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Current Reading'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Rate per m',
                hintText: ' \',
              ),
            ),
            if (waterCurrentController.text.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Consumption: \ m',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Amount:  \',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
            SizedBox(height: 24),
            
            // Additional Charges
            Text('Additional Charges', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              controller: trashController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Trash Collection', prefixText: ' '),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: wifiController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'WiFi', prefixText: ' '),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: parkingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Parking', prefixText: ' '),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: additionalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Other Charges', prefixText: ' '),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 24),
            
            // Total
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL', style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      )),
                      Text(
                        ' \',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Create Bill Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createBill,
                child: Text('Create & Publish Bill'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Future<void> _loadUnitDetails(String unitId) async {
    final repository = ref.read(billingRepositoryProvider);
    final unit = await repository.getUnitDetails(selectedPropertyId!, unitId);
    if (unit != null) {
      setState(() {
        rentController.text = unit.monthlyRent.toStringAsFixed(2);
        electricityPrevious = unit.lastElectricityReading?.reading ?? 0.0;
        waterPrevious = unit.lastWaterReading?.reading ?? 0.0;
        parkingController.text = unit.hasParking ? unit.parkingFee.toStringAsFixed(2) : '0';
      });
      
      // Load property rates
      final rates = await repository.getPropertyRates(selectedPropertyId!);
      if (rates != null) {
        setState(() {
          electricityRate = rates.electricityRatePerKwh;
          waterRate = rates.waterRatePerCubicMeter;
        });
      }
    }
  }
  
  double _calculateElectricityConsumption() {
    final current = double.tryParse(electricityCurrentController.text) ?? 0.0;
    return current - electricityPrevious;
  }
  
  double _calculateElectricityAmount() {
    return _calculateElectricityConsumption() * electricityRate;
  }
  
  double _calculateWaterConsumption() {
    final current = double.tryParse(waterCurrentController.text) ?? 0.0;
    return current - waterPrevious;
  }
  
  double _calculateWaterAmount() {
    return _calculateWaterConsumption() * waterRate;
  }
  
  double _calculateTotal() {
    final rent = double.tryParse(rentController.text) ?? 0.0;
    final electricity = _calculateElectricityAmount();
    final water = _calculateWaterAmount();
    final trash = double.tryParse(trashController.text) ?? 0.0;
    final wifi = double.tryParse(wifiController.text) ?? 0.0;
    final parking = double.tryParse(parkingController.text) ?? 0.0;
    final additional = double.tryParse(additionalController.text) ?? 0.0;
    
    return rent + electricity + water + trash + wifi + parking + additional;
  }
  
  Future<void> _createBill() async {
    try {
      Loaders.showLoadingDialog(context);
      
      final repository = ref.read(billingRepositoryProvider);
      await repository.createBillFromInput(
        propertyId: selectedPropertyId!,
        unitId: selectedUnitId!,
        electricityCurrent: double.parse(electricityCurrentController.text),
        waterCurrent: double.parse(waterCurrentController.text),
        additionalCharges: {
          'trash': double.parse(trashController.text),
          'wifi': double.parse(wifiController.text),
          'parking': double.parse(parkingController.text),
          'other': double.parse(additionalController.text),
        },
        month: DateTime.now().month,
        year: DateTime.now().year,
      );
      
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close screen
      
      Loaders.successSnackBar(
        title: 'Bill Created',
        message: 'The bill has been created and sent to the tenant',
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      Loaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }
}
\\\

### Step 3.2: Tenant - View Billing Screen

This screen will show bill breakdown with highlighted paid items.

\\\dart
// Create tenant_view_billing_screen.dart
// - Show bill breakdown
// - Highlight paid items in green
// - Show unpaid items in red
// - Display late fees if applicable
// - Show due date and days until due/overdue
\\\

### Step 3.3: Tenant - Pay Rent Screen with Partial Payment

\\\dart
// Create tenant_pay_rent_screen.dart
// - Checkbox for full payment
// - Checkboxes for individual items (disabled if already paid)
// - Calculate total based on selection
// - Upload proof of payment
// - Submit for validation
\\\

### Step 3.4: Admin - Validate Payments Screen

\\\dart
//  Create admin_validate_payments_screen.dart
// - List all pending verification payments
// - Show proof of payment
// - Approve/Reject buttons
// - Add admin notes
\\\

---

## Phase 4: Scheduled Jobs & Cloud Functions (Day 11-12)

### Step 4.1: Late Fee Calculator (Daily Job)

\\\dart
// Firebase Cloud Function (or Flutter scheduled job)
// Run daily at midnight
Future<void> calculateLateFees() async {
  final repository = BillingRepository(...);
  await repository.updateLateFees();
}
\\\

### Step 4.2: Eviction Notice (Daily Job)

\\\dart
// Check for tenants with 2 consecutive unpaid months
Future<void> checkEvictionStatus() async {
  final firestore = FirebaseFirestore.instance;
  
  // Get all tenants
  final tenants = await firestore
      .collection('Users')
      .where('account.role', isEqualTo: 'tenant')
      .get();
  
  for (final tenantDoc in tenants.docs) {
    final userId = tenantDoc.id;
    
    // Get all bills for tenant
    final bills = await firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .orderBy('billingPeriod.year', descending: true)
        .orderBy('billingPeriod.month', descending: true)
        .limit(2)
        .get();
    
    if (bills.docs.length < 2) continue;
    
    final currentBill = BillModel.fromSnapshot(bills.docs[0]);
    final previousBill = BillModel.fromSnapshot(bills.docs[1]);
    
    // Check if should evict
    if (currentBill.shouldEvict([currentBill, previousBill])) {
      // Send eviction notice
      await _sendEvictionNotice(userId, currentBill, previousBill);
      
      // Update tenant status
      await firestore.collection('Users').doc(userId).update({
        'account.evictionNotice': true,
        'account.evictionDate': DateTime.now().toIso8601String(),
      });
    }
  }
}
\\\

---

## Phase 5: Receipt Generation (Day 13)

### Step 5.1: PDF Receipt Generator

\\\dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generateBillReceipt(BillModel bill, List<PaymentModel> payments) async {
  final pdf = pw.Document();
  
  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(
            level: 0,
            child: pw.Text('Payment Receipt', style: pw.TextStyle(fontSize: 24)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Receipt No: \'),
          pw.Text('Date: \'),
          pw.Text('Tenant: \'),
          pw.Text('Unit: \'),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text('Bill Breakdown', style: pw.TextStyle(fontSize: 18)),
          _buildReceiptItem('Rent', bill.baseRent),
          _buildReceiptItem('Electricity', bill.electricity.amount),
          _buildReceiptItem('Water', bill.water.amount),
          // ... more items
          pw.Divider(),
          pw.Text('Total: \', 
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Payment History'),
          ...payments.map((p) => pw.Text(
            '\: \ - \'
          )),
        ],
      ),
    ),
  );
  
  return pdf.save();
}
\\\

---

## Testing Checklist

### Admin Tests
-  Can select property and unit
-  Previous readings are fetched correctly
-  Consumption is calculated automatically
-  Rates are fetched from property settings
-  Total is calculated correctly
-  Bill is saved to Firestore
-  Tenant can see the bill immediately
-  Can validate payments with proof
-  Can approve/reject payments

### Tenant Tests
-  Can view bill breakdown
-  Can see balance on home screen
-  Can choose partial payment
-  Paid items are highlighted/disabled
-  Can upload proof of payment
-  Transaction history updates after approval
-  Bill breakdown shows paid status
-  Can download receipt when fully paid

### Late Fee Tests
-  No late fee within grace period
-  Late fee applies after grace period
-  Late fee increases weekly
-  Total updates with late fee
-  Balance updates with late fee

### Eviction Tests
-  Eviction notice sent after 2 unpaid months
-  Tenant status updated
-  Admin is notified

---

## Database Migration Steps

1. **Add utility rates to existing Properties**
2. **Add last readings to Units**
3. **Update BillingSettings with new config**
4. **Test with sample data**
5. **Deploy to production**

---

## Summary

This implementation covers:
 Property-based billing
 Automatic consumption calculation  
 Partial payment support
 Payment validation workflow
 Late fee automation (150/week)
 Eviction notices (2 months unpaid)
 Receipt generation
 Real-time updates
 Complete audit trail

Next: Start with Phase 1 (Models) and work sequentially through each phase.
