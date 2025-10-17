import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../models/import_models.dart';

/// Service for parsing CSV files into import data models
class CsvParserService {
  /// Parse bills CSV file from bytes
  Future<List<ImportBillData>> parseBillsCSV(Uint8List fileBytes) async {
    try {
      final contents = utf8.decode(fileBytes);
      final rows = const CsvToListConverter().convert(contents, shouldParseNumbers: false);

      if (rows.isEmpty || rows.length < 2) {
        throw Exception('CSV file is empty or has no data rows');
      }

      // Skip header row and parse data
      final dataRows = rows.skip(1);
      final bills = <ImportBillData>[];

      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows.elementAt(i);
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        try {
          bills.add(_parseBillRow(row, i + 2)); // +2 for header and 1-based index
        } catch (e) {
          throw Exception('Error parsing bill row ${i + 2}: $e');
        }
      }

      return bills;
    } catch (e) {
      throw Exception('Failed to parse bills CSV: $e');
    }
  }

  /// Parse payments CSV file from bytes
  Future<List<ImportPaymentData>> parsePaymentsCSV(Uint8List fileBytes) async {
    try {
      final contents = utf8.decode(fileBytes);
      final rows = const CsvToListConverter().convert(contents, shouldParseNumbers: false);

      if (rows.isEmpty || rows.length < 2) {
        throw Exception('CSV file is empty or has no data rows');
      }

      final dataRows = rows.skip(1);
      final payments = <ImportPaymentData>[];

      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows.elementAt(i);
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        try {
          payments.add(_parsePaymentRow(row, i + 2));
        } catch (e) {
          throw Exception('Error parsing payment row ${i + 2}: $e');
        }
      }

      return payments;
    } catch (e) {
      throw Exception('Failed to parse payments CSV: $e');
    }
  }

  /// Parse a single bill row
  ImportBillData _parseBillRow(List<dynamic> row, int rowNumber) {
    if (row.length < 39) {
      throw Exception('Row has ${row.length} columns, expected 39');
    }

    return ImportBillData(
      userId: _parseString(row[0], 'userId'),
      userEmail: _parseString(row[1], 'userEmail'),
      userName: _parseString(row[2], 'userName'),
      unitId: _parseString(row[3], 'unitId'),
      propertyId: _parseString(row[4], 'propertyId'),
      billingMonth: _parseInt(row[5], 'billingMonth'),
      billingYear: _parseInt(row[6], 'billingYear'),
      startDate: _parseDate(row[7], 'startDate'),
      endDate: _parseDate(row[8], 'endDate'),
      dueDate: _parseDate(row[9], 'dueDate'),
      baseRent: _parseDouble(row[10], 'baseRent'),
      electricityPreviousReading: _parseDouble(row[11], 'electricityPreviousReading'),
      electricityCurrentReading: _parseDouble(row[12], 'electricityCurrentReading'),
      electricityConsumption: _parseDouble(row[13], 'electricityConsumption'),
      electricityRatePerUnit: _parseDouble(row[14], 'electricityRatePerUnit'),
      electricityAmount: _parseDouble(row[15], 'electricityAmount'),
      electricityMeterNumber: _parseString(row[16], 'electricityMeterNumber'),
      electricityReadingDate: _parseDate(row[17], 'electricityReadingDate'),
      waterPreviousReading: _parseDouble(row[18], 'waterPreviousReading'),
      waterCurrentReading: _parseDouble(row[19], 'waterCurrentReading'),
      waterConsumption: _parseDouble(row[20], 'waterConsumption'),
      waterRatePerUnit: _parseDouble(row[21], 'waterRatePerUnit'),
      waterAmount: _parseDouble(row[22], 'waterAmount'),
      waterMeterNumber: _parseString(row[23], 'waterMeterNumber'),
      waterReadingDate: _parseDate(row[24], 'waterReadingDate'),
      trashAmount: _parseDouble(row[25], 'trashAmount'),
      wifiAmount: _parseDouble(row[26], 'wifiAmount'),
      parkingAmount: _parseDouble(row[27], 'parkingAmount'),
      additionalChargesAmount: _parseDouble(row[28], 'additionalChargesAmount'),
      additionalChargesDescription: _parseString(row[29], 'additionalChargesDescription'),
      subtotal: _parseDouble(row[30], 'subtotal'),
      discount: _parseDouble(row[31], 'discount'),
      discountReason: _parseString(row[32], 'discountReason'),
      lateFee: _parseDouble(row[33], 'lateFee'),
      lateFeeWeeks: _parseInt(row[34], 'lateFeeWeeks'),
      total: _parseDouble(row[35], 'total'),
      isPaid: _parseBool(row[36], 'isPaid'),
      amountPaid: _parseDouble(row[37], 'amountPaid'),
      balance: _parseDouble(row[38], 'balance'),
    );
  }

  /// Parse a single payment row
  ImportPaymentData _parsePaymentRow(List<dynamic> row, int rowNumber) {
    if (row.length < 19) {
      throw Exception('Row has ${row.length} columns, expected 19');
    }

    return ImportPaymentData(
      paymentId: _parseString(row[0], 'paymentId'),
      billId: _parseString(row[1], 'billId'),
      userId: _parseString(row[2], 'userId'),
      paymentDate: _parseDate(row[3], 'paymentDate'),
      amount: _parseDouble(row[4], 'amount'),
      paymentMethod: _parseString(row[5], 'paymentMethod'),
      referenceNumber: _parseString(row[6], 'referenceNumber'),
      proofOfPaymentUrl: _parseString(row[7], 'proofOfPaymentUrl'),
      status: _parseString(row[8], 'status'),
      verifiedBy: _parseString(row[9], 'verifiedBy'),
      verifiedAt: _parseDate(row[10], 'verifiedAt'),
      notes: _parseString(row[11], 'notes'),
      allocRent: _parseDouble(row[12], 'allocRent'),
      allocElectricity: _parseDouble(row[13], 'allocElectricity'),
      allocWater: _parseDouble(row[14], 'allocWater'),
      allocTrash: _parseDouble(row[15], 'allocTrash'),
      allocWifi: _parseDouble(row[16], 'allocWifi'),
      allocParking: _parseDouble(row[17], 'allocParking'),
      allocAdditional: _parseDouble(row[18], 'allocAdditional'),
    );
  }

  // Helper parsing methods
  String _parseString(dynamic value, String fieldName) {
    return value?.toString().trim() ?? '';
  }

  int _parseInt(dynamic value, String fieldName) {
    if (value == null || value.toString().trim().isEmpty) {
      return 0;
    }
    try {
      return int.parse(value.toString().trim());
    } catch (e) {
      throw Exception('Invalid integer for $fieldName: $value');
    }
  }

  double _parseDouble(dynamic value, String fieldName) {
    if (value == null || value.toString().trim().isEmpty) {
      return 0.0;
    }
    try {
      return double.parse(value.toString().trim());
    } catch (e) {
      throw Exception('Invalid number for $fieldName: $value');
    }
  }

  DateTime _parseDate(dynamic value, String fieldName) {
    if (value == null || value.toString().trim().isEmpty) {
      throw Exception('Date field $fieldName is required but empty');
    }
    try {
      return DateTime.parse(value.toString().trim());
    } catch (e) {
      throw Exception('Invalid date format for $fieldName: $value. Expected YYYY-MM-DD');
    }
  }

  bool _parseBool(dynamic value, String fieldName) {
    if (value == null || value.toString().trim().isEmpty) {
      return false;
    }
    final str = value.toString().trim().toLowerCase();
    return str == 'true' || str == 'yes' || str == '1';
  }
}
