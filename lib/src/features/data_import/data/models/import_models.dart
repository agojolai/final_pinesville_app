/// Model for import result tracking
class ImportResult {
  final int totalRecords;
  final int successCount;
  final int errorCount;
  final List<String> errors;
  final Duration duration;

  ImportResult({
    required this.totalRecords,
    required this.successCount,
    required this.errorCount,
    required this.errors,
    required this.duration,
  });

  bool get hasErrors => errorCount > 0;
  bool get isSuccess => errorCount == 0 && successCount > 0;
  double get successRate => totalRecords > 0 ? (successCount / totalRecords) * 100 : 0;
}

/// Model for validation error
class ValidationError {
  final int rowNumber;
  final String field;
  final String message;

  ValidationError({
    required this.rowNumber,
    required this.field,
    required this.message,
  });

  String toDisplayString() => 'Row $rowNumber - $field: $message';
}

/// Model for parsed bill data from CSV
class ImportBillData {
  final String userId;
  final String userEmail;
  final String userName;
  final String unitId;
  final String propertyId;
  final int billingMonth;
  final int billingYear;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime dueDate;
  final double baseRent;
  final double electricityPreviousReading;
  final double electricityCurrentReading;
  final double electricityConsumption;
  final double electricityRatePerUnit;
  final double electricityAmount;
  final String electricityMeterNumber;
  final DateTime electricityReadingDate;
  final double waterPreviousReading;
  final double waterCurrentReading;
  final double waterConsumption;
  final double waterRatePerUnit;
  final double waterAmount;
  final String waterMeterNumber;
  final DateTime waterReadingDate;
  final double trashAmount;
  final double wifiAmount;
  final double parkingAmount;
  final double additionalChargesAmount;
  final String additionalChargesDescription;
  final double subtotal;
  final double discount;
  final String discountReason;
  final double lateFee;
  final int lateFeeWeeks;
  final double total;
  final bool isPaid;
  final double amountPaid;
  final double balance;

  ImportBillData({
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.unitId,
    required this.propertyId,
    required this.billingMonth,
    required this.billingYear,
    required this.startDate,
    required this.endDate,
    required this.dueDate,
    required this.baseRent,
    required this.electricityPreviousReading,
    required this.electricityCurrentReading,
    required this.electricityConsumption,
    required this.electricityRatePerUnit,
    required this.electricityAmount,
    required this.electricityMeterNumber,
    required this.electricityReadingDate,
    required this.waterPreviousReading,
    required this.waterCurrentReading,
    required this.waterConsumption,
    required this.waterRatePerUnit,
    required this.waterAmount,
    required this.waterMeterNumber,
    required this.waterReadingDate,
    required this.trashAmount,
    required this.wifiAmount,
    required this.parkingAmount,
    required this.additionalChargesAmount,
    required this.additionalChargesDescription,
    required this.subtotal,
    required this.discount,
    required this.discountReason,
    required this.lateFee,
    required this.lateFeeWeeks,
    required this.total,
    required this.isPaid,
    required this.amountPaid,
    required this.balance,
  });

  String get billId => 'BILL_${billingYear}_${billingMonth.toString().padLeft(2, '0')}_$userId';
}

/// Model for parsed payment data from CSV  
class ImportPaymentData {
  final String paymentId;
  final String billId;
  final String userId;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethod;
  final String referenceNumber;
  final String proofOfPaymentUrl;
  final String status;
  final String verifiedBy;
  final DateTime verifiedAt;
  final String notes;
  final double allocRent;
  final double allocElectricity;
  final double allocWater;
  final double allocTrash;
  final double allocWifi;
  final double allocParking;
  final double allocAdditional;

  ImportPaymentData({
    required this.paymentId,
    required this.billId,
    required this.userId,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.proofOfPaymentUrl,
    required this.status,
    required this.verifiedBy,
    required this.verifiedAt,
    required this.notes,
    required this.allocRent,
    required this.allocElectricity,
    required this.allocWater,
    required this.allocTrash,
    required this.allocWifi,
    required this.allocParking,
    required this.allocAdditional,
  });

  double get totalAllocations =>
      allocRent + allocElectricity + allocWater + allocTrash + allocWifi + allocParking + allocAdditional;
}

