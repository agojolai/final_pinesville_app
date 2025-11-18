import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/import_models.dart';

/// Service for validating import data before Firebase writes
class DataValidatorService {
  final FirebaseFirestore _firestore;

  DataValidatorService(this._firestore);

  /// Validate bills data
  Future<List<ValidationError>> validateBills(List<ImportBillData> bills) async {
    final errors = <ValidationError>[];

    // Sort bills by user and date for continuity checks
    final sortedBills = List<ImportBillData>.from(bills)
      ..sort((a, b) {
        final userCompare = a.userId.compareTo(b.userId);
        if (userCompare != 0) return userCompare;
        return a.startDate.compareTo(b.startDate);
      });

    // Group by user for continuity validation
    final billsByUser = <String, List<ImportBillData>>{};
    for (var bill in sortedBills) {
      billsByUser.putIfAbsent(bill.userId, () => []).add(bill);
    }

    // Validate each bill
    for (var i = 0; i < sortedBills.length; i++) {
      final bill = sortedBills[i];
      final rowNumber = bills.indexOf(bill) + 2; // +2 for header and 1-based

      // Required field validation
      _validateRequiredBillFields(bill, rowNumber, errors);

      // Calculation validation
      _validateBillCalculations(bill, rowNumber, errors);

      // Date logic validation
      _validateBillDates(bill, rowNumber, errors);

      // Meter reading validation
      _validateMeterReadings(bill, rowNumber, errors);
    }

    // Validate meter continuity for each user
    for (var entry in billsByUser.entries) {
      _validateMeterContinuity(entry.value, errors);
    }

    // Validate user/unit/property existence in Firebase
    await _validateFirebaseReferences(sortedBills, errors);

    return errors;
  }

  /// Validate payments data
  Future<List<ValidationError>> validatePayments(List<ImportPaymentData> payments) async {
    final errors = <ValidationError>[];

    for (var i = 0; i < payments.length; i++) {
      final payment = payments[i];
      final rowNumber = i + 2;

      // Required fields
      if (payment.paymentId.isEmpty) {
        errors.add(ValidationError(
          rowNumber: rowNumber,
          field: 'paymentId',
          message: 'Payment ID is required',
        ));
      }

      if (payment.billId.isEmpty) {
        errors.add(ValidationError(
          rowNumber: rowNumber,
          field: 'billId',
          message: 'Bill ID is required',
        ));
      }

      if (payment.userId.isEmpty) {
        errors.add(ValidationError(
          rowNumber: rowNumber,
          field: 'userId',
          message: 'User ID is required',
        ));
      }

      if (payment.amount <= 0) {
        errors.add(ValidationError(
          rowNumber: rowNumber,
          field: 'amount',
          message: 'Payment amount must be greater than 0',
        ));
      }

      // Allocation validation
      final totalAlloc = payment.totalAllocations;
      if ((totalAlloc - payment.amount).abs() > 0.01) {
        errors.add(ValidationError(
          rowNumber: rowNumber,
          field: 'allocations',
          message: 'Allocation total ($totalAlloc) does not match payment amount (${payment.amount})',
        ));
      }

      // Status validation
      if (!['pending', 'verified', 'rejected'].contains(payment.status.toLowerCase())) {
        errors.add(ValidationError(
          rowNumber: rowNumber,
          field: 'status',
          message: 'Invalid status: ${payment.status}. Must be pending, verified, or rejected',
        ));
      }
    }

    return errors;
  }

  void _validateRequiredBillFields(ImportBillData bill, int rowNumber, List<ValidationError> errors) {
    if (bill.userId.isEmpty) {
      errors.add(ValidationError(rowNumber: rowNumber, field: 'userId', message: 'User ID is required'));
    }
    if (bill.unitId.isEmpty) {
      errors.add(ValidationError(rowNumber: rowNumber, field: 'unitId', message: 'Unit ID is required'));
    }
    if (bill.propertyId.isEmpty) {
      errors.add(ValidationError(rowNumber: rowNumber, field: 'propertyId', message: 'Property ID is required'));
    }
    if (bill.billingMonth < 1 || bill.billingMonth > 12) {
      errors.add(ValidationError(rowNumber: rowNumber, field: 'billingMonth', message: 'Invalid month: ${bill.billingMonth}'));
    }
    if (bill.baseRent <= 0) {
      errors.add(ValidationError(rowNumber: rowNumber, field: 'baseRent', message: 'Base rent must be greater than 0'));
    }
  }

  void _validateBillCalculations(ImportBillData bill, int rowNumber, List<ValidationError> errors) {
    // Electricity calculation
    final expectedElecConsumption = bill.electricityCurrentReading - bill.electricityPreviousReading;
    if ((bill.electricityConsumption - expectedElecConsumption).abs() > 0.01) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'electricityConsumption',
        message: 'Consumption mismatch: ${bill.electricityConsumption} != $expectedElecConsumption (current - previous)',
      ));
    }

    final expectedElecAmount = bill.electricityConsumption * bill.electricityRatePerUnit;
    if ((bill.electricityAmount - expectedElecAmount).abs() > 0.01) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'electricityAmount',
        message: 'Amount mismatch: ${bill.electricityAmount} != $expectedElecAmount',
      ));
    }

    // Water calculation
    final expectedWaterConsumption = bill.waterCurrentReading - bill.waterPreviousReading;
    if ((bill.waterConsumption - expectedWaterConsumption).abs() > 0.01) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'waterConsumption',
        message: 'Consumption mismatch: ${bill.waterConsumption} != $expectedWaterConsumption',
      ));
    }

    final expectedWaterAmount = bill.waterConsumption * bill.waterRatePerUnit;
    if ((bill.waterAmount - expectedWaterAmount).abs() > 0.01) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'waterAmount',
        message: 'Amount mismatch: ${bill.waterAmount} != $expectedWaterAmount',
      ));
    }

    // Total calculation
    final expectedSubtotal = bill.baseRent +
        bill.electricityAmount +
        bill.waterAmount +
        bill.trashAmount +
        bill.wifiAmount +
        bill.parkingAmount +
        bill.additionalChargesAmount;
    if ((bill.subtotal - expectedSubtotal).abs() > 0.01) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'subtotal',
        message: 'Subtotal mismatch: ${bill.subtotal} != $expectedSubtotal',
      ));
    }

    final expectedTotal = bill.subtotal - bill.discount + bill.lateFee;
    if ((bill.total - expectedTotal).abs() > 0.01) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'total',
        message: 'Total mismatch: ${bill.total} != $expectedTotal (subtotal - discount + lateFee)',
      ));
    }

    final expectedBalance = bill.total - bill.amountPaid;
    if ((bill.balance - expectedBalance).abs() > 0.01) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'balance',
        message: 'Balance mismatch: ${bill.balance} != $expectedBalance (total - amountPaid)',
      ));
    }
  }

  void _validateBillDates(ImportBillData bill, int rowNumber, List<ValidationError> errors) {
    if (bill.endDate.isBefore(bill.startDate)) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'endDate',
        message: 'End date must be after start date',
      ));
    }

    // Due date should be 7 days after end date (per project rules)
    final expectedDueDate = bill.endDate.add(const Duration(days: 7));
    if (bill.dueDate.difference(expectedDueDate).inDays.abs() > 1) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'dueDate',
        message: 'Due date should be ~7 days after end date',
      ));
    }
  }

  void _validateMeterReadings(ImportBillData bill, int rowNumber, List<ValidationError> errors) {
    if (bill.electricityCurrentReading < bill.electricityPreviousReading) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'electricityCurrentReading',
        message: 'Current reading cannot be less than previous reading',
      ));
    }

    if (bill.waterCurrentReading < bill.waterPreviousReading) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'waterCurrentReading',
        message: 'Current reading cannot be less than previous reading',
      ));
    }

    // Consumption sanity check (e.g., electricity >500 kWh per month is unusual)
    if (bill.electricityConsumption > 1000) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'electricityConsumption',
        message: 'Warning: Very high consumption (${bill.electricityConsumption} kWh)',
      ));
    }

    if (bill.waterConsumption > 100) {
      errors.add(ValidationError(
        rowNumber: rowNumber,
        field: 'waterConsumption',
        message: 'Warning: Very high consumption (${bill.waterConsumption} m)',
      ));
    }
  }

  void _validateMeterContinuity(List<ImportBillData> userBills, List<ValidationError> errors) {
    if (userBills.length < 2) return;

    for (var i = 1; i < userBills.length; i++) {
      final prevBill = userBills[i - 1];
      final currBill = userBills[i];

      // Check electricity continuity
      if ((currBill.electricityPreviousReading - prevBill.electricityCurrentReading).abs() > 0.01) {
        final rowNumber = i + 2;
        errors.add(ValidationError(
          rowNumber: rowNumber,
          field: 'electricityPreviousReading',
          message: 'Electricity reading continuity broken for ${currBill.userName}: '
              'previous reading ${currBill.electricityPreviousReading} != '
              'last month current ${prevBill.electricityCurrentReading}',
        ));
      }

      // Check water continuity
      if ((currBill.waterPreviousReading - prevBill.waterCurrentReading).abs() > 0.01) {
        final rowNumber = i + 2;
        errors.add(ValidationError(
          rowNumber: rowNumber,
          field: 'waterPreviousReading',
          message: 'Water reading continuity broken for ${currBill.userName}: '
              'previous reading ${currBill.waterPreviousReading} != '
              'last month current ${prevBill.waterCurrentReading}',
        ));
      }
    }
  }

  Future<void> _validateFirebaseReferences(List<ImportBillData> bills, List<ValidationError> errors) async {
    // Get unique user IDs, property IDs
    final userIds = bills.map((b) => b.userId).toSet();
    final propertyIds = bills.map((b) => b.propertyId).toSet();

    // Check users exist
    for (var userId in userIds) {
      try {
        final userDoc = await _firestore.collection('Users').doc(userId).get();
        if (!userDoc.exists) {
          errors.add(ValidationError(
            rowNumber: 0,
            field: 'userId',
            message: 'User $userId does not exist in Firebase',
          ));
        }
      } catch (e) {
        errors.add(ValidationError(
          rowNumber: 0,
          field: 'userId',
          message: 'Failed to verify user $userId: $e',
        ));
      }
    }

    // Check properties and units exist
    for (var propertyId in propertyIds) {
      try {
        final propDoc = await _firestore.collection('Property').doc(propertyId).get();
        if (!propDoc.exists) {
          errors.add(ValidationError(
            rowNumber: 0,
            field: 'propertyId',
            message: 'Property $propertyId does not exist',
          ));
        }
      } catch (e) {
        errors.add(ValidationError(
          rowNumber: 0,
          field: 'propertyId',
          message: 'Failed to verify property $propertyId: $e',
        ));
      }
    }
  }
}
