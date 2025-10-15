import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bill_model.dart';
import '../domain/payment_model.dart';
import '../domain/billing_models.dart';
import '../domain/property_billing_model.dart';
import '../domain/unit_billing_model.dart';
import '../../../core/utils/app_logger.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class BillingRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  BillingRepository({
    required this.firestore,
    required this.auth,
  });

  // ==================== BILLS ====================

  /// Get all bills for a user
  Stream<List<BillModel>> getUserBills(String userId) {
    return firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .orderBy('billingPeriod.year', descending: true)
        .orderBy('billingPeriod.month', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BillModel.fromSnapshot(doc)).toList());
  }

  /// Get bill by ID
  Future<BillModel?> getBillById(String billId) async {
    final doc = await firestore.collection('Bills').doc(billId).get();
    if (!doc.exists) return null;
    return BillModel.fromSnapshot(doc);
  }

  /// Get bill by ID as a stream (real-time updates)
  Stream<BillModel?> getBillByIdStream(String billId) {
    AppLogger.debug('BillingRepository.getBillByIdStream - billId: $billId');
    return firestore
        .collection('Bills')
        .doc(billId)
        .snapshots()
        .map((doc) {
          AppLogger.debug('Bill snapshot - exists: ${doc.exists}, id: ${doc.id}');
          if (!doc.exists) return null;
          return BillModel.fromSnapshot(doc);
        });
  }

  /// Get unpaid bills for a user
  Stream<List<BillModel>> getUnpaidBills(String userId) {
    return firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .where('isPaid', isEqualTo: false)
        .orderBy('billingPeriod.dueDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BillModel.fromSnapshot(doc)).toList());
  }

  /// Get overdue bills for a user
  Stream<List<BillModel>> getOverdueBills(String userId) {
    return firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .where('isOverdue', isEqualTo: true)
        .where('isPaid', isEqualTo: false)
        .orderBy('billingPeriod.dueDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BillModel.fromSnapshot(doc)).toList());
  }

  /// Get partially paid bills for a user
  Stream<List<BillModel>> getPartiallyPaidBills(String userId) {
    return firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .where('isPartiallyPaid', isEqualTo: true)
        .where('isPaid', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BillModel.fromSnapshot(doc)).toList());
  }

  /// Get all bills for current month (Admin)
  Stream<List<BillModel>> getCurrentMonthBills({int? month, int? year}) {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    return firestore
        .collection('Bills')
        .where('billingPeriod.month', isEqualTo: targetMonth)
        .where('billingPeriod.year', isEqualTo: targetYear)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BillModel.fromSnapshot(doc)).toList());
  }

  /// Create a new bill (Admin only)
  Future<void> createBill(BillModel bill) async {
    await firestore.collection('Bills').doc(bill.billId).set(bill.toMap());
  }

  /// Update bill status
  Future<void> updateBillStatus(String billId, Map<String, dynamic> updates) async {
    await firestore.collection('Bills').doc(billId).update(updates);
  }

  // ==================== PAYMENTS ====================

  /// Get all payments for a user
  Stream<List<PaymentModel>> getUserPayments(String userId) {
    return firestore
        .collection('Payments')
        .where('userId', isEqualTo: userId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentModel.fromSnapshot(doc)).toList());
  }

  /// Get payments for a specific bill
  Stream<List<PaymentModel>> getBillPayments(String billId) {
    return firestore
        .collection('Payments')
        .where('billId', isEqualTo: billId)
        .where('status', isEqualTo: 'completed')
        .orderBy('transactionDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentModel.fromSnapshot(doc)).toList());
  }

  /// Get pending verification payments (Admin)
  Stream<List<PaymentModel>> getPendingVerificationPayments() {
    return firestore
        .collection('Payments')
        .where('paymentStatus', isEqualTo: 'pending_verification')
        .orderBy('transactionDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentModel.fromSnapshot(doc)).toList());
  }

  /// Submit a partial payment
  Future<void> submitPartialPayment({
    required String billId,
    required String userId,
    required double amount,
    required List<PaymentCategory> payFor,
    required PaymentMethod paymentMethod,
    required Map<String, dynamic> paymentDetails,
    String? proofOfPaymentUrl,
    String notes = '',
  }) async {
    // Get the bill
    final bill = await getBillById(billId);
    if (bill == null) throw Exception('Bill not found');

    // Calculate allocation
    Map<PaymentCategory, double> allocation = {};
    double totalAllocated = 0.0;

    for (final category in payFor) {
      double balance = 0.0;
      switch (category) {
        case PaymentCategory.rent:
          balance = bill.rentBreakdown.balance;
          break;
        case PaymentCategory.electricity:
          balance = bill.electricityBreakdown.balance;
          break;
        case PaymentCategory.water:
          balance = bill.waterBreakdown.balance;
          break;
        case PaymentCategory.trash:
          balance = bill.trashBreakdown.balance;
          break;
        case PaymentCategory.wifi:
          balance = bill.wifiBreakdown.balance;
          break;
        case PaymentCategory.parking:
          balance = bill.parkingBreakdown.balance;
          break;
        case PaymentCategory.additionalCharges:
          balance = bill.additionalChargesBreakdown.balance;
          break;
      }
      allocation[category] = balance;
      totalAllocated += balance;
    }

    // Verify amount matches
    if ((totalAllocated - amount).abs() > 0.01) {
      throw Exception('Payment amount does not match selected items');
    }

    // Create payment document
    final paymentId = 'PAY_';
    final now = DateTime.now();

    final payment = PaymentModel(
      paymentId: paymentId,
      billId: billId,
      userId: userId,
      userEmail: bill.userEmail,
      userName: bill.userName,
      unitId: bill.unitId,
      amount: amount,
      paymentType: PaymentType.partial,
      paymentMethod: paymentMethod,
      paymentMethodDetails: paymentDetails,
      rentAllocation: PaymentAllocationItem(
        amount: allocation[PaymentCategory.rent] ?? 0.0,
        appliedAt: payFor.contains(PaymentCategory.rent) ? now : null,
      ),
      electricityAllocation: PaymentAllocationItem(
        amount: allocation[PaymentCategory.electricity] ?? 0.0,
        appliedAt: payFor.contains(PaymentCategory.electricity) ? now : null,
      ),
      waterAllocation: PaymentAllocationItem(
        amount: allocation[PaymentCategory.water] ?? 0.0,
        appliedAt: payFor.contains(PaymentCategory.water) ? now : null,
      ),
      trashAllocation: PaymentAllocationItem(
        amount: allocation[PaymentCategory.trash] ?? 0.0,
        appliedAt: payFor.contains(PaymentCategory.trash) ? now : null,
      ),
      wifiAllocation: PaymentAllocationItem(
        amount: allocation[PaymentCategory.wifi] ?? 0.0,
        appliedAt: payFor.contains(PaymentCategory.wifi) ? now : null,
      ),
      parkingAllocation: PaymentAllocationItem(
        amount: allocation[PaymentCategory.parking] ?? 0.0,
        appliedAt: payFor.contains(PaymentCategory.parking) ? now : null,
      ),
      additionalChargesAllocation: PaymentAllocationItem(
        amount: allocation[PaymentCategory.additionalCharges] ?? 0.0,
        appliedAt: payFor.contains(PaymentCategory.additionalCharges) ? now : null,
      ),
      paidFor: payFor,
      transactionDate: now,
      transactionId: 'TXN_',
      receiptNumber: 'REC____',
      status: PaymentStatus.pending,
      paymentStatus: PaymentVerificationStatus.pendingVerification,
      proofOfPaymentUrl: proofOfPaymentUrl,
      proofUploadedAt: proofOfPaymentUrl != null ? now : null,
      createdAt: now,
      updatedAt: now,
      notes: notes,
    );

    await firestore.collection('Payments').doc(paymentId).set(payment.toMap());
  }

  /// Verify and approve a payment (Admin only)
  Future<void> verifyPayment({
    required String paymentId,
    required String adminUserId,
    required bool approve,
    String adminNotes = '',
  }) async {
    final paymentDoc = await firestore.collection('Payments').doc(paymentId).get();
    if (!paymentDoc.exists) throw Exception('Payment not found');

    final payment = PaymentModel.fromSnapshot(paymentDoc);
    final now = DateTime.now();

    if (approve) {
      // Update payment status
      await firestore.collection('Payments').doc(paymentId).update({
        'status': PaymentStatus.completed.toJson(),
        'paymentStatus': PaymentVerificationStatus.verified.toJson(),
        'verifiedBy': adminUserId,
        'verifiedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'adminNotes': adminNotes,
      });

      // Update bill breakdown
      final bill = await getBillById(payment.billId);
      if (bill == null) throw Exception('Bill not found');

      Map<String, dynamic> updates = {};
      double newTotalPaid = bill.amountPaid + payment.amount;
      double newBalance = bill.balance - payment.amount;

      for (final category in payment.paidFor) {
        double categoryAmount = 0.0;
        final categoryKey = category.toJson();

        switch (category) {
          case PaymentCategory.rent:
            categoryAmount = payment.rentAllocation.amount;
            break;
          case PaymentCategory.electricity:
            categoryAmount = payment.electricityAllocation.amount;
            break;
          case PaymentCategory.water:
            categoryAmount = payment.waterAllocation.amount;
            break;
          case PaymentCategory.trash:
            categoryAmount = payment.trashAllocation.amount;
            break;
          case PaymentCategory.wifi:
            categoryAmount = payment.wifiAllocation.amount;
            break;
          case PaymentCategory.parking:
            categoryAmount = payment.parkingAllocation.amount;
            break;
          case PaymentCategory.additionalCharges:
            categoryAmount = payment.additionalChargesAllocation.amount;
            break;
        }

        updates['paymentBreakdown.$categoryKey.amountPaid'] =
            FieldValue.increment(categoryAmount);
        updates['paymentBreakdown.$categoryKey.balance'] =
            FieldValue.increment(-categoryAmount);
        updates['paymentBreakdown.$categoryKey.isPaid'] = true;
        updates['paymentBreakdown.$categoryKey.paidAt'] = now.toIso8601String();
      }

      updates['summary.amountPaid'] = newTotalPaid;
      updates['summary.balance'] = newBalance;

      // Determine bill status
      if (newBalance <= 0.01) {
        updates['status'] = BillStatus.paid.name;
        updates['isPaid'] = true;
        updates['isPartiallyPaid'] = false;
        updates['paidAt'] = now.toIso8601String();
      } else {
        updates['status'] = BillStatus.partiallyPaid.name;
        updates['isPaid'] = false;
        updates['isPartiallyPaid'] = true;
      }

      updates['updatedAt'] = now.toIso8601String();

      await firestore.collection('Bills').doc(payment.billId).update(updates);
    } else {
      // Reject payment
      await firestore.collection('Payments').doc(paymentId).update({
        'status': PaymentStatus.failed.toJson(),
        'paymentStatus': PaymentVerificationStatus.rejected.toJson(),
        'verifiedBy': adminUserId,
        'verifiedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'adminNotes': adminNotes,
      });
    }
  }

  /// Get unpaid breakdown for a bill
  Future<Map<String, double>> getUnpaidBreakdown(String billId) async {
    final bill = await getBillById(billId);
    if (bill == null) throw Exception('Bill not found');

    Map<String, double> unpaid = {};

    if (!bill.rentBreakdown.isPaid && bill.rentBreakdown.balance > 0) {
      unpaid['rent'] = bill.rentBreakdown.balance;
    }
    if (!bill.electricityBreakdown.isPaid && bill.electricityBreakdown.balance > 0) {
      unpaid['electricity'] = bill.electricityBreakdown.balance;
    }
    if (!bill.waterBreakdown.isPaid && bill.waterBreakdown.balance > 0) {
      unpaid['water'] = bill.waterBreakdown.balance;
    }
    if (!bill.additionalChargesBreakdown.isPaid &&
        bill.additionalChargesBreakdown.balance > 0) {
      unpaid['additionalCharges'] = bill.additionalChargesBreakdown.balance;
    }

    return unpaid;
  }

  // ==================== PROPERTY & UNIT QUERIES ====================

  /// Get all properties for billing
  Stream<List<Map<String, dynamic>>> getProperties() {
    return firestore
        .collection('Property')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Get units for a property
  Stream<List<UnitBillingInfo>> getUnitsForProperty(String propertyId) {
    AppLogger.debug('BillingRepository.getUnitsForProperty - propertyId: $propertyId');
    return firestore
        .collection('Property')
        .doc(propertyId)
        .collection('Units')
        .where('rental.status', isEqualTo: 'occupied')
        .snapshots()
        .map((snapshot) {
          AppLogger.debug('Units snapshot received: ${snapshot.docs.length} documents');
          return snapshot.docs.map((doc) {
            AppLogger.trace('Processing unit doc ID: ${doc.id}');
            return UnitBillingInfo.fromSnapshot(doc);
          }).toList();
        });
  }

  /// Get unit details
  Future<UnitBillingInfo?> getUnitDetails(String propertyId, String unitId) async {
    final doc = await firestore
        .collection('Property')
        .doc(propertyId)
        .collection('Units')
        .doc(unitId)
        .get();

    if (!doc.exists) return null;
    return UnitBillingInfo.fromSnapshot(doc);
  }

  /// Get property utility rates
  Future<PropertyUtilityRates?> getPropertyRates(String propertyId) async {
    try {
      final doc = await firestore.collection('Property').doc(propertyId).get();
      if (!doc.exists) {
        AppLogger.warning('Property document does not exist for ID: $propertyId');
        return null;
      }

      final data = doc.data()!;
      AppLogger.trace('Raw Firestore data for Property/$propertyId: $data');
      AppLogger.trace('Property-level keys: ${data.keys}');
      
      if (!data.containsKey('utilityRates')) {
        AppLogger.warning('No utilityRates field found in property document');
        return null;
      }

      final utilityRatesData = data['utilityRates'] as Map<String, dynamic>;
      AppLogger.trace('utilityRates data: $utilityRatesData');
      
      // CRITICAL FIX: fixedCharges is at property level, not in utilityRates!
      // Pass it separately to fromMap
      final combinedData = Map<String, dynamic>.from(utilityRatesData);
      if (data.containsKey('fixedCharges')) {
        AppLogger.debug('Found fixedCharges at property level!');
        combinedData['fixedCharges'] = data['fixedCharges'];
        AppLogger.trace('Property-level fixedCharges: ${data['fixedCharges']}');
      } else {
        AppLogger.warning('No fixedCharges found at property level');
      }
      
      final rates = PropertyUtilityRates.fromMap(combinedData);
      AppLogger.debug('Parsed PropertyUtilityRates - fixedCharges count: ${rates.fixedCharges.length}');
      AppLogger.trace('Fixed charges details: ${rates.fixedCharges}');
      
      return rates;
    } catch (e, stackTrace) {
      AppLogger.error('ERROR in getPropertyRates', e, stackTrace);
      return null;
    }
  }

  // ==================== ENHANCED BILL CREATION ====================

  /// Create bill with all calculations from admin input
  Future<String> createBillFromInput({
    required String propertyId,
    required String unitId,
    required double electricityCurrent,
    required double waterCurrent,
    required Map<String, double> additionalCharges,
    String? additionalChargesDescription, // Optional description for 'other' charges
    required int month,
    required int year,
    double? rentOverride, // Optional: use this if rent was manually adjusted
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
    final profile = tenantData['profile'] as Map<String, dynamic>;

    // Calculate electricity
    final electricityPrevious = unit.lastElectricityReading?.reading ?? 0.0;
    final electricityConsumption = electricityCurrent - electricityPrevious;
    final electricityAmount = electricityConsumption * rates.electricityRatePerKwh;

    // Calculate water
    final waterPrevious = unit.lastWaterReading?.reading ?? 0.0;
    final waterConsumption = waterCurrent - waterPrevious;
    final waterAmount = waterConsumption * rates.waterRatePerCubicMeter;

    // Use rent override if provided, otherwise use unit's monthly rent
    final rentAmount = rentOverride ?? unit.monthlyRent;

    // Calculate total
    final subtotal = rentAmount +
        electricityAmount +
        waterAmount +
        additionalCharges.values.fold(0.0, (total, amount) => total + amount);

    // Create billing period
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    final now = DateTime.now();
    
    // NEW LOGIC: Due date is 7 days after bill creation, not 7 days after month end
    final dueDate = now.add(const Duration(days: 7));

    final billingPeriod = BillingPeriod(
      month: month,
      year: year,
      startDate: startDate,
      endDate: endDate,
      dueDate: dueDate,
    );

    // Create late fee details (initially not late)
    // NO GRACE PERIOD - Late fees apply immediately after due date
    final lateFeeDetails = LateFeeDetails(
      isLate: false,
      weeksOverdue: 0,
      lateFeePerWeek: 150.00,
      totalLateFee: 0.0,
      gracePeriodEnd: dueDate, // No grace period, same as due date
    );

    // Create bill
    final billId = 'BILL_${year}_${month.toString().padLeft(2, '0')}_${unit.tenantId}';

    final bill = BillModel(
      billId: billId,
      userId: unit.tenantId!,
      userEmail: profile['email'] as String,
      userName: '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim(),
      unitId: unitId,
      propertyId: propertyId,
      billingPeriod: billingPeriod,
      baseRent: rentAmount,
      rentDescription: 'Monthly rent for Unit ${unit.unitNumber}',
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
      additionalCharges: const [],  // No longer used - data is in paymentBreakdown
      subtotal: subtotal,
      discount: 0.0,
      discountReason: '',
      lateFee: 0.0,
      tax: 0.0,
      total: subtotal,
      amountPaid: 0.0,
      balance: subtotal,
      rentBreakdown: PaymentBreakdownItem(
        amount: rentAmount,
        amountPaid: 0.0,
        balance: rentAmount,
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
        amount: additionalCharges['parking'] ?? 0.0,
        amountPaid: 0.0,
        balance: additionalCharges['parking'] ?? 0.0,
        isPaid: false,
      ),
      additionalChargesBreakdown: PaymentBreakdownItem(
        amount: additionalCharges['other'] ?? 0.0,
        amountPaid: 0.0,
        balance: additionalCharges['other'] ?? 0.0,
        isPaid: false,
        description: additionalChargesDescription, // Store admin's custom description
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
        .collection('Property')
        .doc(propertyId)
        .collection('Units')
        .doc(unitId)
        .update({
      'lastReadings.electricity': {
        'reading': electricityCurrent,
        'readingDate': now.toIso8601String(),
        'meterNumber': unit.lastElectricityReading?.meterNumber ?? 'ELEC-$unitId',
      },
      'lastReadings.water': {
        'reading': waterCurrent,
        'readingDate': now.toIso8601String(),
        'meterNumber': unit.lastWaterReading?.meterNumber ?? 'WATER-$unitId',
      },
      'updatedAt': now.toIso8601String(),
    });

    return billId;
  }

  // ==================== LATE FEE MANAGEMENT ====================

  /// Update late fees for overdue bills (run daily via Cloud Function)
  /// IMPORTANT: Late fees freeze when next billing period starts
  Future<void> updateLateFees() async {
    final now = DateTime.now();

    final overdueBills = await firestore
        .collection('Bills')
        .where('isPaid', isEqualTo: false)
        .where('isOverdue', isEqualTo: true)
        .get();

    for (final doc in overdueBills.docs) {
      final bill = BillModel.fromSnapshot(doc);

      // Check if there's a next bill for this user (same property/unit, next month)
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
        AppLogger.info('Found next bill for user ${bill.userId} - freezing late fees at $nextBillCreatedAt');
      }

      // Recalculate late fee (will freeze if nextBillCreatedAt is provided)
      final newLateFeeDetails = LateFeeDetails.calculate(
        dueDate: bill.billingPeriod.dueDate,
        gracePeriodDays: 0, // No grace period
        lateFeePerWeek: 150.00,
        nextBillCreatedAt: nextBillCreatedAt, // Freeze at next bill creation
      );

      if (newLateFeeDetails.totalLateFee != bill.lateFeeDetails.totalLateFee) {
        final newTotal = bill.subtotal + newLateFeeDetails.totalLateFee;
        final newBalance = newTotal - bill.amountPaid;

        AppLogger.info('Updating late fee for bill ${bill.billId}: ${bill.lateFeeDetails.totalLateFee} → ${newLateFeeDetails.totalLateFee}');
        
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

  /// Generate receipt PDF for fully paid bill
  Future<String> generateReceipt(String billId) async {
    final bill = await getBillById(billId);
    if (bill == null) throw Exception('Bill not found');
    if (!bill.isPaid) throw Exception('Bill not fully paid');

    // TODO: Implement PDF generation using pdf package
    // For now, return placeholder URL
    final receiptUrl = 'https://storage.googleapis.com/receipts/$billId.pdf';

    await firestore.collection('Bills').doc(billId).update({
      'receiptGenerated': true,
      'receiptUrl': receiptUrl,
      'receiptGeneratedAt': DateTime.now().toIso8601String(),
    });

    return receiptUrl;
  }

  // ==================== CONSUMPTION ANALYTICS ====================

  /// Get monthly consumption data for a specific unit
  Future<List<Map<String, dynamic>>> getUnitMonthlyConsumption({
    required String userId,
    required int numberOfMonths,
  }) async {
    final bills = await firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .orderBy('billingPeriod.year', descending: true)
        .orderBy('billingPeriod.month', descending: true)
        .limit(numberOfMonths)
        .get();

    return bills.docs.map((doc) {
      final bill = BillModel.fromSnapshot(doc);
      return {
        'month': bill.billingPeriod.month,
        'year': bill.billingPeriod.year,
        'monthLabel': '${_getMonthName(bill.billingPeriod.month)} ${bill.billingPeriod.year}',
        'electricity': {
          'consumption': bill.electricity.consumption,
          'amount': bill.electricity.amount,
          'currentReading': bill.electricity.currentReading,
          'previousReading': bill.electricity.previousReading,
        },
        'water': {
          'consumption': bill.water.consumption,
          'amount': bill.water.amount,
          'currentReading': bill.water.currentReading,
          'previousReading': bill.water.previousReading,
        },
        'totalAmount': bill.total,
      };
    }).toList();
  }

  /// Get consumption data for all units in a property (Admin)
  Future<List<Map<String, dynamic>>> getPropertyMonthlyConsumption({
    required String propertyId,
    required int month,
    required int year,
  }) async {
    final bills = await firestore
        .collection('Bills')
        .where('propertyId', isEqualTo: propertyId)
        .where('billingPeriod.month', isEqualTo: month)
        .where('billingPeriod.year', isEqualTo: year)
        .get();

    return bills.docs.map((doc) {
      final bill = BillModel.fromSnapshot(doc);
      return {
        'unitId': bill.unitId,
        'userId': bill.userId,
        'userName': bill.userName,
        'electricity': {
          'consumption': bill.electricity.consumption,
          'amount': bill.electricity.amount,
        },
        'water': {
          'consumption': bill.water.consumption,
          'amount': bill.water.amount,
        },
        'totalAmount': bill.total,
      };
    }).toList();
  }

  /// Get consumption trends for a user (for charts/analytics)
  Stream<List<Map<String, dynamic>>> getConsumptionTrends({
    required String userId,
    int months = 6,
  }) {
    return firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .orderBy('billingPeriod.year', descending: true)
        .orderBy('billingPeriod.month', descending: true)
        .limit(months)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final bill = BillModel.fromSnapshot(doc);
            return {
              'month': bill.billingPeriod.month,
              'year': bill.billingPeriod.year,
              'date': DateTime(bill.billingPeriod.year, bill.billingPeriod.month),
              'monthLabel': '${_getMonthName(bill.billingPeriod.month)} ${bill.billingPeriod.year}',
              'electricityConsumption': bill.electricity.consumption,
              'waterConsumption': bill.water.consumption,
              'electricityCost': bill.electricity.amount,
              'waterCost': bill.water.amount,
            };
          }).toList();
        });
  }

  /// Get average monthly consumption for a user
  Future<Map<String, double>> getAverageConsumption({
    required String userId,
    int months = 6,
  }) async {
    final bills = await firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .orderBy('billingPeriod.year', descending: true)
        .orderBy('billingPeriod.month', descending: true)
        .limit(months)
        .get();

    if (bills.docs.isEmpty) {
      return {
        'avgElectricityConsumption': 0.0,
        'avgWaterConsumption': 0.0,
        'avgElectricityCost': 0.0,
        'avgWaterCost': 0.0,
      };
    }

    double totalElecConsumption = 0.0;
    double totalWaterConsumption = 0.0;
    double totalElecCost = 0.0;
    double totalWaterCost = 0.0;

    for (final doc in bills.docs) {
      final bill = BillModel.fromSnapshot(doc);
      totalElecConsumption += bill.electricity.consumption;
      totalWaterConsumption += bill.water.consumption;
      totalElecCost += bill.electricity.amount;
      totalWaterCost += bill.water.amount;
    }

    final count = bills.docs.length;

    return {
      'avgElectricityConsumption': totalElecConsumption / count,
      'avgWaterConsumption': totalWaterConsumption / count,
      'avgElectricityCost': totalElecCost / count,
      'avgWaterCost': totalWaterCost / count,
      'months': count.toDouble(),
    };
  }

  /// Compare current month consumption with previous month
  Future<Map<String, dynamic>> compareWithPreviousMonth({
    required String userId,
  }) async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Get current month bill
    final currentBillId = 'BILL_${currentYear}_${currentMonth.toString().padLeft(2, '0')}_$userId';
    final currentBill = await getBillById(currentBillId);

    if (currentBill == null) {
      return {'error': 'Current month bill not found'};
    }

    // Get previous month bill
    final prevDate = DateTime(currentYear, currentMonth - 1);
    final prevBillId = 'BILL_${prevDate.year}_${prevDate.month.toString().padLeft(2, '0')}_$userId';
    final prevBill = await getBillById(prevBillId);

    if (prevBill == null) {
      return {
        'current': {
          'month': currentMonth,
          'year': currentYear,
          'electricityConsumption': currentBill.electricity.consumption,
          'waterConsumption': currentBill.water.consumption,
        },
        'previous': null,
        'comparison': null,
      };
    }

    // Calculate differences
    final elecDiff = currentBill.electricity.consumption - prevBill.electricity.consumption;
    final waterDiff = currentBill.water.consumption - prevBill.water.consumption;
    final elecPercentChange = (elecDiff / prevBill.electricity.consumption) * 100;
    final waterPercentChange = (waterDiff / prevBill.water.consumption) * 100;

    return {
      'current': {
        'month': currentMonth,
        'year': currentYear,
        'monthLabel': _getMonthName(currentMonth),
        'electricityConsumption': currentBill.electricity.consumption,
        'waterConsumption': currentBill.water.consumption,
        'electricityCost': currentBill.electricity.amount,
        'waterCost': currentBill.water.amount,
      },
      'previous': {
        'month': prevDate.month,
        'year': prevDate.year,
        'monthLabel': _getMonthName(prevDate.month),
        'electricityConsumption': prevBill.electricity.consumption,
        'waterConsumption': prevBill.water.consumption,
        'electricityCost': prevBill.electricity.amount,
        'waterCost': prevBill.water.amount,
      },
      'comparison': {
        'electricityDiff': elecDiff,
        'waterDiff': waterDiff,
        'electricityPercentChange': elecPercentChange,
        'waterPercentChange': waterPercentChange,
        'electricityIncreased': elecDiff > 0,
        'waterIncreased': waterDiff > 0,
      },
    };
  }

  /// Get month name from number
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // ==================== PAYMENT VALIDATION (ADMIN) ====================

  /// Get all pending payments (for admin validation)
  /// Returns payments with status='pending' (newly submitted payments)
  Stream<List<PaymentModel>> getPendingPayments() {
    return firestore
        .collection('Payments')
        .where('status', isEqualTo: 'pending')
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentModel.fromSnapshot(doc)).toList());
  }
}
