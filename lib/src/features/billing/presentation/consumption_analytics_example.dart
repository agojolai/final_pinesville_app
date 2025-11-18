import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'billing_providers.dart';

/// Example implementation of consumption analytics
/// This file demonstrates how to use all consumption tracking features

class ConsumptionAnalyticsScreen extends ConsumerWidget {
  final String userId;

  const ConsumptionAnalyticsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumption Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlyConsumptionHistory(ref),
            const SizedBox(height: 24),
            _buildAverageConsumption(ref),
            const SizedBox(height: 24),
            _buildMonthComparison(ref),
            const SizedBox(height: 24),
            _buildConsumptionTrends(ref),
          ],
        ),
      ),
    );
  }

  /// Example 1: Show last 6 months of consumption history
  Widget _buildMonthlyConsumptionHistory(WidgetRef ref) {
    final consumptionAsync = ref.watch(
      userMonthlyConsumptionProvider((userId: userId, months: 6)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Consumption History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            consumptionAsync.when(
              data: (consumptionData) {
                if (consumptionData.isEmpty) {
                  return const Text('No consumption data available');
                }

                return Column(
                  children: consumptionData.map((monthData) {
                    final electricity = monthData['electricity'] as Map<String, dynamic>;
                    final water = monthData['water'] as Map<String, dynamic>;

                    return ListTile(
                      title: Text(monthData['monthLabel'] as String),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Electricity:  kWh - '),
                          Text('Water:  m - '),
                        ],
                      ),
                      trailing: Text(
                        '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  /// Example 2: Show average consumption statistics
  Widget _buildAverageConsumption(WidgetRef ref) {
    final avgAsync = ref.watch(
      averageConsumptionProvider((userId: userId, months: 6)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Monthly Consumption (6 months)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            avgAsync.when(
              data: (avgData) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Avg. Electricity:'),
                        Text(' kWh'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Avg. Water:'),
                        Text(' m'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Avg. Electricity Cost:'),
                        Text(''),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Avg. Water Cost:'),
                        Text(''),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  /// Example 3: Compare current month with previous month
  Widget _buildMonthComparison(WidgetRef ref) {
    final comparisonAsync = ref.watch(
      consumptionComparisonProvider(userId),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Month-to-Month Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            comparisonAsync.when(
              data: (comparison) {
                if (comparison.containsKey('error')) {
                  return Text(comparison['error'] as String);
                }

                final current = comparison['current'] as Map<String, dynamic>;
                final previous = comparison['previous'] as Map<String, dynamic>?;
                final comp = comparison['comparison'] as Map<String, dynamic>?;

                if (previous == null || comp == null) {
                  return const Text('Not enough data for comparison');
                }

                return Column(
                  children: [
                    _buildComparisonRow(
                      'Electricity',
                      previous['electricityConsumption'],
                      current['electricityConsumption'],
                      comp['electricityPercentChange'],
                      comp['electricityIncreased'] as bool,
                      'kWh',
                    ),
                    const SizedBox(height: 8),
                    _buildComparisonRow(
                      'Water',
                      previous['waterConsumption'],
                      current['waterConsumption'],
                      comp['waterPercentChange'],
                      comp['waterIncreased'] as bool,
                      'm',
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    double previousValue,
    double currentValue,
    double percentChange,
    bool increased,
    String unit,
  ) {
    final color = increased ? Colors.red : Colors.green;
    final icon = increased ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('   $unit'),
            ],
          ),
        ),
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              '%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  /// Example 4: Real-time consumption trends (for charts)
  Widget _buildConsumptionTrends(WidgetRef ref) {
    final trendsAsync = ref.watch(
      consumptionTrendsProvider((userId: userId, months: 6)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consumption Trends (Real-time)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This data updates in real-time. Perfect for charts!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            trendsAsync.when(
              data: (trends) {
                if (trends.isEmpty) {
                  return const Text('No trend data available');
                }

                // Here you would integrate a chart library like fl_chart
                // For now, showing data in simple format
                return Column(
                  children: trends.map((trend) {
                    return ListTile(
                      dense: true,
                      title: Text(trend['monthLabel'] as String),
                      subtitle: Text(
                        'Elec:  kWh | Water:  m',
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example for Admin: Property-wide consumption
class PropertyConsumptionScreen extends ConsumerWidget {
  final String propertyId;

  const PropertyConsumptionScreen({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final propertyConsumptionAsync = ref.watch(
      propertyMonthlyConsumptionProvider((
        propertyId: propertyId,
        month: now.month,
        year: now.year,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Consumption'),
      ),
      body: propertyConsumptionAsync.when(
        data: (units) {
          if (units.isEmpty) {
            return const Center(child: Text('No consumption data for this month'));
          }

          double totalElectricity = 0;
          double totalWater = 0;
          double totalAmount = 0;

          for (final unit in units) {
            final electricity = unit['electricity'] as Map<String, dynamic>;
            final water = unit['water'] as Map<String, dynamic>;
            totalElectricity += electricity['consumption'] as double;
            totalWater += water['consumption'] as double;
            totalAmount += unit['totalAmount'] as double;
          }

          return Column(
            children: [
              // Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Property-wide Summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Total Electricity', ' kWh'),
                          _buildSummaryItem('Total Water', ' m'),
                          _buildSummaryItem('Total Amount', ''),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Per-unit breakdown
              Expanded(
                child: ListView.builder(
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    final electricity = unit['electricity'] as Map<String, dynamic>;
                    final water = unit['water'] as Map<String, dynamic>;

                    return ListTile(
                      title: Text(' - Unit '),
                      subtitle: Text(
                        'Elec:  kWh | Water:  m',
                      ),
                      trailing: Text(
                        '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
