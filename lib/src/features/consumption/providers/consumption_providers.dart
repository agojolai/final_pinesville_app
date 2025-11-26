import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/consumption_repository.dart';
import '../domain/consumption_models.dart';

/// Provider for consumption repository
final consumptionRepositoryProvider = Provider<ConsumptionRepository>((ref) {
  return ConsumptionRepository.instance;
});

/// Stream tenant's electricity consumption
final tenantElectricityProvider = StreamProvider.family<ConsumptionSummary, String>((ref, userId) {
  final repository = ref.watch(consumptionRepositoryProvider);
  return repository.streamTenantConsumption(
    userId: userId,
    utilityType: 'electricity',
    months: 6,
  );
});

/// Stream tenant's water consumption
final tenantWaterProvider = StreamProvider.family<ConsumptionSummary, String>((ref, userId) {
  final repository = ref.watch(consumptionRepositoryProvider);
  return repository.streamTenantConsumption(
    userId: userId,
    utilityType: 'water',
    months: 6,
  );
});

/// Fetch unit electricity consumption history (admin view)
final unitElectricityHistoryProvider = FutureProvider.family<UnitConsumptionHistory, String>((ref, unitId) async {
  final repository = ref.watch(consumptionRepositoryProvider);
  return repository.getUnitConsumption(
    unitId: unitId,
    utilityType: 'electricity',
  );
});

/// Fetch unit water consumption history (admin view)
final unitWaterHistoryProvider = FutureProvider.family<UnitConsumptionHistory, String>((ref, unitId) async {
  final repository = ref.watch(consumptionRepositoryProvider);
  return repository.getUnitConsumption(
    unitId: unitId,
    utilityType: 'water',
  );
});

/// Consumption comparison provider (tenant vs unit average)
class ConsumptionComparisonParams {
  final String userId;
  final String unitId;
  final String utilityType;

  ConsumptionComparisonParams({
    required this.userId,
    required this.unitId,
    required this.utilityType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsumptionComparisonParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          unitId == other.unitId &&
          utilityType == other.utilityType;

  @override
  int get hashCode => userId.hashCode ^ unitId.hashCode ^ utilityType.hashCode;
}

final consumptionComparisonProvider = FutureProvider.family<Map<String, dynamic>, ConsumptionComparisonParams>((ref, params) async {
  final repository = ref.watch(consumptionRepositoryProvider);
  return repository.getConsumptionComparison(
    userId: params.userId,
    unitId: params.unitId,
    utilityType: params.utilityType,
    months: 6,
  );
});

/// Latest consumption reading provider
class LatestReadingParams {
  final String userId;
  final String utilityType;

  LatestReadingParams({
    required this.userId,
    required this.utilityType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatestReadingParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          utilityType == other.utilityType;

  @override
  int get hashCode => userId.hashCode ^ utilityType.hashCode;
}

final latestConsumptionReadingProvider = FutureProvider.family<ConsumptionDataPoint?, LatestReadingParams>((ref, params) async {
  final repository = ref.watch(consumptionRepositoryProvider);
  return repository.getLatestReading(
    userId: params.userId,
    utilityType: params.utilityType,
  );
});
