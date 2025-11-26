# Consumption Analytics & Graphical Visualization - Enhancement Guide

**Date:** October 1, 2025  
**Purpose:** Add comprehensive consumption tracking and graphical visualization for both admins and tenants

---

## Overview

This enhancement adds **graphical consumption tracking** that allows:
-  **Admins**: View overall consumption per tenant, per unit, per property, per month
-  **Tenants**: View their own monthly consumption with comparison graphs
-  **Both**: Interactive charts showing electricity, water, and cost trends

---

## Database Structure (Already Exists )

### ConsumptionAnalytics Collection
**Path:** Users/{userId}/ConsumptionAnalytics/{year}

This collection is **already defined** in BILLING_DATABASE_STRUCTURE.md and includes:
-  Monthly breakdown (electricity, water consumption & costs)
-  Year summary statistics
-  Trend analysis (increasing, decreasing, stable)
-  Average calculations

---

## New Features to Add

### 1. Admin Dashboard - Consumption Overview

#### Admin Can View:
1. **Overall Consumption by Property**
   - Total electricity consumption across all units in a property
   - Total water consumption across all units in a property
   - Monthly trends per property
   
2. **Consumption by Unit**
   - Individual unit consumption comparison
   - Identify high consumers
   - Identify unusual consumption patterns
   
3. **Consumption by Tenant**
   - Track tenant consumption history
   - Compare current vs previous months
   - Identify billing anomalies

4. **Time Period Selection**
   - View by month, quarter, year
   - Compare different time periods
   - Export reports

---

### 2. Tenant Dashboard - Personal Consumption

#### Tenant Can View:
1. **Monthly Consumption Graph**
   - Line chart: Electricity consumption over time
   - Line chart: Water consumption over time
   - Bar chart: Monthly costs comparison
   
2. **Current vs Previous Month**
   - Percentage change indicators
   - Visual indicators (up arrow = increase, down arrow = decrease)
   
3. **Year-to-Date Summary**
   - Total consumption YTD
   - Average monthly consumption
   - Highest/lowest consumption months

4. **Cost Breakdown**
   - Pie chart: Bill composition (rent, electricity, water, other)
   - Stacked bar chart: Monthly bill breakdown

---

## Implementation Plan

### Phase 1: Database Queries & Aggregation

#### Step 1.1: Add Analytics Repository Methods

Create lib/src/features/billing/data/analytics_repository.dart:

\\\dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsRepository {
  final FirebaseFirestore firestore;
  
  AnalyticsRepository({required this.firestore});
  
  // ==================== TENANT ANALYTICS ====================
  
  /// Get consumption analytics for a specific user and year
  Future<ConsumptionAnalytics?> getUserConsumption(String userId, int year) async {
    final doc = await firestore
        .collection('Users')
        .doc(userId)
        .collection('ConsumptionAnalytics')
        .doc(year.toString())
        .get();
    
    if (!doc.exists) return null;
    return ConsumptionAnalytics.fromSnapshot(doc);
  }
  
  /// Stream consumption analytics for real-time updates
  Stream<ConsumptionAnalytics?> streamUserConsumption(String userId, int year) {
    return firestore
        .collection('Users')
        .doc(userId)
        .collection('ConsumptionAnalytics')
        .doc(year.toString())
        .snapshots()
        .map((doc) => doc.exists ? ConsumptionAnalytics.fromSnapshot(doc) : null);
  }
  
  /// Get multi-year consumption for historical comparison
  Future<List<ConsumptionAnalytics>> getUserConsumptionHistory(
    String userId,
    List<int> years,
  ) async {
    final List<ConsumptionAnalytics> analytics = [];
    
    for (final year in years) {
      final data = await getUserConsumption(userId, year);
      if (data != null) analytics.add(data);
    }
    
    return analytics;
  }
  
  // ==================== ADMIN ANALYTICS ====================
  
  /// Get all consumption for a specific property
  Future<Map<String, ConsumptionAnalytics>> getPropertyConsumption(
    String propertyId,
    int year,
  ) async {
    // Get all units in property
    final unitsSnapshot = await firestore
        .collection('Properties')
        .doc(propertyId)
        .collection('units')
        .where('rental.status', isEqualTo: 'occupied')
        .get();
    
    Map<String, ConsumptionAnalytics> propertyData = {};
    
    for (final unitDoc in unitsSnapshot.docs) {
      final tenantId = unitDoc.data()['rental']['tenantId'] as String?;
      if (tenantId != null) {
        final consumption = await getUserConsumption(tenantId, year);
        if (consumption != null) {
          propertyData[unitDoc.id] = consumption;
        }
      }
    }
    
    return propertyData;
  }
  
  /// Get consumption summary for all properties
  Future<PropertyConsumptionSummary> getAllPropertiesConsumption(
    int year,
    int month,
  ) async {
    final bills = await firestore
        .collection('Bills')
        .where('billingPeriod.year', isEqualTo: year)
        .where('billingPeriod.month', isEqualTo: month)
        .get();
    
    Map<String, PropertyStats> propertyStats = {};
    
    for (final doc in bills.docs) {
      final bill = BillModel.fromSnapshot(doc);
      final propertyId = bill.propertyId;
      
      if (!propertyStats.containsKey(propertyId)) {
        propertyStats[propertyId] = PropertyStats(
          propertyId: propertyId,
          totalElectricityConsumption: 0,
          totalWaterConsumption: 0,
          totalElectricityCost: 0,
          totalWaterCost: 0,
          unitCount: 0,
        );
      }
      
      propertyStats[propertyId]!.totalElectricityConsumption += bill.electricity.consumption;
      propertyStats[propertyId]!.totalWaterConsumption += bill.water.consumption;
      propertyStats[propertyId]!.totalElectricityCost += bill.electricity.amount;
      propertyStats[propertyId]!.totalWaterCost += bill.water.amount;
      propertyStats[propertyId]!.unitCount++;
    }
    
    return PropertyConsumptionSummary(
      year: year,
      month: month,
      properties: propertyStats,
    );
  }
  
  /// Get top consumers (highest electricity or water usage)
  Future<List<ConsumerRanking>> getTopConsumers({
    required String propertyId,
    required int year,
    required int month,
    required ConsumptionType type, // electricity or water
    int limit = 10,
  }) async {
    final bills = await firestore
        .collection('Bills')
        .where('propertyId', isEqualTo: propertyId)
        .where('billingPeriod.year', isEqualTo: year)
        .where('billingPeriod.month', isEqualTo: month)
        .get();
    
    final List<ConsumerRanking> rankings = [];
    
    for (final doc in bills.docs) {
      final bill = BillModel.fromSnapshot(doc);
      final consumption = type == ConsumptionType.electricity
          ? bill.electricity.consumption
          : bill.water.consumption;
      
      rankings.add(ConsumerRanking(
        userId: bill.userId,
        userName: bill.userName,
        unitId: bill.unitId,
        consumption: consumption,
        cost: type == ConsumptionType.electricity
            ? bill.electricity.amount
            : bill.water.amount,
      ));
    }
    
    // Sort by consumption descending
    rankings.sort((a, b) => b.consumption.compareTo(a.consumption));
    
    return rankings.take(limit).toList();
  }
  
  /// Compare unit consumption month-over-month
  Future<ConsumptionComparison> compareUnitConsumption({
    required String userId,
    required int currentYear,
    required int currentMonth,
    required int previousYear,
    required int previousMonth,
  }) async {
    final currentBill = await firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .where('billingPeriod.year', isEqualTo: currentYear)
        .where('billingPeriod.month', isEqualTo: currentMonth)
        .limit(1)
        .get();
    
    final previousBill = await firestore
        .collection('Bills')
        .where('userId', isEqualTo: userId)
        .where('billingPeriod.year', isEqualTo: previousYear)
        .where('billingPeriod.month', isEqualTo: previousMonth)
        .limit(1)
        .get();
    
    if (currentBill.docs.isEmpty || previousBill.docs.isEmpty) {
      throw Exception('Bills not found for comparison');
    }
    
    final current = BillModel.fromSnapshot(currentBill.docs.first);
    final previous = BillModel.fromSnapshot(previousBill.docs.first);
    
    return ConsumptionComparison(
      current: current,
      previous: previous,
      electricityChange: current.electricity.consumption - previous.electricity.consumption,
      waterChange: current.water.consumption - previous.water.consumption,
      electricityPercentChange: _calculatePercentChange(
        previous.electricity.consumption,
        current.electricity.consumption,
      ),
      waterPercentChange: _calculatePercentChange(
        previous.water.consumption,
        current.water.consumption,
      ),
    );
  }
  
  double _calculatePercentChange(double oldValue, double newValue) {
    if (oldValue == 0) return 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }
  
  // ==================== AUTO-UPDATE ANALYTICS ====================
  
  /// Update consumption analytics when a bill is created/updated
  Future<void> updateConsumptionAnalytics(BillModel bill) async {
    final year = bill.billingPeriod.year;
    final month = bill.billingPeriod.month;
    final monthKey = _getMonthKey(month);
    
    final analyticsRef = firestore
        .collection('Users')
        .doc(bill.userId)
        .collection('ConsumptionAnalytics')
        .doc(year.toString());
    
    final doc = await analyticsRef.get();
    
    final monthData = {
      'month': month,
      'electricity': {
        'consumption': bill.electricity.consumption,
        'cost': bill.electricity.amount,
        'previousReading': bill.electricity.previousReading,
        'currentReading': bill.electricity.currentReading,
      },
      'water': {
        'consumption': bill.water.consumption,
        'cost': bill.water.amount,
        'previousReading': bill.water.previousReading,
        'currentReading': bill.water.currentReading,
      },
      'totalUtilityCost': bill.electricity.amount + bill.water.amount,
      'totalBill': bill.total,
    };
    
    if (doc.exists) {
      // Update existing document
      await analyticsRef.update({
        'monthlyData.\': monthData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Recalculate year summary
      await _recalculateYearSummary(bill.userId, year);
    } else {
      // Create new document
      await analyticsRef.set({
        'userId': bill.userId,
        'year': year,
        'unitId': bill.unitId,
        'monthlyData': {
          monthKey: monthData,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
  
  Future<void> _recalculateYearSummary(String userId, int year) async {
    // TODO: Implement year summary recalculation
    // This would aggregate all monthly data for the year
  }
  
  String _getMonthKey(int month) {
    const months = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    return months[month - 1];
  }
}

// Supporting models
enum ConsumptionType { electricity, water }

class PropertyStats {
  final String propertyId;
  double totalElectricityConsumption;
  double totalWaterConsumption;
  double totalElectricityCost;
  double totalWaterCost;
  int unitCount;
  
  PropertyStats({
    required this.propertyId,
    required this.totalElectricityConsumption,
    required this.totalWaterConsumption,
    required this.totalElectricityCost,
    required this.totalWaterCost,
    required this.unitCount,
  });
  
  double get avgElectricityPerUnit => unitCount > 0 ? totalElectricityConsumption / unitCount : 0;
  double get avgWaterPerUnit => unitCount > 0 ? totalWaterConsumption / unitCount : 0;
}

class PropertyConsumptionSummary {
  final int year;
  final int month;
  final Map<String, PropertyStats> properties;
  
  PropertyConsumptionSummary({
    required this.year,
    required this.month,
    required this.properties,
  });
}

class ConsumerRanking {
  final String userId;
  final String userName;
  final String unitId;
  final double consumption;
  final double cost;
  
  ConsumerRanking({
    required this.userId,
    required this.userName,
    required this.unitId,
    required this.consumption,
    required this.cost,
  });
}

class ConsumptionComparison {
  final BillModel current;
  final BillModel previous;
  final double electricityChange;
  final double waterChange;
  final double electricityPercentChange;
  final double waterPercentChange;
  
  ConsumptionComparison({
    required this.current,
    required this.previous,
    required this.electricityChange,
    required this.waterChange,
    required this.electricityPercentChange,
    required this.waterPercentChange,
  });
  
  bool get electricityIncreased => electricityChange > 0;
  bool get waterIncreased => waterChange > 0;
}
\\\

---

### Phase 2: Riverpod Providers for Analytics

Create lib/src/features/billing/presentation/analytics_providers.dart:

\\\dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================== PROVIDERS ====================

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(firestore: FirebaseFirestore.instance);
});

// ==================== TENANT ANALYTICS ====================

/// Stream user consumption for current year
final userConsumptionProvider = StreamProvider.family<ConsumptionAnalytics?, String>((ref, userId) {
  final repository = ref.read(analyticsRepositoryProvider);
  final currentYear = DateTime.now().year;
  return repository.streamUserConsumption(userId, currentYear);
});

/// Get consumption history for multiple years
final userConsumptionHistoryProvider = FutureProvider.family<List<ConsumptionAnalytics>, UserYearsParams>((ref, params) async {
  final repository = ref.read(analyticsRepositoryProvider);
  return await repository.getUserConsumptionHistory(params.userId, params.years);
});

/// Month-over-month comparison for tenant
final consumptionComparisonProvider = FutureProvider.family<ConsumptionComparison, ComparisonParams>((ref, params) async {
  final repository = ref.read(analyticsRepositoryProvider);
  return await repository.compareUnitConsumption(
    userId: params.userId,
    currentYear: params.currentYear,
    currentMonth: params.currentMonth,
    previousYear: params.previousYear,
    previousMonth: params.previousMonth,
  );
});

// ==================== ADMIN ANALYTICS ====================

/// Get all consumption for a property
final propertyConsumptionProvider = FutureProvider.family<Map<String, ConsumptionAnalytics>, PropertyYearParams>((ref, params) async {
  final repository = ref.read(analyticsRepositoryProvider);
  return await repository.getPropertyConsumption(params.propertyId, params.year);
});

/// Get overall consumption summary for all properties
final allPropertiesConsumptionProvider = FutureProvider.family<PropertyConsumptionSummary, YearMonthParams>((ref, params) async {
  final repository = ref.read(analyticsRepositoryProvider);
  return await repository.getAllPropertiesConsumption(params.year, params.month);
});

/// Get top consumers in a property
final topConsumersProvider = FutureProvider.family<List<ConsumerRanking>, TopConsumersParams>((ref, params) async {
  final repository = ref.read(analyticsRepositoryProvider);
  return await repository.getTopConsumers(
    propertyId: params.propertyId,
    year: params.year,
    month: params.month,
    type: params.type,
    limit: params.limit,
  );
});

// ==================== PARAMETER CLASSES ====================

class UserYearsParams {
  final String userId;
  final List<int> years;
  
  UserYearsParams(this.userId, this.years);
}

class PropertyYearParams {
  final String propertyId;
  final int year;
  
  PropertyYearParams(this.propertyId, this.year);
}

class YearMonthParams {
  final int year;
  final int month;
  
  YearMonthParams(this.year, this.month);
}

class ComparisonParams {
  final String userId;
  final int currentYear;
  final int currentMonth;
  final int previousYear;
  final int previousMonth;
  
  ComparisonParams({
    required this.userId,
    required this.currentYear,
    required this.currentMonth,
    required this.previousYear,
    required this.previousMonth,
  });
}

class TopConsumersParams {
  final String propertyId;
  final int year;
  final int month;
  final ConsumptionType type;
  final int limit;
  
  TopConsumersParams({
    required this.propertyId,
    required this.year,
    required this.month,
    required this.type,
    this.limit = 10,
  });
}
\\\

---

### Phase 3: UI Implementation - Charts & Graphs

#### Required Package
Add to pubspec.yaml:
\\\yaml
dependencies:
  fl_chart: ^0.68.0  # For beautiful charts
\\\

#### Step 3.1: Tenant Consumption Dashboard

Create lib/src/features/billing/presentation/screens/tenant_consumption_screen.dart:

\\\dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenantConsumptionScreen extends ConsumerStatefulWidget {
  final String userId;
  
  const TenantConsumptionScreen({required this.userId});

  @override
  ConsumerState<TenantConsumptionScreen> createState() => _TenantConsumptionScreenState();
}

class _TenantConsumptionScreenState extends ConsumerState<TenantConsumptionScreen> {
  @override
  Widget build(BuildContext context) {
    final consumptionAsync = ref.watch(userConsumptionProvider(widget.userId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('My Consumption'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: consumptionAsync.when(
        data: (consumption) {
          if (consumption == null) {
            return Center(child: Text('No consumption data available'));
          }
          return _buildDashboard(consumption);
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: \')),
      ),
    );
  }
  
  Widget _buildDashboard(ConsumptionAnalytics consumption) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(consumption),
          SizedBox(height: 24),
          
          // Electricity Consumption Chart
          Text('Electricity Consumption (kWh)', 
               style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          _buildElectricityChart(consumption),
          SizedBox(height: 32),
          
          // Water Consumption Chart
          Text('Water Consumption (m)', 
               style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          _buildWaterChart(consumption),
          SizedBox(height: 32),
          
          // Cost Breakdown Chart
          Text('Monthly Cost Breakdown', 
               style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          _buildCostChart(consumption),
          SizedBox(height: 32),
          
          // Bill Composition Pie Chart
          Text('Current Month Bill Composition', 
               style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          _buildPieChart(consumption),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCards(ConsumptionAnalytics consumption) {
    final summary = consumption.yearSummary;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Electricity',
            '\ kWh',
            '\',
            Icons.bolt,
            Colors.orange,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Water',
            '\ m',
            '\',
            Icons.water_drop,
            Colors.blue,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, String cost, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(cost, style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildElectricityChart(ConsumptionAnalytics consumption) {
    final spots = <FlSpot>[];
    final monthlyData = consumption.monthlyData;
    
    monthlyData.forEach((key, data) {
      spots.add(FlSpot(data.month.toDouble(), data.electricity.consumption));
    });
    
    spots.sort((a, b) => a.x.compareTo(b.x));
    
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  if (value.toInt() >= 1 && value.toInt() <= 12) {
                    return Text(months[value.toInt() - 1], style: TextStyle(fontSize: 10));
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWaterChart(ConsumptionAnalytics consumption) {
    final spots = <FlSpot>[];
    final monthlyData = consumption.monthlyData;
    
    monthlyData.forEach((key, data) {
      spots.add(FlSpot(data.month.toDouble(), data.water.consumption));
    });
    
    spots.sort((a, b) => a.x.compareTo(b.x));
    
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  if (value.toInt() >= 1 && value.toInt() <= 12) {
                    return Text(months[value.toInt() - 1], style: TextStyle(fontSize: 10));
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCostChart(ConsumptionAnalytics consumption) {
    final monthlyData = consumption.monthlyData;
    final barGroups = <BarChartGroupData>[];
    
    monthlyData.forEach((key, data) {
      barGroups.add(
        BarChartGroupData(
          x: data.month,
          barRods: [
            BarChartRodData(
              toY: data.totalBill,
              color: Colors.green,
              width: 16,
            ),
          ],
        ),
      );
    });
    
    barGroups.sort((a, b) => a.x.compareTo(b.x));
    
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['J', 'F', 'M', 'A', 'M', 'J',
                                  'J', 'A', 'S', 'O', 'N', 'D'];
                  if (value.toInt() >= 1 && value.toInt() <= 12) {
                    return Text(months[value.toInt() - 1]);
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 50),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          barGroups: barGroups,
        ),
      ),
    );
  }
  
  Widget _buildPieChart(ConsumptionAnalytics consumption) {
    // Get latest month data
    final latestMonth = consumption.monthlyData.values.reduce(
      (a, b) => a.month > b.month ? a : b
    );
    
    final total = latestMonth.totalBill;
    final rent = 25000.0; // You'd get this from the actual bill
    final electricity = latestMonth.electricity.cost;
    final water = latestMonth.water.cost;
    final others = total - rent - electricity - water;
    
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: rent,
              title: 'Rent\n\%',
              color: Colors.purple,
              radius: 100,
            ),
            PieChartSectionData(
              value: electricity,
              title: 'Electricity\n\%',
              color: Colors.orange,
              radius: 100,
            ),
            PieChartSectionData(
              value: water,
              title: 'Water\n\%',
              color: Colors.blue,
              radius: 100,
            ),
            PieChartSectionData(
              value: others,
              title: 'Others\n\%',
              color: Colors.grey,
              radius: 100,
            ),
          ],
        ),
      ),
    );
  }
  
  void _exportReport() {
    // Implement image export of validated payment
  }
}
\\\

#### Step 3.2: Admin Consumption Dashboard

Create lib/src/features/billing/presentation/screens/admin_consumption_dashboard.dart:

\\\dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminConsumptionDashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<AdminConsumptionDashboard> createState() => _AdminConsumptionDashboardState();
}

class _AdminConsumptionDashboardState extends ConsumerState<AdminConsumptionDashboard> {
  String? selectedPropertyId;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consumption Dashboard'),
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),
          
          // Summary
          Expanded(
            child: _buildDashboard(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Property selector
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final propertiesAsync = ref.watch(propertiesProvider);
                return propertiesAsync.when(
                  data: (properties) => DropdownButtonFormField<String>(
                    value: selectedPropertyId,
                    decoration: InputDecoration(labelText: 'Property'),
                    items: properties
                        .map((p) => DropdownMenuItem(
                              value: p.propertyId,
                              child: Text(p.propertyName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedPropertyId = value);
                    },
                  ),
                  loading: () => CircularProgressIndicator(),
                  error: (e, st) => Text('Error'),
                );
              },
            ),
          ),
          SizedBox(width: 16),
          
          // Month selector
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: InputDecoration(labelText: 'Month'),
              items: List.generate(12, (i) => i + 1)
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(_getMonthName(m)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedMonth = value);
              },
            ),
          ),
          SizedBox(width: 16),
          
          // Year selector
          SizedBox(
            width: 100,
            child: DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: InputDecoration(labelText: 'Year'),
              items: List.generate(5, (i) => DateTime.now().year - i)
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text(y.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedYear = value);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboard() {
    if (selectedPropertyId == null) {
      return Center(child: Text('Select a property to view consumption'));
    }
    
    final summaryAsync = ref.watch(
      allPropertiesConsumptionProvider(
        YearMonthParams(selectedYear, selectedMonth)
      )
    );
    
    final topElectricityAsync = ref.watch(
      topConsumersProvider(
        TopConsumersParams(
          propertyId: selectedPropertyId!,
          year: selectedYear,
          month: selectedMonth,
          type: ConsumptionType.electricity,
          limit: 10,
        ),
      ),
    );
    
    final topWaterAsync = ref.watch(
      topConsumersProvider(
        TopConsumersParams(
          propertyId: selectedPropertyId!,
          year: selectedYear,
          month: selectedMonth,
          type: ConsumptionType.water,
          limit: 10,
        ),
      ),
    );
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Summary
          summaryAsync.when(
            data: (summary) {
              if (!summary.properties.containsKey(selectedPropertyId)) {
                return Text('No data for this property');
              }
              final stats = summary.properties[selectedPropertyId]!;
              return _buildPropertySummary(stats);
            },
            loading: () => CircularProgressIndicator(),
            error: (e, st) => Text('Error: \'),
          ),
          SizedBox(height: 32),
          
          // Top Electricity Consumers
          Text('Top Electricity Consumers', 
               style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          topElectricityAsync.when(
            data: (rankings) => _buildRankingsTable(rankings, ConsumptionType.electricity),
            loading: () => CircularProgressIndicator(),
            error: (e, st) => Text('Error: \'),
          ),
          SizedBox(height: 32),
          
          // Top Water Consumers
          Text('Top Water Consumers', 
               style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 16),
          topWaterAsync.when(
            data: (rankings) => _buildRankingsTable(rankings, ConsumptionType.water),
            loading: () => CircularProgressIndicator(),
            error: (e, st) => Text('Error: \'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPropertySummary(PropertyStats stats) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Property Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Electricity',
                    '\ kWh',
                    '\',
                    Icons.bolt,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Water',
                    '\ m',
                    '\',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg Electricity/Unit',
                    '\ kWh',
                    '\ units',
                    Icons.analytics,
                    Colors.orange.shade300,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Water/Unit',
                    '\ m',
                    '\ units',
                    Icons.analytics,
                    Colors.blue.shade300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String title, String value, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
  
  Widget _buildRankingsTable(List<ConsumerRanking> rankings, ConsumptionType type) {
    return Card(
      child: DataTable(
        columns: [
          DataColumn(label: Text('Rank')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Tenant')),
          DataColumn(label: Text('Consumption')),
          DataColumn(label: Text('Cost')),
        ],
        rows: rankings.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final ranking = entry.value;
          final unit = type == ConsumptionType.electricity ? 'kWh' : 'm';
          
          return DataRow(
            cells: [
              DataCell(Text('\')),
              DataCell(Text(ranking.unitId)),
              DataCell(Text(ranking.userName)),
              DataCell(Text('\ \')),
              DataCell(Text('\')),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
\\\

---

## Summary

###  What's Included:

1. **Database Structure** (Already exists in BILLING_DATABASE_STRUCTURE.md)
   - ConsumptionAnalytics collection
   - Monthly breakdown
   - Year summary

2. **Backend Repository** (New - Phase 1)
   - AnalyticsRepository with 10+ methods
   - Tenant analytics queries
   - Admin analytics queries
   - Automatic analytics updates

3. **Riverpod Providers** (New - Phase 2)
   - Stream/Future providers for all analytics data
   - Family providers for parameterized queries

4. **UI Screens** (New - Phase 3)
   - **Tenant Dashboard**: Line charts (electricity, water), bar charts (costs), pie chart (bill composition)
   - **Admin Dashboard**: Property overview, top consumers table, comparison tools

###  Charts Available:

**For Tenants:**
-  Line chart: Monthly electricity consumption
-  Line chart: Monthly water consumption
-  Bar chart: Monthly total bill
-  Pie chart: Current bill composition

**For Admins:**
-  Property summary statistics
-  Top consumers ranking table
-  Average consumption per unit
-  Property comparison (future enhancement)

###  Package Required:
\\\yaml
dependencies:
  fl_chart: ^0.68.0
\\\

---

**Next Steps:**
1. Add l_chart to pubspec.yaml
2. Create nalytics_repository.dart
3. Create nalytics_providers.dart
4. Create tenant and admin consumption screens
5. Test with sample data

**Status:**  Ready for Implementation
