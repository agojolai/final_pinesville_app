import 'bill_model.dart';

/// Represents eviction status for a user
class EvictionStatus {
  final bool isFacingEviction;
  final int unpaidMonthsCount;
  final BillModel? oldestUnpaidBill;
  final List<BillModel>? consecutiveUnpaidBills;

  const EvictionStatus({
    required this.isFacingEviction,
    required this.unpaidMonthsCount,
    this.oldestUnpaidBill,
    this.consecutiveUnpaidBills,
  });

  String get warningMessage {
    if (!isFacingEviction) return '';
    
    return 'You have 2 consecutive months of unpaid bills past their due dates. '
           'Please settle your outstanding balance immediately or contact the admin '
           'to discuss payment arrangements to avoid eviction proceedings.';
  }

  String get shortWarning {
    if (!isFacingEviction) return '';
    return 'Eviction Warning:  unpaid months';
  }
}
