/// Represents a single monthly consumption data point
class ConsumptionDataPoint {
  final String month;              // "Jan", "Feb", etc.
  final int monthNumber;           // 1-12
  final int year;                  // 2024, 2025
  final double value;              // Consumption amount
  final String unit;               // "kWh" or "m"
  final DateTime readingDate;      // When reading was taken
  final double previousReading;    // Previous meter reading
  final double currentReading;     // Current meter reading
  final String? tenantName;        // For unit-level view (past tenants)
  final String? tenantId;          // For filtering
  final String? billId;            // Reference to bill
  
  // Billing info (optional)
  final double? ratePerUnit;
  final double? amount;
  final String? meterNumber;

  const ConsumptionDataPoint({
    required this.month,
    required this.monthNumber,
    required this.year,
    required this.value,
    required this.unit,
    required this.readingDate,
    required this.previousReading,
    required this.currentReading,
    this.tenantName,
    this.tenantId,
    this.billId,
    this.ratePerUnit,
    this.amount,
    this.meterNumber,
  });

  /// Create from bill utility data
  factory ConsumptionDataPoint.fromBillUtility({
    required Map<String, dynamic> utilityData,
    required int month,
    required int year,
    required String unit,
    String? tenantName,
    String? tenantId,
    String? billId,
  }) {
    final consumption = (utilityData['consumption'] as num?)?.toDouble() ?? 0.0;
    final previousReading = (utilityData['previousReading'] as num?)?.toDouble() ?? 0.0;
    final currentReading = (utilityData['currentReading'] as num?)?.toDouble() ?? 0.0;
    final ratePerUnit = (utilityData['ratePerUnit'] as num?)?.toDouble();
    final amount = (utilityData['amount'] as num?)?.toDouble();
    final meterNumber = utilityData['meterNumber'] as String?;
    
    DateTime readingDate;
    try {
      readingDate = DateTime.parse(utilityData['readingDate'] as String);
    } catch (e) {
      readingDate = DateTime(year, month, 1);
    }

    return ConsumptionDataPoint(
      month: _getMonthName(month),
      monthNumber: month,
      year: year,
      value: consumption,
      unit: unit,
      readingDate: readingDate,
      previousReading: previousReading,
      currentReading: currentReading,
      tenantName: tenantName,
      tenantId: tenantId,
      billId: billId,
      ratePerUnit: ratePerUnit,
      amount: amount,
      meterNumber: meterNumber,
    );
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'monthNumber': monthNumber,
      'year': year,
      'value': value,
      'unit': unit,
      'readingDate': readingDate.toIso8601String(),
      'previousReading': previousReading,
      'currentReading': currentReading,
      'tenantName': tenantName,
      'tenantId': tenantId,
      'billId': billId,
      'ratePerUnit': ratePerUnit,
      'amount': amount,
      'meterNumber': meterNumber,
    };
  }
}

/// Consumption summary with analytics
class ConsumptionSummary {
  final String utilityType;        // "electricity" or "water"
  final List<ConsumptionDataPoint> dataPoints;
  final double averageConsumption;
  final double totalConsumption;
  final double highestMonth;
  final double lowestMonth;
  final String period;             // "Last 6 months", "Last 12 months"
  final int monthsCount;

  const ConsumptionSummary({
    required this.utilityType,
    required this.dataPoints,
    required this.averageConsumption,
    required this.totalConsumption,
    required this.highestMonth,
    required this.lowestMonth,
    required this.period,
    required this.monthsCount,
  });

  /// Create from list of data points
  factory ConsumptionSummary.fromDataPoints({
    required String utilityType,
    required List<ConsumptionDataPoint> dataPoints,
    int monthsCount = 6,
  }) {
    if (dataPoints.isEmpty) {
      return ConsumptionSummary(
        utilityType: utilityType,
        dataPoints: [],
        averageConsumption: 0.0,
        totalConsumption: 0.0,
        highestMonth: 0.0,
        lowestMonth: 0.0,
        period: 'Last ${monthsCount} months',
        monthsCount: monthsCount,
      );
    }

    // Sort by date (newest first)
    final sortedPoints = List<ConsumptionDataPoint>.from(dataPoints)
      ..sort((a, b) => b.readingDate.compareTo(a.readingDate));

    // Take only the requested number of months
    final recentPoints = sortedPoints.take(monthsCount).toList();

    final values = recentPoints.map((p) => p.value).toList();
    final total = values.fold(0.0, (sum, val) => sum + val);
    final average = total / recentPoints.length;
    final highest = values.reduce((a, b) => a > b ? a : b);
    final lowest = values.reduce((a, b) => a < b ? a : b);

    return ConsumptionSummary(
      utilityType: utilityType,
      dataPoints: recentPoints.reversed.toList(), // Oldest to newest for chart
      averageConsumption: average,
      totalConsumption: total,
      highestMonth: highest,
      lowestMonth: lowest,
      period: 'Last ${recentPoints.length} months',
      monthsCount: recentPoints.length,
    );
  }

  /// Empty summary
  factory ConsumptionSummary.empty(String utilityType) {
    return ConsumptionSummary(
      utilityType: utilityType,
      dataPoints: [],
      averageConsumption: 0.0,
      totalConsumption: 0.0,
      highestMonth: 0.0,
      lowestMonth: 0.0,
      period: 'No data',
      monthsCount: 0,
    );
  }

  bool get isEmpty => dataPoints.isEmpty;
  bool get isNotEmpty => dataPoints.isNotEmpty;
}

/// Unit consumption history (aggregated across tenants)
class UnitConsumptionHistory {
  final String unitId;
  final String propertyId;
  final String utilityType;
  final List<ConsumptionDataPoint> allReadings;
  final Map<String, List<ConsumptionDataPoint>> byTenant;
  final double totalConsumption;
  final DateTime? firstReading;
  final DateTime? lastReading;
  final int totalMonths;

  const UnitConsumptionHistory({
    required this.unitId,
    required this.propertyId,
    required this.utilityType,
    required this.allReadings,
    required this.byTenant,
    required this.totalConsumption,
    this.firstReading,
    this.lastReading,
    required this.totalMonths,
  });

  /// Create from list of bills
  factory UnitConsumptionHistory.fromBills({
    required String unitId,
    required String propertyId,
    required String utilityType,
    required List<Map<String, dynamic>> bills,
  }) {
    if (bills.isEmpty) {
      return UnitConsumptionHistory(
        unitId: unitId,
        propertyId: propertyId,
        utilityType: utilityType,
        allReadings: [],
        byTenant: {},
        totalConsumption: 0.0,
        totalMonths: 0,
      );
    }

    final List<ConsumptionDataPoint> allReadings = [];
    final Map<String, List<ConsumptionDataPoint>> byTenant = {};

    for (var bill in bills) {
      final utilities = bill['utilities'] as Map<String, dynamic>?;
      if (utilities == null) continue;

      final utilityData = utilities[utilityType] as Map<String, dynamic>?;
      if (utilityData == null) continue;

      final billingPeriod = bill['billingPeriod'] as Map<String, dynamic>?;
      if (billingPeriod == null) continue;

      final month = billingPeriod['month'] as int;
      final year = billingPeriod['year'] as int;
      final tenantName = bill['userName'] as String? ?? 'Unknown';
      final tenantId = bill['userId'] as String?;
      final billId = bill['billId'] as String?;

      final unit = utilityType == 'electricity' ? 'kWh' : 'm';

      final dataPoint = ConsumptionDataPoint.fromBillUtility(
        utilityData: utilityData,
        month: month,
        year: year,
        unit: unit,
        tenantName: tenantName,
        tenantId: tenantId,
        billId: billId,
      );

      allReadings.add(dataPoint);

      // Group by tenant
      if (tenantId != null) {
        byTenant.putIfAbsent(tenantId, () => []).add(dataPoint);
      }
    }

    // Sort all readings by date
    allReadings.sort((a, b) => a.readingDate.compareTo(b.readingDate));

    final total = allReadings.fold(0.0, (sum, point) => sum + point.value);
    final firstReading = allReadings.isNotEmpty ? allReadings.first.readingDate : null;
    final lastReading = allReadings.isNotEmpty ? allReadings.last.readingDate : null;

    return UnitConsumptionHistory(
      unitId: unitId,
      propertyId: propertyId,
      utilityType: utilityType,
      allReadings: allReadings,
      byTenant: byTenant,
      totalConsumption: total,
      firstReading: firstReading,
      lastReading: lastReading,
      totalMonths: allReadings.length,
    );
  }

  /// Empty history
  factory UnitConsumptionHistory.empty({
    required String unitId,
    required String propertyId,
    required String utilityType,
  }) {
    return UnitConsumptionHistory(
      unitId: unitId,
      propertyId: propertyId,
      utilityType: utilityType,
      allReadings: [],
      byTenant: {},
      totalConsumption: 0.0,
      totalMonths: 0,
    );
  }

  bool get isEmpty => allReadings.isEmpty;
  bool get isNotEmpty => allReadings.isNotEmpty;
}
