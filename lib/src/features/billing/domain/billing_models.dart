/// Represents a billing period
class BillingPeriod {
  final int month;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime dueDate;
  final String billingCycle;

  const BillingPeriod({
    required this.month,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.dueDate,
    this.billingCycle = 'monthly',
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'year': year,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'billingCycle': billingCycle,
    };
  }

  factory BillingPeriod.fromMap(Map<String, dynamic> map) {
    return BillingPeriod(
      month: map['month'] as int,
      year: map['year'] as int,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      billingCycle: map['billingCycle'] as String? ?? 'monthly',
    );
  }

  BillingPeriod copyWith({
    int? month,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? dueDate,
    String? billingCycle,
  }) {
    return BillingPeriod(
      month: month ?? this.month,
      year: year ?? this.year,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dueDate: dueDate ?? this.dueDate,
      billingCycle: billingCycle ?? this.billingCycle,
    );
  }
}

/// Represents utility charges (electricity or water)
class UtilityCharge {
  final double previousReading;
  final double currentReading;
  final double consumption;
  final String unit;
  final double ratePerUnit;
  final double amount;
  final String meterNumber;
  final DateTime readingDate;

  const UtilityCharge({
    required this.previousReading,
    required this.currentReading,
    required this.consumption,
    required this.unit,
    required this.ratePerUnit,
    required this.amount,
    required this.meterNumber,
    required this.readingDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'previousReading': previousReading,
      'currentReading': currentReading,
      'consumption': consumption,
      'unit': unit,
      'ratePerUnit': ratePerUnit,
      'amount': amount,
      'meterNumber': meterNumber,
      'readingDate': readingDate.toIso8601String(),
    };
  }

  factory UtilityCharge.fromMap(Map<String, dynamic> map) {
    return UtilityCharge(
      previousReading: (map['previousReading'] as num).toDouble(),
      currentReading: (map['currentReading'] as num).toDouble(),
      consumption: (map['consumption'] as num).toDouble(),
      unit: map['unit'] as String,
      ratePerUnit: (map['ratePerUnit'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      meterNumber: map['meterNumber'] as String,
      readingDate: DateTime.parse(map['readingDate'] as String),
    );
  }
}

/// Represents additional charges
class AdditionalCharge {
  final String chargeId;
  final String description;
  final double amount;
  final String category;

  const AdditionalCharge({
    required this.chargeId,
    required this.description,
    required this.amount,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'chargeId': chargeId,
      'description': description,
      'amount': amount,
      'category': category,
    };
  }

  factory AdditionalCharge.fromMap(Map<String, dynamic> map) {
    return AdditionalCharge(
      chargeId: map['chargeId'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
    );
  }
}

/// Represents payment breakdown for partial payments
class PaymentBreakdownItem {
  final double amount;
  final double amountPaid;
  final double balance;
  final bool isPaid;
  final DateTime? paidAt;
  final String? description; // Optional description for additional charges

  const PaymentBreakdownItem({
    required this.amount,
    required this.amountPaid,
    required this.balance,
    required this.isPaid,
    this.paidAt,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'amountPaid': amountPaid,
      'balance': balance,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
      if (description != null) 'description': description,
    };
  }

  factory PaymentBreakdownItem.fromMap(Map<String, dynamic> map) {
    return PaymentBreakdownItem(
      amount: (map['amount'] as num).toDouble(),
      amountPaid: (map['amountPaid'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      isPaid: map['isPaid'] as bool,
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt'] as String) : null,
      description: map['description'] as String?,
    );
  }

  PaymentBreakdownItem copyWith({
    double? amount,
    double? amountPaid,
    double? balance,
    bool? isPaid,
    DateTime? paidAt,
    String? description,
  }) {
    return PaymentBreakdownItem(
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      balance: balance ?? this.balance,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      description: description ?? this.description,
    );
  }
}

/// Represents late fee details for overdue bills
class LateFeeDetails {
  final bool isLate;
  final int weeksOverdue;
  final double lateFeePerWeek;
  final double totalLateFee;
  final DateTime? lateFeeAppliedAt;
  final DateTime gracePeriodEnd;

  const LateFeeDetails({
    required this.isLate,
    required this.weeksOverdue,
    required this.lateFeePerWeek,
    required this.totalLateFee,
    this.lateFeeAppliedAt,
    required this.gracePeriodEnd,
  });

  Map<String, dynamic> toMap() {
    return {
      'isLate': isLate,
      'weeksOverdue': weeksOverdue,
      'lateFeePerWeek': lateFeePerWeek,
      'totalLateFee': totalLateFee,
      'lateFeeAppliedAt': lateFeeAppliedAt?.toIso8601String(),
      'gracePeriodEnd': gracePeriodEnd.toIso8601String(),
    };
  }

  factory LateFeeDetails.fromMap(Map<String, dynamic> map) {
    return LateFeeDetails(
      isLate: map['isLate'] as bool,
      weeksOverdue: map['weeksOverdue'] as int,
      lateFeePerWeek: (map['lateFeePerWeek'] as num).toDouble(),
      totalLateFee: (map['totalLateFee'] as num).toDouble(),
      lateFeeAppliedAt: map['lateFeeAppliedAt'] != null
          ? DateTime.parse(map['lateFeeAppliedAt'] as String)
          : null,
      gracePeriodEnd: DateTime.parse(map['gracePeriodEnd'] as String),
    );
  }

  /// Calculate late fee based on current date
  static LateFeeDetails calculate({
    required DateTime dueDate,
    required int gracePeriodDays,
    required double lateFeePerWeek,
  }) {
    final now = DateTime.now();
    final gracePeriodEnd = dueDate.add(Duration(days: gracePeriodDays));

    if (now.isBefore(gracePeriodEnd)) {
      // Still within grace period
      return LateFeeDetails(
        isLate: false,
        weeksOverdue: 0,
        lateFeePerWeek: lateFeePerWeek,
        totalLateFee: 0.0,
        gracePeriodEnd: gracePeriodEnd,
      );
    }

    // Calculate weeks overdue
    final daysOverdue = now.difference(gracePeriodEnd).inDays;
    final weeksOverdue = (daysOverdue / 7).ceil();
    final totalLateFee = weeksOverdue * lateFeePerWeek;

    return LateFeeDetails(
      isLate: true,
      weeksOverdue: weeksOverdue,
      lateFeePerWeek: lateFeePerWeek,
      totalLateFee: totalLateFee,
      lateFeeAppliedAt: now,
      gracePeriodEnd: gracePeriodEnd,
    );
  }

  LateFeeDetails copyWith({
    bool? isLate,
    int? weeksOverdue,
    double? lateFeePerWeek,
    double? totalLateFee,
    DateTime? lateFeeAppliedAt,
    DateTime? gracePeriodEnd,
  }) {
    return LateFeeDetails(
      isLate: isLate ?? this.isLate,
      weeksOverdue: weeksOverdue ?? this.weeksOverdue,
      lateFeePerWeek: lateFeePerWeek ?? this.lateFeePerWeek,
      totalLateFee: totalLateFee ?? this.totalLateFee,
      lateFeeAppliedAt: lateFeeAppliedAt ?? this.lateFeeAppliedAt,
      gracePeriodEnd: gracePeriodEnd ?? this.gracePeriodEnd,
    );
  }
}
