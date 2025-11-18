import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/consumption_models.dart';
import '../../../core/utils/app_logger.dart';

/// Repository for consumption data operations
class ConsumptionRepository {
  static ConsumptionRepository? _instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ConsumptionRepository._();

  static ConsumptionRepository get instance {
    _instance ??= ConsumptionRepository._();
    return _instance!;
  }

  /// Fetch tenant's consumption history for a specific utility
  Future<ConsumptionSummary> getTenantConsumption({
    required String userId,
    required String utilityType, // "electricity" or "water"
    int months = 6,
  }) async {
    try {
      AppLogger.debug(' Fetching $utilityType consumption for user: $userId (last $months months)');

      // Query bills for this user, ordered by billing period (newest first)
      final querySnapshot = await _firestore
          .collection('Bills')
          .where('userId', isEqualTo: userId)
          .orderBy('billingPeriod.year', descending: true)
          .orderBy('billingPeriod.month', descending: true)
          .limit(months * 2) // Get more than needed in case some bills are missing utility data
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.debug(' No bills found for user $userId');
        return ConsumptionSummary.empty(utilityType);
      }

      final List<ConsumptionDataPoint> dataPoints = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final utilities = data['utilities'] as Map<String, dynamic>?;
        
        if (utilities == null) continue;

        final utilityData = utilities[utilityType] as Map<String, dynamic>?;
        if (utilityData == null) continue;

        final billingPeriod = data['billingPeriod'] as Map<String, dynamic>?;
        if (billingPeriod == null) continue;

        final month = billingPeriod['month'] as int;
        final year = billingPeriod['year'] as int;
        final unit = utilityType == 'electricity' ? 'kWh' : 'm³';

        final dataPoint = ConsumptionDataPoint.fromBillUtility(
          utilityData: utilityData,
          month: month,
          year: year,
          unit: unit,
          tenantId: userId,
          billId: doc.id,
        );

        dataPoints.add(dataPoint);
      }

      AppLogger.debug(' Found ${dataPoints.length} consumption data points');

      return ConsumptionSummary.fromDataPoints(
        utilityType: utilityType,
        dataPoints: dataPoints,
        monthsCount: months,
      );
    } catch (e) {
      AppLogger.error(' Error fetching tenant consumption: $e');
      return ConsumptionSummary.empty(utilityType);
    }
  }

  /// Stream tenant's consumption (real-time updates)
  Stream<ConsumptionSummary> streamTenantConsumption({
    required String userId,
    required String utilityType,
    int months = 6,
  }) {
    AppLogger.debug(' Streaming $utilityType consumption for user: $userId');

    return _firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .orderBy('billingPeriod.year', descending: true)
        .orderBy('billingPeriod.month', descending: true)
        .limit(months * 2)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return ConsumptionSummary.empty(utilityType);
      }

      final List<ConsumptionDataPoint> dataPoints = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final utilities = data['utilities'] as Map<String, dynamic>?;
        
        if (utilities == null) continue;

        final utilityData = utilities[utilityType] as Map<String, dynamic>?;
        if (utilityData == null) continue;

        final billingPeriod = data['billingPeriod'] as Map<String, dynamic>?;
        if (billingPeriod == null) continue;

        final month = billingPeriod['month'] as int;
        final year = billingPeriod['year'] as int;
        final unit = utilityType == 'electricity' ? 'kWh' : 'm³';

        final dataPoint = ConsumptionDataPoint.fromBillUtility(
          utilityData: utilityData,
          month: month,
          year: year,
          unit: unit,
          tenantId: userId,
          billId: doc.id,
        );

        dataPoints.add(dataPoint);
      }

      return ConsumptionSummary.fromDataPoints(
        utilityType: utilityType,
        dataPoints: dataPoints,
        monthsCount: months,
      );
    });
  }

  /// Fetch unit's consumption history (all tenants, admin view)
  Future<UnitConsumptionHistory> getUnitConsumption({
    required String unitId,
    required String utilityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug(' Fetching unit consumption: unitId=$unitId, utilityType=$utilityType');

      // Query all bills for this unit
      Query query = _firestore
          .collection('Bills')
          .where('unitId', isEqualTo: unitId);

      // Add date filters if provided
      if (startDate != null) {
        query = query.where('billingPeriod.startDate', isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('billingPeriod.endDate', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final querySnapshot = await query
          .orderBy('billingPeriod.year', descending: false)
          .orderBy('billingPeriod.month', descending: false)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.debug(' No bills found for unit $unitId');
        return UnitConsumptionHistory.empty(
          unitId: unitId,
          propertyId: '', // Will be filled from first bill if available
          utilityType: utilityType,
        );
      }

      // Convert documents to maps
      final bills = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      final propertyId = bills.isNotEmpty 
          ? (bills.first['propertyId'] as String? ?? '') 
          : '';

      AppLogger.debug(' Found ${bills.length} bills for unit');

      return UnitConsumptionHistory.fromBills(
        unitId: unitId,
        propertyId: propertyId,
        utilityType: utilityType,
        bills: bills,
      );
    } catch (e) {
      AppLogger.error(' Error fetching unit consumption: $e');
      return UnitConsumptionHistory.empty(
        unitId: unitId,
        propertyId: '',
        utilityType: utilityType,
      );
    }
  }

  /// Get consumption comparison (tenant vs unit average)
  Future<Map<String, dynamic>> getConsumptionComparison({
    required String userId,
    required String unitId,
    required String utilityType,
    int months = 6,
  }) async {
    try {
      AppLogger.debug(' Comparing tenant vs unit consumption');

      // Get tenant's consumption
      final tenantSummary = await getTenantConsumption(
        userId: userId,
        utilityType: utilityType,
        months: months,
      );

      // Get unit's historical consumption
      final unitHistory = await getUnitConsumption(
        unitId: unitId,
        utilityType: utilityType,
      );

      // Calculate unit average (excluding current tenant if needed)
      double unitAverage = 0.0;
      int unitMonthsCount = 0;

      for (var reading in unitHistory.allReadings) {
        if (reading.tenantId != userId) {
          unitAverage += reading.value;
          unitMonthsCount++;
        }
      }

      if (unitMonthsCount > 0) {
        unitAverage = unitAverage / unitMonthsCount;
      }

      // Calculate difference percentage
      double differencePercentage = 0.0;
      if (unitAverage > 0 && tenantSummary.averageConsumption > 0) {
        differencePercentage = ((tenantSummary.averageConsumption - unitAverage) / unitAverage) * 100;
      }

      return {
        'tenantAverage': tenantSummary.averageConsumption,
        'unitAverage': unitAverage,
        'differencePercentage': differencePercentage,
        'isAboveAverage': tenantSummary.averageConsumption > unitAverage,
        'unitMonthsCount': unitMonthsCount,
      };
    } catch (e) {
      AppLogger.error(' Error comparing consumption: $e');
      return {
        'tenantAverage': 0.0,
        'unitAverage': 0.0,
        'differencePercentage': 0.0,
        'isAboveAverage': false,
        'unitMonthsCount': 0,
      };
    }
  }

  /// Get latest consumption reading for a tenant
  Future<ConsumptionDataPoint?> getLatestReading({
    required String userId,
    required String utilityType,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('Bills')
          .where('userId', isEqualTo: userId)
          .orderBy('billingPeriod.year', descending: true)
          .orderBy('billingPeriod.month', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final data = querySnapshot.docs.first.data();
      final utilities = data['utilities'] as Map<String, dynamic>?;
      
      if (utilities == null) return null;

      final utilityData = utilities[utilityType] as Map<String, dynamic>?;
      if (utilityData == null) return null;

      final billingPeriod = data['billingPeriod'] as Map<String, dynamic>?;
      if (billingPeriod == null) return null;

      final month = billingPeriod['month'] as int;
      final year = billingPeriod['year'] as int;
      final unit = utilityType == 'electricity' ? 'kWh' : 'm³';

      return ConsumptionDataPoint.fromBillUtility(
        utilityData: utilityData,
        month: month,
        year: year,
        unit: unit,
        tenantId: userId,
        billId: querySnapshot.docs.first.id,
      );
    } catch (e) {
      AppLogger.error(' Error fetching latest reading: $e');
      return null;
    }
  }
}
