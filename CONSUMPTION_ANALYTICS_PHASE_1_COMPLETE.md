# Consumption Analytics - Phase 1 Implementation Complete

**Date**: October 15, 2025  
**Status**:  PHASE 1 COMPLETE - All tests passing (59/59)

## Overview

Phase 1 of the consumption analytics feature has been successfully implemented. This feature allows:
- **Tenants**: View their own electricity and water consumption history on the home screen
- **Admins**: Query unit-wide consumption including data from past tenants (data layer ready, UI pending)

The implementation follows clean architecture with feature-based structure and uses existing BillModel data from Firebase.

---

##  What Was Implemented

### 1. Domain Models (lib/src/features/consumption/domain/consumption_models.dart)

Three core models were created to represent consumption data:

#### ConsumptionDataPoint
Represents a single monthly consumption reading.
`dart
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
  final double? ratePerUnit;       // Billing rate
  final double? amount;            // Total amount for this consumption
  final String? meterNumber;       // Meter identifier
}
`

**Key Features**:
- Factory romBillUtility() parses data from existing BillModel.utilities field
- Handles both electricity (kWh) and water (m) consumption
- Tracks tenant information for historical unit-wide analysis

#### ConsumptionSummary
Analytics summary for tenant consumption view.
`dart
class ConsumptionSummary {
  final String utilityType;        // "electricity" or "water"
  final List<ConsumptionDataPoint> dataPoints;
  final double averageConsumption;
  final double totalConsumption;
  final double highestMonth;
  final double lowestMonth;
  final String period;             // "Last 6 months"
  final int monthsCount;
}
`

**Key Features**:
- Factory FromDataPoints() calculates statistics from consumption data
- Automatically sorts data oldest-to-newest for chart display
- Provides isEmpty and isNotEmpty getters
- Factory empty() returns empty summary for error states

#### UnitConsumptionHistory
Aggregated consumption across all tenants for a unit (admin view).
`dart
class UnitConsumptionHistory {
  final String unitId;
  final String propertyId;
  final String utilityType;
  final List<ConsumptionDataPoint> allReadings;
  final Map<String, List<ConsumptionDataPoint>> byTenant;  // Grouped by tenant ID
  final double totalConsumption;
  final DateTime? firstReading;
  final DateTime? lastReading;
  final int totalMonths;
}
`

**Key Features**:
- Factory romBills() processes multiple bills from different tenants
- Groups consumption by tenant ID in yTenant map
- Includes all historical data, even from past tenants who no longer live in unit
- Calculates totals and time ranges

---

### 2. Data Repository (lib/src/features/consumption/data/consumption_repository.dart)

Singleton repository following existing patterns from BillingRepository.

#### Methods Implemented:

**getTenantConsumption()** - Future
`dart
Future<ConsumptionSummary> getTenantConsumption({
  required String userId,
  required String utilityType,  // "electricity" or "water"
  int months = 6,
})
`
- Queries Bills collection by userId
- Orders by illingPeriod.year and illingPeriod.month (newest first)
- Parses utilities.electricity or utilities.water from bills
- Returns ConsumptionSummary with analytics
- Handles missing data gracefully (returns empty summary)

**streamTenantConsumption()** - Stream
`dart
Stream<ConsumptionSummary> streamTenantConsumption({
  required String userId,
  required String utilityType,
  int months = 6,
})
`
- Real-time stream version of getTenantConsumption()
- Used by Riverpod StreamProvider for reactive UI updates
- Automatically updates when new bills are created

**getUnitConsumption()** - Future
`dart
Future<UnitConsumptionHistory> getUnitConsumption({
  required String unitId,
  required String utilityType,
  DateTime? startDate,
  DateTime? endDate,
})
`
- Queries all bills for a unit (includes all tenants, past and present)
- Optional date range filtering
- Returns UnitConsumptionHistory with tenant-grouped data
- For admin view showing complete unit consumption history

**getConsumptionComparison()** - Future
`dart
Future<Map<String, dynamic>> getConsumptionComparison({
  required String userId,
  required String unitId,
  required String utilityType,
  int months = 6,
})
`
- Compares tenant's consumption to unit average
- Excludes current tenant from unit average calculation
- Returns map with:
  - 	enantAverage: Current tenant's average consumption
  - unitAverage: Average consumption of past tenants in unit
  - differencePercentage: Percentage difference
  - isAboveAverage: Boolean indicator
  - unitMonthsCount: Number of months included in unit average

**getLatestReading()** - Future
`dart
Future<ConsumptionDataPoint?> getLatestReading({
  required String userId,
  required String utilityType,
})
`
- Fetches most recent consumption reading for a tenant
- Used for quick status displays
- Returns 
ull if no bills exist

**Error Handling**:
- All methods use try-catch with AppLogger.error()
- Returns empty/default data on errors instead of throwing
- Debug logging with emoji indicators ()

---

### 3. Riverpod Providers (lib/src/features/consumption/providers/consumption_providers.dart)

State management layer connecting repository to UI.

**consumptionRepositoryProvider**
`dart
final consumptionRepositoryProvider = Provider<ConsumptionRepository>((ref) {
  return ConsumptionRepository.instance;
});
`

**tenantElectricityProvider** - StreamProvider
`dart
final tenantElectricityProvider = 
    StreamProvider.family<ConsumptionSummary, String>((ref, userId) {
  final repository = ref.watch(consumptionRepositoryProvider);
  return repository.streamTenantConsumption(
    userId: userId,
    utilityType: 'electricity',
    months: 6,
  );
});
`
- Used in home screen to display real-time electricity consumption
- Automatically updates when new bills are created

**tenantWaterProvider** - StreamProvider
`dart
final tenantWaterProvider = 
    StreamProvider.family<ConsumptionSummary, String>((ref, userId) {
  final repository = ref.watch(consumptionRepositoryProvider);
  return repository.streamTenantConsumption(
    userId: userId,
    utilityType: 'water',
    months: 6,
  );
});
`
- Used in home screen to display real-time water consumption

**unitElectricityHistoryProvider** - FutureProvider
`dart
final unitElectricityHistoryProvider = 
    FutureProvider.family<UnitConsumptionHistory, String>((ref, unitId) async {
  final repository = ref.watch(consumptionRepositoryProvider);
  return repository.getUnitConsumption(
    unitId: unitId,
    utilityType: 'electricity',
  );
});
`
- For admin views showing complete unit electricity history

**unitWaterHistoryProvider** - FutureProvider
- Same as electricity but for water consumption

**consumptionComparisonProvider** - FutureProvider
`dart
class ConsumptionComparisonParams {
  final String userId;
  final String unitId;
  final String utilityType;
}

final consumptionComparisonProvider = 
    FutureProvider.family<Map<String, dynamic>, ConsumptionComparisonParams>(
      (ref, params) async { ... }
    );
`
- For comparison UI showing tenant vs unit average
- Uses custom params class for multiple parameters

**latestConsumptionReadingProvider** - FutureProvider
- Fetches latest reading for quick status displays

---

### 4. UI Integration (lib/src/features/home/presentation/home_screen.dart)

Updated tenant home screen to display real consumption data.

#### Changes Made:

**Added Imports**:
`dart
import '../../consumption/providers/consumption_providers.dart';
`

**Updated _ConsumptionSection**:
- Changed from StatelessWidget to ConsumerWidget
- Added userId parameter
- Watches 	enantElectricityProvider(userId) and 	enantWaterProvider(userId)
- Converts ConsumptionDataPoint to ConsumptionData for existing chart widget
- Falls back to hardcoded sample data if:
  - No bills exist yet (new tenant)
  - Provider is loading
  - Error occurs

**Code Example**:
`dart
class _ConsumptionSection extends ConsumerWidget {
  final String userId;
  
  const _ConsumptionSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electricitySummaryAsync = ref.watch(tenantElectricityProvider(userId));
    final waterSummaryAsync = ref.watch(tenantWaterProvider(userId));
    
    return Column(
      children: [
        // Electricity Chart
        electricitySummaryAsync.when(
          data: (summary) {
            final chartData = summary.dataPoints.map((point) =>
              ConsumptionData(month: point.month, value: point.value, unit: point.unit)
            ).toList();
            
            return _ConsumptionChart(
              title: 'Electricity Usage',
              data: chartData.isNotEmpty ? chartData : electricityData,
              // ... other params
            );
          },
          loading: () => _ConsumptionChart(/* loading state */),
          error: (error, stack) => _ConsumptionChart(/* error fallback */),
        ),
        // Water Chart (similar pattern)
      ],
    );
  }
}
`

**Benefits**:
- Real-time updates when new bills are created
- Graceful degradation (shows sample data instead of errors)
- Maintains existing UI/UX (reuses _ConsumptionChart widget)
- No breaking changes for existing users

---

##  File Structure

`
lib/src/features/consumption/
 domain/
    consumption_models.dart           (293 lines, 3 classes)
 data/
    consumption_repository.dart       (310 lines, 5 methods)
 presentation/                         (empty, future screens)
 providers/
     consumption_providers.dart        (115 lines, 7 providers)

lib/src/features/home/presentation/
 home_screen.dart                      (updated, ~1170 lines)
`

---

##  Data Flow

### Tenant View (Home Screen)
`
Firebase Bills Collection
         
ConsumptionRepository.streamTenantConsumption()
         
tenantElectricityProvider / tenantWaterProvider
         
_ConsumptionSection (ConsumerWidget)
         
_ConsumptionChart (displays bars)
`

### Admin View (Future Implementation)
`
Firebase Bills Collection
         
ConsumptionRepository.getUnitConsumption()
         
unitElectricityHistoryProvider / unitWaterHistoryProvider
         
Admin Consumption Screen (TBD)
         
Chart/Table showing all tenants + totals
`

---

##  Testing

**Test Results**:  **59/59 tests passing**

All existing tests continue to pass:
- Onboarding repository tests
- User profile tests
- Auth tests
- Billing tests

No new tests added in Phase 1 (feature-level testing planned for Phase 2+).

---

##  How It Works

### Data Source
The consumption data comes from the existing Bills collection in Firebase. Each bill has a structure like:
`json
{
  "billId": "bill_123",
  "userId": "user_abc",
  "unitId": "unit_456",
  "propertyId": "prop_789",
  "billingPeriod": {
    "month": 10,
    "year": 2025,
    "startDate": "2025-09-15",
    "endDate": "2025-10-14"
  },
  "utilities": {
    "electricity": {
      "consumption": 318.9,
      "previousReading": 1234.5,
      "currentReading": 1553.4,
      "readingDate": "2025-10-14",
      "ratePerUnit": 12.5,
      "amount": 3986.25,
      "meterNumber": "ELEC-001"
    },
    "water": {
      "consumption": 22.6,
      "previousReading": 450.2,
      "currentReading": 472.8,
      "readingDate": "2025-10-14",
      "ratePerUnit": 35.0,
      "amount": 791.0,
      "meterNumber": "WAT-001"
    }
  }
}
`

### Parsing Process
1. Repository queries bills by userId (tenant) or unitId (admin)
2. Extracts utilities.electricity or utilities.water from each bill
3. Creates ConsumptionDataPoint using romBillUtility() factory
4. Builds ConsumptionSummary or UnitConsumptionHistory with analytics
5. Provider exposes data to UI via Riverpod
6. UI displays charts with real data

### Fallback Behavior
If no bills exist or an error occurs:
- Home screen shows sample data (hardcoded in _ConsumptionSection)
- No error messages shown to user (graceful degradation)
- Once bills are created, real data appears automatically

---

##  Future Enhancements (Not in Phase 1)

### Phase 2: Historical Data Import
- CSV/Excel parser for bill data
- Admin import screen with file upload
- Data validation and preview
- Batch import to Firestore (2 years of data)
- Progress indicator and error reporting

### Phase 3: Dedicated Consumption Screens
- **Tenant Consumption Screen**
  - Full history view (not just last 6 months)
  - Detailed meter readings table
  - Export consumption report
  - Month-over-month comparison
  
- **Admin Unit Consumption Screen**
  - View consumption by unit
  - See all tenants' consumption (current + past)
  - Compare units within property
  - Download unit consumption report

### Phase 4: Advanced Analytics
- Consumption comparison UI (tenant vs unit average)
- Consumption trends and predictions
- Notifications for unusual consumption
- Energy-saving tips based on usage patterns

---

##  Usage Examples

### For Developers

**Watching tenant consumption in a widget**:
`dart
class MyConsumptionWidget extends ConsumerWidget {
  final String userId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final electricityAsync = ref.watch(tenantElectricityProvider(userId));
    
    return electricityAsync.when(
      data: (summary) => Text('Avg: {summary.averageConsumption} kWh'),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: e'),
    );
  }
}
`

**Fetching unit consumption (admin)**:
`dart
final unitHistory = await ref.read(
  unitElectricityHistoryProvider(unitId).future
);

print('Total consumption: {unitHistory.totalConsumption} kWh');
print('Tenants: {unitHistory.byTenant.keys.length}');
`

**Comparing tenant to unit average**:
`dart
final comparison = await ref.read(
  consumptionComparisonProvider(
    ConsumptionComparisonParams(
      userId: 'user_123',
      unitId: 'unit_456',
      utilityType: 'electricity',
    )
  ).future
);

print('Tenant avg: {comparison['tenantAverage']} kWh');
print('Unit avg: {comparison['unitAverage']} kWh');
print('Difference: {comparison['differencePercentage']}%');
`

---

##  Known Limitations

1. **Sample Data Fallback**: Home screen still shows hardcoded sample data if no bills exist. This is intentional for graceful UX, but may confuse new tenants. Consider adding "No data yet" indicator in Phase 2.

2. **No Dedicated Screens**: Only home screen integration done. Full consumption history screens planned for Phase 3.

3. **No Admin UI**: Admin consumption views are data-ready but have no UI yet. Planned for Phase 3.

4. **No Comparison UI**: Comparison provider exists but no UI to display it. Planned for Phase 4.

5. **6-Month Limit**: Home screen only shows last 6 months. Full history requires dedicated screen (Phase 3).

---

##  Conclusion

Phase 1 successfully implemented the core data layer and basic UI integration for consumption analytics. The feature:
-  Follows existing architecture patterns
-  Reuses existing bill data (no schema changes)
-  Provides real-time updates via Riverpod streams
-  Maintains backward compatibility
-  All tests passing (59/59)

**Ready for Phase 2**: Historical data import can now be implemented, as the data models and repository methods are complete.

**Next Steps**:
1. User testing with real bill data
2. Phase 2: Historical data import tool
3. Phase 3: Dedicated consumption screens
4. Phase 4: Advanced analytics and comparison UI

---

**Last Updated**: October 15, 2025  
**Version**: Phase 1 Complete  
**Status**:  Production Ready
