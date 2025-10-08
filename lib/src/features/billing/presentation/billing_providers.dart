import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bill_model.dart';
import '../domain/payment_model.dart';
import '../domain/property_billing_model.dart';
import '../domain/unit_billing_model.dart';
import '../data/billing_repository.dart';

// ==================== BILL PROVIDERS ====================

/// Provider for user's bills stream
final userBillsProvider = StreamProvider.family<List<BillModel>, String>((ref, userId) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getUserBills(userId);
});

/// Provider for unpaid bills stream
final unpaidBillsProvider = StreamProvider.family<List<BillModel>, String>((ref, userId) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getUnpaidBills(userId);
});

/// Provider for overdue bills stream
final overdueBillsProvider = StreamProvider.family<List<BillModel>, String>((ref, userId) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getOverdueBills(userId);
});

/// Provider for partially paid bills stream
final partiallyPaidBillsProvider = StreamProvider.family<List<BillModel>, String>((ref, userId) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getPartiallyPaidBills(userId);
});

/// Provider for a single bill (real-time updates)
final billProvider = StreamProvider.family<BillModel?, String>((ref, billId) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getBillByIdStream(billId);
});

/// Provider for unpaid breakdown of a bill
final unpaidBreakdownProvider = FutureProvider.family<Map<String, double>, String>((ref, billId) async {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getUnpaidBreakdown(billId);
});

// ==================== PAYMENT PROVIDERS ====================

/// Provider for user's payments stream
final userPaymentsProvider = StreamProvider.family<List<PaymentModel>, String>((ref, userId) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getUserPayments(userId);
});

/// Provider for bill's payments stream
final billPaymentsProvider = StreamProvider.family<List<PaymentModel>, String>((ref, billId) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getBillPayments(billId);
});

/// Provider for pending verification payments (Admin) - Legacy
final pendingVerificationPaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getPendingVerificationPayments();
});

/// Provider for pending payments (Admin) - New simplified workflow
final pendingPaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getPendingPayments();
});

// ==================== STATISTICS PROVIDERS ====================

/// Provider for total unpaid amount for a user
final totalUnpaidAmountProvider = Provider.family<double, String>((ref, userId) {
  final billsAsync = ref.watch(unpaidBillsProvider(userId));
  return billsAsync.when(
    data: (bills) => bills.fold(0.0, (sum, bill) => sum + bill.balance),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider for count of unpaid bills
final unpaidBillsCountProvider = Provider.family<int, String>((ref, userId) {
  final billsAsync = ref.watch(unpaidBillsProvider(userId));
  return billsAsync.when(
    data: (bills) => bills.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for count of overdue bills
final overdueBillsCountProvider = Provider.family<int, String>((ref, userId) {
  final billsAsync = ref.watch(overdueBillsProvider(userId));
  return billsAsync.when(
    data: (bills) => bills.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for bills due soon (within 3 days)
final billsDueSoonProvider = Provider.family<List<BillModel>, String>((ref, userId) {
  final billsAsync = ref.watch(unpaidBillsProvider(userId));
  return billsAsync.when(
    data: (bills) => bills.where((bill) => bill.isDueSoon).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ==================== PROPERTY & UNIT PROVIDERS ====================

/// Provider for all properties stream
final propertiesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getProperties();
});

/// Provider for units in a specific property
final unitsForPropertyProvider = StreamProvider.family<List<UnitBillingInfo>, String>((ref, propertyId) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getUnitsForProperty(propertyId);
});

/// Provider for specific unit details
final unitDetailsProvider = FutureProvider.family<UnitBillingInfo?, ({String propertyId, String unitId})>((ref, params) async {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getUnitDetails(params.propertyId, params.unitId);
});

/// Provider for property utility rates
final propertyRatesProvider = FutureProvider.family<PropertyUtilityRates?, String>((ref, propertyId) async {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getPropertyRates(propertyId);
});

// ==================== ADMIN BILL OVERVIEW PROVIDERS ====================

/// Provider for current month bills (Admin - for Bills Overview tab)
final currentMonthBillsProvider = StreamProvider<List<BillModel>>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getCurrentMonthBills();
});

// ==================== CONSUMPTION ANALYTICS PROVIDERS ====================

/// Provider for user's monthly consumption history
final userMonthlyConsumptionProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String userId, int months})>((ref, params) async {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getUnitMonthlyConsumption(
    userId: params.userId,
    numberOfMonths: params.months,
  );
});

/// Provider for property-wide consumption (Admin)
final propertyMonthlyConsumptionProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String propertyId, int month, int year})>((ref, params) async {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getPropertyMonthlyConsumption(
    propertyId: params.propertyId,
    month: params.month,
    year: params.year,
  );
});

/// Provider for consumption trends stream (for live charts)
final consumptionTrendsProvider = StreamProvider.family<List<Map<String, dynamic>>, ({String userId, int months})>((ref, params) {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getConsumptionTrends(
    userId: params.userId,
    months: params.months,
  );
});

/// Provider for average consumption statistics
final averageConsumptionProvider = FutureProvider.family<Map<String, double>, ({String userId, int months})>((ref, params) async {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.getAverageConsumption(
    userId: params.userId,
    months: params.months,
  );
});

/// Provider for month-to-month comparison
final consumptionComparisonProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.compareWithPreviousMonth(userId: userId);
});
