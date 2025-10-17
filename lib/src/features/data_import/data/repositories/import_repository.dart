import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/import_models.dart';
import '../../../../features/billing/domain/bill_model.dart';
import '../../../../features/billing/domain/billing_models.dart';
import '../../../../features/billing/domain/payment_model.dart';

/// Repository for importing bulk data into Firebase
class ImportRepository {
  final FirebaseFirestore _firestore;

  ImportRepository(this._firestore);

  /// Import bills to Firebase with batch writes
  Future<ImportResult> importBills(
    List<ImportBillData> billsData, {
    Function(int current, int total)? onProgress,
  }) async {
    final startTime = DateTime.now();
    int successCount = 0;
    final errors = <String>[];
    final unitLastReadings = <String, Map<String, Map<String, dynamic>>>{};

    try {
      // Process in batches of 500 (Firebase limit)
      const batchSize = 500;
      for (var i = 0; i < billsData.length; i += batchSize) {
        final end = (i + batchSize < billsData.length) ? i + batchSize : billsData.length;
        final batch = _firestore.batch();
        final batchData = billsData.sublist(i, end);

        for (var billData in batchData) {
          try {
            // Convert ImportBillData to BillModel
            final bill = _createBillModel(billData);
            final billRef = _firestore.collection('Bills').doc(bill.billId);
            batch.set(billRef, bill.toMap());

            // Track last readings for unit update
            _trackLastReadings(billData, unitLastReadings);

            successCount++;
          } catch (e) {
            errors.add('Error creating bill for ${billData.userName}: $e');
          }
        }

        // Commit batch
        await batch.commit();
        onProgress?.call(end, billsData.length);
      }

      // Update unit last readings
      await _updateUnitLastReadings(unitLastReadings);

      final duration = DateTime.now().difference(startTime);
      return ImportResult(
        totalRecords: billsData.length,
        successCount: successCount,
        errorCount: errors.length,
        errors: errors,
        duration: duration,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      errors.add('Fatal error during import: $e');
      return ImportResult(
        totalRecords: billsData.length,
        successCount: successCount,
        errorCount: billsData.length - successCount,
        errors: errors,
        duration: duration,
      );
    }
  }

  /// Import payments to Firebase with batch writes
  Future<ImportResult> importPayments(
    List<ImportPaymentData> paymentsData, {
    Function(int current, int total)? onProgress,
  }) async {
    final startTime = DateTime.now();
    int successCount = 0;
    final errors = <String>[];
    final billUpdates = <String, Map<String, dynamic>>{};

    try {
      const batchSize = 500;
      for (var i = 0; i < paymentsData.length; i += batchSize) {
        final end = (i + batchSize < paymentsData.length) ? i + batchSize : paymentsData.length;
        final batch = _firestore.batch();
        final batchData = paymentsData.sublist(i, end);

        for (var paymentData in batchData) {
          try {
            final payment = _createPaymentModel(paymentData);
            final paymentRef = _firestore.collection('Payments').doc(payment.paymentId);
            batch.set(paymentRef, payment.toMap());

            // Track bill updates
            _trackBillPaymentUpdate(paymentData, billUpdates);

            successCount++;
          } catch (e) {
            errors.add('Error creating payment ${paymentData.paymentId}: $e');
          }
        }

        await batch.commit();
        onProgress?.call(end, paymentsData.length);
      }

      // Update bills with payment info
      await _updateBillsFromPayments(billUpdates);

      final duration = DateTime.now().difference(startTime);
      return ImportResult(
        totalRecords: paymentsData.length,
        successCount: successCount,
        errorCount: errors.length,
        errors: errors,
        duration: duration,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      errors.add('Fatal error during payment import: $e');
      return ImportResult(
        totalRecords: paymentsData.length,
        successCount: successCount,
        errorCount: paymentsData.length - successCount,
        errors: errors,
        duration: duration,
      );
    }
  }

  /// Convert ImportBillData to BillModel
  BillModel _createBillModel(ImportBillData data) {
    final now = DateTime.now();
    final billingPeriod = BillingPeriod(
      month: data.billingMonth,
      year: data.billingYear,
      startDate: data.startDate,
      endDate: data.endDate,
      dueDate: data.dueDate,
    );

    final electricity = UtilityCharge(
      previousReading: data.electricityPreviousReading,
      currentReading: data.electricityCurrentReading,
      consumption: data.electricityConsumption,
      unit: 'kWh',
      ratePerUnit: data.electricityRatePerUnit,
      amount: data.electricityAmount,
      meterNumber: data.electricityMeterNumber,
      readingDate: data.electricityReadingDate,
    );

    final water = UtilityCharge(
      previousReading: data.waterPreviousReading,
      currentReading: data.waterCurrentReading,
      consumption: data.waterConsumption,
      unit: 'm³',
      ratePerUnit: data.waterRatePerUnit,
      amount: data.waterAmount,
      meterNumber: data.waterMeterNumber,
      readingDate: data.waterReadingDate,
    );

    final lateFeeDetails = LateFeeDetails(
      isLate: data.lateFee > 0,
      weeksOverdue: data.lateFeeWeeks,
      lateFeePerWeek: 150.0,
      totalLateFee: data.lateFee,
      gracePeriodEnd: data.dueDate.add(const Duration(days: 7)),
    );

    // Create payment breakdown items
    final rentBreakdown = PaymentBreakdownItem(
      amount: data.baseRent,
      amountPaid: data.isPaid ? data.baseRent : 0.0,
      balance: data.isPaid ? 0.0 : data.baseRent,
      isPaid: data.isPaid,
      paidAt: data.isPaid ? data.dueDate : null,
    );

    final electricityBreakdown = PaymentBreakdownItem(
      amount: data.electricityAmount,
      amountPaid: data.isPaid ? data.electricityAmount : 0.0,
      balance: data.isPaid ? 0.0 : data.electricityAmount,
      isPaid: data.isPaid,
      paidAt: data.isPaid ? data.dueDate : null,
    );

    final waterBreakdown = PaymentBreakdownItem(
      amount: data.waterAmount,
      amountPaid: data.isPaid ? data.waterAmount : 0.0,
      balance: data.isPaid ? 0.0 : data.waterAmount,
      isPaid: data.isPaid,
      paidAt: data.isPaid ? data.dueDate : null,
    );

    final trashBreakdown = PaymentBreakdownItem(
      amount: data.trashAmount,
      amountPaid: data.isPaid ? data.trashAmount : 0.0,
      balance: data.isPaid ? 0.0 : data.trashAmount,
      isPaid: data.isPaid,
      paidAt: data.isPaid ? data.dueDate : null,
    );

    final wifiBreakdown = PaymentBreakdownItem(
      amount: data.wifiAmount,
      amountPaid: data.isPaid ? data.wifiAmount : 0.0,
      balance: data.isPaid ? 0.0 : data.wifiAmount,
      isPaid: data.isPaid,
      paidAt: data.isPaid ? data.dueDate : null,
    );

    final parkingBreakdown = PaymentBreakdownItem(
      amount: data.parkingAmount,
      amountPaid: data.isPaid ? data.parkingAmount : 0.0,
      balance: data.isPaid ? 0.0 : data.parkingAmount,
      isPaid: data.isPaid,
      paidAt: data.isPaid ? data.dueDate : null,
    );

    final additionalChargesBreakdown = PaymentBreakdownItem(
      amount: data.additionalChargesAmount,
      amountPaid: data.isPaid ? data.additionalChargesAmount : 0.0,
      balance: data.isPaid ? 0.0 : data.additionalChargesAmount,
      isPaid: data.isPaid,
      paidAt: data.isPaid ? data.dueDate : null,
      description: data.additionalChargesDescription.isNotEmpty ? data.additionalChargesDescription : null,
    );

    BillStatus status;
    if (data.isPaid) {
      status = BillStatus.paid;
    } else if (data.lateFee > 0 || now.isAfter(data.dueDate)) {
      status = BillStatus.overdue;
    } else if (data.amountPaid > 0) {
      status = BillStatus.partiallyPaid;
    } else {
      status = BillStatus.pending;
    }

    return BillModel(
      billId: data.billId,
      userId: data.userId,
      userEmail: data.userEmail,
      userName: data.userName,
      unitId: data.unitId,
      propertyId: data.propertyId,
      billingPeriod: billingPeriod,
      baseRent: data.baseRent,
      rentDescription: 'Monthly Rent',
      electricity: electricity,
      water: water,
      additionalCharges: const [], // Empty array as per project rules
      subtotal: data.subtotal,
      discount: data.discount,
      discountReason: data.discountReason,
      lateFee: data.lateFee,
      tax: 0.0,
      total: data.total,
      amountPaid: data.amountPaid,
      balance: data.balance,
      rentBreakdown: rentBreakdown,
      electricityBreakdown: electricityBreakdown,
      waterBreakdown: waterBreakdown,
      trashBreakdown: trashBreakdown,
      wifiBreakdown: wifiBreakdown,
      parkingBreakdown: parkingBreakdown,
      additionalChargesBreakdown: additionalChargesBreakdown,
      lateFeeDetails: lateFeeDetails,
      status: status,
      isPaid: data.isPaid,
      isOverdue: status == BillStatus.overdue,
      isPartiallyPaid: status == BillStatus.partiallyPaid,
      createdAt: data.startDate,
      updatedAt: now,
      paidAt: data.isPaid ? data.dueDate : null,
      generatedBy: 'import_system',
      notes: 'Imported from historical data',
    );
  }

  /// Convert ImportPaymentData to PaymentModel
  PaymentModel _createPaymentModel(ImportPaymentData data) {
    return PaymentModel(
      paymentId: data.paymentId,
      billId: data.billId,
      userId: data.userId,
      userEmail: '', // Will be filled from bill
      userName: '', // Will be filled from bill
      unitId: '', // Will be filled from bill
      amount: data.amount,
      paymentType: PaymentType.full,
      paymentMethod: PaymentMethod.fromJson(data.paymentMethod.toLowerCase()),
      paymentMethodDetails: {'referenceNumber': data.referenceNumber},
      rentAllocation: PaymentAllocationItem(amount: data.allocRent, appliedAt: data.paymentDate),
      electricityAllocation: PaymentAllocationItem(amount: data.allocElectricity, appliedAt: data.paymentDate),
      waterAllocation: PaymentAllocationItem(amount: data.allocWater, appliedAt: data.paymentDate),
      trashAllocation: PaymentAllocationItem(amount: data.allocTrash, appliedAt: data.paymentDate),
      wifiAllocation: PaymentAllocationItem(amount: data.allocWifi, appliedAt: data.paymentDate),
      parkingAllocation: PaymentAllocationItem(amount: data.allocParking, appliedAt: data.paymentDate),
      additionalChargesAllocation: PaymentAllocationItem(amount: data.allocAdditional, appliedAt: data.paymentDate),
      paidFor: _getPaidForCategories(data),
      transactionDate: data.paymentDate,
      transactionId: data.referenceNumber,
      receiptNumber: 'RCP-${data.paymentId}',
      status: PaymentStatus.fromJson(data.status),
      paymentStatus: PaymentVerificationStatus.fromJson(data.status == 'verified' ? 'verified' : 'pending_verification'),
      verifiedBy: data.verifiedBy.isNotEmpty ? data.verifiedBy : null,
      verifiedAt: data.status == 'verified' ? data.verifiedAt : null,
      proofOfPaymentUrl: data.proofOfPaymentUrl.isNotEmpty ? data.proofOfPaymentUrl : null,
      proofUploadedAt: data.proofOfPaymentUrl.isNotEmpty ? data.paymentDate : null,
      createdAt: data.paymentDate,
      updatedAt: data.verifiedAt,
      notes: data.notes,
    );
  }

  List<PaymentCategory> _getPaidForCategories(ImportPaymentData data) {
    final categories = <PaymentCategory>[];
    if (data.allocRent > 0) categories.add(PaymentCategory.rent);
    if (data.allocElectricity > 0) categories.add(PaymentCategory.electricity);
    if (data.allocWater > 0) categories.add(PaymentCategory.water);
    if (data.allocTrash > 0) categories.add(PaymentCategory.trash);
    if (data.allocWifi > 0) categories.add(PaymentCategory.wifi);
    if (data.allocParking > 0) categories.add(PaymentCategory.parking);
    if (data.allocAdditional > 0) categories.add(PaymentCategory.additionalCharges);
    return categories;
  }

  void _trackLastReadings(ImportBillData bill, Map<String, Map<String, Map<String, dynamic>>> lastReadings) {
    lastReadings.putIfAbsent(bill.unitId, () => {});
    lastReadings[bill.unitId]!['electricity'] = {
      'reading': bill.electricityCurrentReading,
      'date': bill.electricityReadingDate.toIso8601String(),
      'meterNumber': bill.electricityMeterNumber,
    };
    lastReadings[bill.unitId]!['water'] = {
      'reading': bill.waterCurrentReading,
      'date': bill.waterReadingDate.toIso8601String(),
      'meterNumber': bill.waterMeterNumber,
    };
  }

  Future<void> _updateUnitLastReadings(Map<String, Map<String, Map<String, dynamic>>> lastReadings) async {
    final batch = _firestore.batch();
    
    for (var entry in lastReadings.entries) {
      final unitId = entry.key;
      final readings = entry.value;
      
      // Find unit document by querying
      final unitSnapshot = await _firestore
          .collectionGroup('Units')
          .where(FieldPath.documentId, isEqualTo: unitId)
          .limit(1)
          .get();
      
      if (unitSnapshot.docs.isNotEmpty) {
        batch.update(unitSnapshot.docs.first.reference, {'lastReadings': readings});
      }
    }
    
    await batch.commit();
  }

  void _trackBillPaymentUpdate(ImportPaymentData payment, Map<String, Map<String, dynamic>> billUpdates) {
    billUpdates[payment.billId] = {
      'amountPaid': payment.amount,
      'paidAt': payment.paymentDate.toIso8601String(),
      'isPaid': true,
      'status': 'paid',
    };
  }

  Future<void> _updateBillsFromPayments(Map<String, Map<String, dynamic>> billUpdates) async {
    final batch = _firestore.batch();
    
    for (var entry in billUpdates.entries) {
      final billRef = _firestore.collection('Bills').doc(entry.key);
      batch.update(billRef, entry.value);
    }
    
    await batch.commit();
  }
}
