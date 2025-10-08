import 'package:cloud_firestore/cloud_firestore.dart';
import 'billing_models.dart';

/// Bill status enum
enum BillStatus {
  pending,
  partiallyPaid,
  paid,
  overdue,
  cancelled;

  String toJson() => name;

  static BillStatus fromJson(String value) {
    switch (value) {
      case 'pending':
        return BillStatus.pending;
      case 'partially_paid':
      case 'partiallyPaid':
        return BillStatus.partiallyPaid;
      case 'paid':
        return BillStatus.paid;
      case 'overdue':
        return BillStatus.overdue;
      case 'cancelled':
        return BillStatus.cancelled;
      default:
        return BillStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case BillStatus.pending:
        return 'Pending';
      case BillStatus.partiallyPaid:
        return 'Partially Paid';
      case BillStatus.paid:
        return 'Paid';
      case BillStatus.overdue:
        return 'Overdue';
      case BillStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Represents a monthly bill
class BillModel {
  final String billId;
  final String userId;
  final String userEmail;
  final String userName;
  final String unitId;
  final String propertyId;
  final BillingPeriod billingPeriod;
  final double baseRent;
  final String rentDescription;
  final UtilityCharge electricity;
  final UtilityCharge water;
  final List<AdditionalCharge> additionalCharges;
  final double subtotal;
  final double discount;
  final String discountReason;
  final double lateFee;
  final double tax;
  final double total;
  final double amountPaid;
  final double balance;
  final PaymentBreakdownItem rentBreakdown;
  final PaymentBreakdownItem electricityBreakdown;
  final PaymentBreakdownItem waterBreakdown;
  final PaymentBreakdownItem trashBreakdown;
  final PaymentBreakdownItem wifiBreakdown;
  final PaymentBreakdownItem parkingBreakdown;
  final PaymentBreakdownItem additionalChargesBreakdown;
  final LateFeeDetails lateFeeDetails;
  final BillStatus status;
  final bool isPaid;
  final bool isOverdue;
  final bool isPartiallyPaid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final String generatedBy;
  final String notes;
  final List<String> attachments;
  final bool receiptGenerated;
  final String? receiptUrl;
  final DateTime? receiptGeneratedAt;

  const BillModel({
    required this.billId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.unitId,
    required this.propertyId,
    required this.billingPeriod,
    required this.baseRent,
    required this.rentDescription,
    required this.electricity,
    required this.water,
    required this.additionalCharges,
    required this.subtotal,
    required this.discount,
    required this.discountReason,
    required this.lateFee,
    required this.tax,
    required this.total,
    required this.amountPaid,
    required this.balance,
    required this.rentBreakdown,
    required this.electricityBreakdown,
    required this.waterBreakdown,
    required this.trashBreakdown,
    required this.wifiBreakdown,
    required this.parkingBreakdown,
    required this.additionalChargesBreakdown,
    required this.lateFeeDetails,
    required this.status,
    required this.isPaid,
    required this.isOverdue,
    required this.isPartiallyPaid,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    required this.generatedBy,
    this.notes = '',
    this.attachments = const [],
    this.receiptGenerated = false,
    this.receiptUrl,
    this.receiptGeneratedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'billId': billId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'unitId': unitId,
      'propertyId': propertyId,
      'billingPeriod': billingPeriod.toMap(),
      'rent': {
        'baseRent': baseRent,
        'description': rentDescription,
      },
      'utilities': {
        'electricity': electricity.toMap(),
        'water': water.toMap(),
      },
      // 'additionalCharges': Removed - redundant with paymentBreakdown
      'summary': {
        'subtotal': subtotal,
        'discount': discount,
        'discountReason': discountReason,
        'lateFee': lateFee,
        'tax': tax,
        'total': total,
        'amountPaid': amountPaid,
        'balance': balance,
      },
      'paymentBreakdown': {
        'rent': rentBreakdown.toMap(),
        'electricity': electricityBreakdown.toMap(),
        'water': waterBreakdown.toMap(),
        'trash': trashBreakdown.toMap(),
        'wifi': wifiBreakdown.toMap(),
        'parking': parkingBreakdown.toMap(),
        'additionalCharges': additionalChargesBreakdown.toMap(),
      },
      'lateFeeDetails': lateFeeDetails.toMap(),
      'status': status.name,
      'isPaid': isPaid,
      'isOverdue': isOverdue,
      'isPartiallyPaid': isPartiallyPaid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'generatedBy': generatedBy,
      'notes': notes,
      'attachments': attachments,
      'receiptGenerated': receiptGenerated,
      'receiptUrl': receiptUrl,
      'receiptGeneratedAt': receiptGeneratedAt?.toIso8601String(),
    };
  }

  factory BillModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillModel.fromMap(data);
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    final rentData = map['rent'] as Map<String, dynamic>;
    final utilitiesData = map['utilities'] as Map<String, dynamic>;
    final summaryData = map['summary'] as Map<String, dynamic>;
    final breakdownData = map['paymentBreakdown'] as Map<String, dynamic>;

    return BillModel(
      billId: map['billId'] as String,
      userId: map['userId'] as String,
      userEmail: map['userEmail'] as String,
      userName: map['userName'] as String,
      unitId: map['unitId'] as String,
      propertyId: map['propertyId'] as String,
      billingPeriod: BillingPeriod.fromMap(map['billingPeriod'] as Map<String, dynamic>),
      baseRent: (rentData['baseRent'] as num).toDouble(),
      rentDescription: rentData['description'] as String,
      electricity: UtilityCharge.fromMap(utilitiesData['electricity'] as Map<String, dynamic>),
      water: UtilityCharge.fromMap(utilitiesData['water'] as Map<String, dynamic>),
      additionalCharges: (map['additionalCharges'] as List<dynamic>?)
          ?.map((c) => AdditionalCharge.fromMap(c as Map<String, dynamic>))
          .toList() ?? const [], // Handle null case - field removed from storage
      subtotal: (summaryData['subtotal'] as num).toDouble(),
      discount: (summaryData['discount'] as num).toDouble(),
      discountReason: summaryData['discountReason'] as String? ?? '',
      lateFee: (summaryData['lateFee'] as num).toDouble(),
      tax: (summaryData['tax'] as num).toDouble(),
      total: (summaryData['total'] as num).toDouble(),
      amountPaid: (summaryData['amountPaid'] as num).toDouble(),
      balance: (summaryData['balance'] as num).toDouble(),
      rentBreakdown: PaymentBreakdownItem.fromMap(breakdownData['rent'] as Map<String, dynamic>),
      electricityBreakdown: PaymentBreakdownItem.fromMap(breakdownData['electricity'] as Map<String, dynamic>),
      waterBreakdown: PaymentBreakdownItem.fromMap(breakdownData['water'] as Map<String, dynamic>),
      trashBreakdown: breakdownData.containsKey('trash')
          ? PaymentBreakdownItem.fromMap(breakdownData['trash'] as Map<String, dynamic>)
          : const PaymentBreakdownItem(amount: 0, amountPaid: 0, balance: 0, isPaid: false),
      wifiBreakdown: breakdownData.containsKey('wifi')
          ? PaymentBreakdownItem.fromMap(breakdownData['wifi'] as Map<String, dynamic>)
          : const PaymentBreakdownItem(amount: 0, amountPaid: 0, balance: 0, isPaid: false),
      parkingBreakdown: breakdownData.containsKey('parking')
          ? PaymentBreakdownItem.fromMap(breakdownData['parking'] as Map<String, dynamic>)
          : const PaymentBreakdownItem(amount: 0, amountPaid: 0, balance: 0, isPaid: false),
      additionalChargesBreakdown: PaymentBreakdownItem.fromMap(breakdownData['additionalCharges'] as Map<String, dynamic>),
      lateFeeDetails: map.containsKey('lateFeeDetails')
          ? LateFeeDetails.fromMap(map['lateFeeDetails'] as Map<String, dynamic>)
          : LateFeeDetails(
              isLate: false,
              weeksOverdue: 0,
              lateFeePerWeek: 150.0,
              totalLateFee: 0.0,
              gracePeriodEnd: DateTime.now().add(const Duration(days: 7)),
            ),
      status: BillStatus.fromJson(map['status'] as String),
      isPaid: map['isPaid'] as bool,
      isOverdue: map['isOverdue'] as bool,
      isPartiallyPaid: map['isPartiallyPaid'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt'] as String) : null,
      generatedBy: map['generatedBy'] as String,
      notes: map['notes'] as String? ?? '',
      attachments: (map['attachments'] as List<dynamic>?)?.cast<String>() ?? [],
      receiptGenerated: map['receiptGenerated'] as bool? ?? false,
      receiptUrl: map['receiptUrl'] as String?,
      receiptGeneratedAt: map['receiptGeneratedAt'] != null
          ? DateTime.parse(map['receiptGeneratedAt'] as String)
          : null,
    );
  }

  BillModel copyWith({
    String? billId,
    String? userId,
    String? userEmail,
    String? userName,
    String? unitId,
    String? propertyId,
    BillingPeriod? billingPeriod,
    double? baseRent,
    String? rentDescription,
    UtilityCharge? electricity,
    UtilityCharge? water,
    List<AdditionalCharge>? additionalCharges,
    double? subtotal,
    double? discount,
    String? discountReason,
    double? lateFee,
    double? tax,
    double? total,
    double? amountPaid,
    double? balance,
    PaymentBreakdownItem? rentBreakdown,
    PaymentBreakdownItem? electricityBreakdown,
    PaymentBreakdownItem? waterBreakdown,
    PaymentBreakdownItem? trashBreakdown,
    PaymentBreakdownItem? wifiBreakdown,
    PaymentBreakdownItem? parkingBreakdown,
    PaymentBreakdownItem? additionalChargesBreakdown,
    LateFeeDetails? lateFeeDetails,
    BillStatus? status,
    bool? isPaid,
    bool? isOverdue,
    bool? isPartiallyPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    String? generatedBy,
    String? notes,
    List<String>? attachments,
    bool? receiptGenerated,
    String? receiptUrl,
    DateTime? receiptGeneratedAt,
  }) {
    return BillModel(
      billId: billId ?? this.billId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      unitId: unitId ?? this.unitId,
      propertyId: propertyId ?? this.propertyId,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      baseRent: baseRent ?? this.baseRent,
      rentDescription: rentDescription ?? this.rentDescription,
      electricity: electricity ?? this.electricity,
      water: water ?? this.water,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      discountReason: discountReason ?? this.discountReason,
      lateFee: lateFee ?? this.lateFee,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      amountPaid: amountPaid ?? this.amountPaid,
      balance: balance ?? this.balance,
      rentBreakdown: rentBreakdown ?? this.rentBreakdown,
      electricityBreakdown: electricityBreakdown ?? this.electricityBreakdown,
      waterBreakdown: waterBreakdown ?? this.waterBreakdown,
      trashBreakdown: trashBreakdown ?? this.trashBreakdown,
      wifiBreakdown: wifiBreakdown ?? this.wifiBreakdown,
      parkingBreakdown: parkingBreakdown ?? this.parkingBreakdown,
      additionalChargesBreakdown: additionalChargesBreakdown ?? this.additionalChargesBreakdown,
      lateFeeDetails: lateFeeDetails ?? this.lateFeeDetails,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      isOverdue: isOverdue ?? this.isOverdue,
      isPartiallyPaid: isPartiallyPaid ?? this.isPartiallyPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      generatedBy: generatedBy ?? this.generatedBy,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      receiptGenerated: receiptGenerated ?? this.receiptGenerated,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      receiptGeneratedAt: receiptGeneratedAt ?? this.receiptGeneratedAt,
    );
  }

  /// Get total additional charges amount
  double get totalAdditionalCharges {
    return additionalCharges.fold(0.0, (total, charge) => total + charge.amount);
  }

  /// Check if bill is due soon (within 3 days)
  bool get isDueSoon {
    if (isPaid) return false;
    final daysUntilDue = billingPeriod.dueDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= 3 && daysUntilDue >= 0;
  }

  /// Get days until due date
  int get daysUntilDue {
    return billingPeriod.dueDate.difference(DateTime.now()).inDays;
  }

  /// Get days overdue
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(billingPeriod.dueDate).inDays;
  }

  /// Check if tenant should be evicted (2 consecutive months unpaid)
  bool shouldEvict(List<BillModel> allBills) {
    if (isPaid) return false;

    // Sort bills by date descending
    final sortedBills = allBills
        .where((b) => b.userId == userId && !b.isPaid)
        .toList()
      ..sort((a, b) => b.billingPeriod.year != a.billingPeriod.year
          ? b.billingPeriod.year.compareTo(a.billingPeriod.year)
          : b.billingPeriod.month.compareTo(a.billingPeriod.month));

    if (sortedBills.length < 2) return false;

    // Check if current and previous month are both unpaid and overdue
    final currentBill = sortedBills[0];
    final previousBill = sortedBills[1];

    return currentBill.isOverdue &&
           previousBill.isOverdue &&
           currentBill.daysOverdue > 0 &&
           previousBill.daysOverdue > 0;
  }
}
