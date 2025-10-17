import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../models/import_models.dart';

/// Service for parsing both CSV and JSON files into import data models
class FileParserService {
  /// Parse bills file from bytes - auto-detects CSV or JSON format
  Future<List<ImportBillData>> parseBillsFile(Uint8List fileBytes, String fileName) async {
    if (fileName.toLowerCase().endsWith('.json')) {
      return _parseBillsJSON(fileBytes);
    } else if (fileName.toLowerCase().endsWith('.csv')) {
      return _parseBillsCSV(fileBytes);
    } else {
      throw Exception('Unsupported file format. Use .csv or .json files.');
    }
  }

  /// Parse payments file from bytes - auto-detects CSV or JSON format
  Future<List<ImportPaymentData>> parsePaymentsFile(Uint8List fileBytes, String fileName) async {
    if (fileName.toLowerCase().endsWith('.json')) {
      return _parsePaymentsJSON(fileBytes);
    } else if (fileName.toLowerCase().endsWith('.csv')) {
      return _parsePaymentsCSV(fileBytes);
    } else {
      throw Exception('Unsupported file format. Use .csv or .json files.');
    }
  }

  // ==================== JSON PARSERS ====================

  /// Parse bills from JSON file
  Future<List<ImportBillData>> _parseBillsJSON(Uint8List fileBytes) async {
    try {
      final contents = utf8.decode(fileBytes);
      final jsonData = jsonDecode(contents);

      if (jsonData is! Map<String, dynamic> || !jsonData.containsKey('bills')) {
        throw Exception('Invalid JSON format. Expected object with "bills" array.');
      }

      final billsArray = jsonData['bills'];
      if (billsArray is! List) {
        throw Exception('"bills" field must be an array.');
      }

      if (billsArray.isEmpty) {
        throw Exception('No bills found in JSON file.');
      }

      final bills = <ImportBillData>[];
      for (var i = 0; i < billsArray.length; i++) {
        try {
          final billJson = billsArray[i];
          if (billJson is! Map<String, dynamic>) {
            throw Exception('Bill at index $i is not a valid object.');
          }
          bills.add(_parseBillFromJson(billJson, i + 1));
        } catch (e) {
          throw Exception('Error parsing bill at index ${i + 1}: $e');
        }
      }

      return bills;
    } catch (e) {
      throw Exception('Failed to parse bills JSON: $e');
    }
  }

  /// Parse payments from JSON file
  Future<List<ImportPaymentData>> _parsePaymentsJSON(Uint8List fileBytes) async {
    try {
      final contents = utf8.decode(fileBytes);
      final jsonData = jsonDecode(contents);

      if (jsonData is! Map<String, dynamic> || !jsonData.containsKey('payments')) {
        throw Exception('Invalid JSON format. Expected object with "payments" array.');
      }

      final paymentsArray = jsonData['payments'];
      if (paymentsArray is! List) {
        throw Exception('"payments" field must be an array.');
      }

      if (paymentsArray.isEmpty) {
        throw Exception('No payments found in JSON file.');
      }

      final payments = <ImportPaymentData>[];
      for (var i = 0; i < paymentsArray.length; i++) {
        try {
          final paymentJson = paymentsArray[i];
          if (paymentJson is! Map<String, dynamic>) {
            throw Exception('Payment at index $i is not a valid object.');
          }
          payments.add(_parsePaymentFromJson(paymentJson, i + 1));
        } catch (e) {
          throw Exception('Error parsing payment at index ${i + 1}: $e');
        }
      }

      return payments;
    } catch (e) {
      throw Exception('Failed to parse payments JSON: $e');
    }
  }

  ImportBillData _parseBillFromJson(Map<String, dynamic> json, int index) {
    return ImportBillData(
      userId: _getJsonString(json, 'userId'),
      userEmail: _getJsonString(json, 'userEmail'),
      userName: _getJsonString(json, 'userName'),
      unitId: _getJsonString(json, 'unitId'),
      propertyId: _getJsonString(json, 'propertyId'),
      billingMonth: _getJsonInt(json, 'billingMonth'),
      billingYear: _getJsonInt(json, 'billingYear'),
      startDate: _getJsonDate(json, 'startDate'),
      endDate: _getJsonDate(json, 'endDate'),
      dueDate: _getJsonDate(json, 'dueDate'),
      baseRent: _getJsonDouble(json, 'baseRent'),
      electricityPreviousReading: _getJsonDouble(json, 'electricityPreviousReading'),
      electricityCurrentReading: _getJsonDouble(json, 'electricityCurrentReading'),
      electricityConsumption: _getJsonDouble(json, 'electricityConsumption'),
      electricityRatePerUnit: _getJsonDouble(json, 'electricityRatePerUnit'),
      electricityAmount: _getJsonDouble(json, 'electricityAmount'),
      electricityMeterNumber: _getJsonString(json, 'electricityMeterNumber'),
      electricityReadingDate: _getJsonDate(json, 'electricityReadingDate'),
      waterPreviousReading: _getJsonDouble(json, 'waterPreviousReading'),
      waterCurrentReading: _getJsonDouble(json, 'waterCurrentReading'),
      waterConsumption: _getJsonDouble(json, 'waterConsumption'),
      waterRatePerUnit: _getJsonDouble(json, 'waterRatePerUnit'),
      waterAmount: _getJsonDouble(json, 'waterAmount'),
      waterMeterNumber: _getJsonString(json, 'waterMeterNumber'),
      waterReadingDate: _getJsonDate(json, 'waterReadingDate'),
      trashAmount: _getJsonDouble(json, 'trashAmount'),
      wifiAmount: _getJsonDouble(json, 'wifiAmount'),
      parkingAmount: _getJsonDouble(json, 'parkingAmount'),
      additionalChargesAmount: _getJsonDouble(json, 'additionalChargesAmount'),
      additionalChargesDescription: _getJsonString(json, 'additionalChargesDescription'),
      subtotal: _getJsonDouble(json, 'subtotal'),
      discount: _getJsonDouble(json, 'discount'),
      discountReason: _getJsonString(json, 'discountReason'),
      lateFee: _getJsonDouble(json, 'lateFee'),
      lateFeeWeeks: _getJsonInt(json, 'lateFeeWeeks'),
      total: _getJsonDouble(json, 'total'),
      isPaid: _getJsonBool(json, 'isPaid'),
      amountPaid: _getJsonDouble(json, 'amountPaid'),
      balance: _getJsonDouble(json, 'balance'),
    );
  }

  ImportPaymentData _parsePaymentFromJson(Map<String, dynamic> json, int index) {
    return ImportPaymentData(
      paymentId: _getJsonString(json, 'paymentId'),
      billId: _getJsonString(json, 'billId'),
      userId: _getJsonString(json, 'userId'),
      paymentDate: _getJsonDate(json, 'paymentDate'),
      amount: _getJsonDouble(json, 'amount'),
      paymentMethod: _getJsonString(json, 'paymentMethod'),
      referenceNumber: _getJsonString(json, 'referenceNumber'),
      proofOfPaymentUrl: _getJsonString(json, 'proofOfPaymentUrl'),
      status: _getJsonString(json, 'status'),
      verifiedBy: _getJsonString(json, 'verifiedBy'),
      verifiedAt: _getJsonDate(json, 'verifiedAt'),
      notes: _getJsonString(json, 'notes'),
      allocRent: _getJsonDouble(json, 'allocRent'),
      allocElectricity: _getJsonDouble(json, 'allocElectricity'),
      allocWater: _getJsonDouble(json, 'allocWater'),
      allocTrash: _getJsonDouble(json, 'allocTrash'),
      allocWifi: _getJsonDouble(json, 'allocWifi'),
      allocParking: _getJsonDouble(json, 'allocParking'),
      allocAdditional: _getJsonDouble(json, 'allocAdditional'),
    );
  }

  // ==================== CSV PARSERS ====================

  /// Parse bills CSV file from bytes
  Future<List<ImportBillData>> _parseBillsCSV(Uint8List fileBytes) async {
    try {
      final contents = utf8.decode(fileBytes);
      final rows = const CsvToListConverter().convert(contents, shouldParseNumbers: false);

      if (rows.isEmpty || rows.length < 2) {
        throw Exception('CSV file is empty or has no data rows');
      }

      final dataRows = rows.skip(1);
      final bills = <ImportBillData>[];

      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows.elementAt(i);
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        try {
          bills.add(_parseBillRow(row, i + 2));
        } catch (e) {
          throw Exception('Error parsing bill row : $e');
        }
      }

      return bills;
    } catch (e) {
      throw Exception('Failed to parse bills CSV: $e');
    }
  }

  /// Parse payments CSV file from bytes
  Future<List<ImportPaymentData>> _parsePaymentsCSV(Uint8List fileBytes) async {
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
          throw Exception('Error parsing payment row : $e');
        }
      }

      return payments;
    } catch (e) {
      throw Exception('Failed to parse payments CSV: $e');
    }
  }

  ImportBillData _parseBillRow(List<dynamic> row, int rowNumber) {
    if (row.length < 39) {
      throw Exception('Row has  columns, expected 39');
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

  ImportPaymentData _parsePaymentRow(List<dynamic> row, int rowNumber) {
    if (row.length < 19) {
      throw Exception('Row has  columns, expected 19');
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

  // ==================== JSON HELPER METHODS ====================

  String _getJsonString(Map<String, dynamic> json, String key) {
    return json[key]?.toString().trim() ?? '';
  }

  int _getJsonInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String && value.trim().isEmpty) return 0;
    try {
      return int.parse(value.toString());
    } catch (e) {
      throw Exception('Invalid integer for $key: $value');
    }
  }

  double _getJsonDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String && value.trim().isEmpty) return 0.0;
    try {
      return double.parse(value.toString());
    } catch (e) {
      throw Exception('Invalid number for $key: $value');
    }
  }

  DateTime _getJsonDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value.toString().trim().isEmpty) {
      throw Exception('Date field $key is required but empty');
    }
    try {
      return DateTime.parse(value.toString().trim());
    } catch (e) {
      throw Exception('Invalid date format for $key: $value. Expected YYYY-MM-DD or ISO8601');
    }
  }

  bool _getJsonBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return false;
    if (value is bool) return value;
    final str = value.toString().trim().toLowerCase();
    return str == 'true' || str == 'yes' || str == '1';
  }

  // ==================== CSV HELPER METHODS ====================

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
