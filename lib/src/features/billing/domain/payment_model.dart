import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment type enum
enum PaymentType {
  full,
  partial;

  String toJson() => name;

  static PaymentType fromJson(String value) {
    return value == 'full' ? PaymentType.full : PaymentType.partial;
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  String toJson() => name;

  static PaymentStatus fromJson(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Payment verification status enum
enum PaymentVerificationStatus {
  pendingVerification,
  verified,
  rejected;

  String toJson() {
    switch (this) {
      case PaymentVerificationStatus.pendingVerification:
        return 'pending_verification';
      case PaymentVerificationStatus.verified:
        return 'verified';
      case PaymentVerificationStatus.rejected:
        return 'rejected';
    }
  }

  static PaymentVerificationStatus fromJson(String value) {
    switch (value) {
      case 'pending_verification':
      case 'pendingVerification':
        return PaymentVerificationStatus.pendingVerification;
      case 'verified':
        return PaymentVerificationStatus.verified;
      case 'rejected':
        return PaymentVerificationStatus.rejected;
      default:
        return PaymentVerificationStatus.pendingVerification;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentVerificationStatus.pendingVerification:
        return 'Pending Verification';
      case PaymentVerificationStatus.verified:
        return 'Verified';
      case PaymentVerificationStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Payment method enum
enum PaymentMethod {
  gcash,
  bdo,
  cash,
  bankTransfer,
  gotyme,
  creditCard;

  String toJson() {
    switch (this) {
      case PaymentMethod.gcash:
        return 'gcash';
      case PaymentMethod.bdo:
        return 'bdo';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.gotyme:
        return 'gotyme';
      case PaymentMethod.creditCard:
        return 'credit_card';
    }
  }

  static PaymentMethod fromJson(String value) {
    switch (value) {
      case 'gcash':
        return PaymentMethod.gcash;
      case 'bdo':
        return PaymentMethod.bdo;
      case 'cash':
        return PaymentMethod.cash;
      case 'gotyme':
        return PaymentMethod.gotyme;
      case 'bank_transfer':
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      case 'credit_card':
      case 'creditCard':
        return PaymentMethod.creditCard;
      default:
        return PaymentMethod.cash;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.gcash:
        return 'GCash';
      case PaymentMethod.bdo:
        return 'BDO';
      case PaymentMethod.gotyme:
        return 'Gotyme';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.creditCard:
        return 'Credit Card';
    }
  }
}

/// Payment category enum
enum PaymentCategory {
  rent,
  electricity,
  water,
  trash,
  wifi,
  parking,
  additionalCharges;

  String toJson() {
    switch (this) {
      case PaymentCategory.rent:
        return 'rent';
      case PaymentCategory.electricity:
        return 'electricity';
      case PaymentCategory.water:
        return 'water';
      case PaymentCategory.trash:
        return 'trash';
      case PaymentCategory.wifi:
        return 'wifi';
      case PaymentCategory.parking:
        return 'parking';
      case PaymentCategory.additionalCharges:
        return 'additionalCharges';
    }
  }

  static PaymentCategory fromJson(String value) {
    switch (value) {
      case 'rent':
        return PaymentCategory.rent;
      case 'electricity':
        return PaymentCategory.electricity;
      case 'water':
        return PaymentCategory.water;
      case 'trash':
        return PaymentCategory.trash;
      case 'wifi':
        return PaymentCategory.wifi;
      case 'parking':
        return PaymentCategory.parking;
      case 'additionalCharges':
        return PaymentCategory.additionalCharges;
      default:
        return PaymentCategory.rent;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentCategory.rent:
        return 'Rent';
      case PaymentCategory.electricity:
        return 'Electricity';
      case PaymentCategory.water:
        return 'Water';
      case PaymentCategory.trash:
        return 'Trash';
      case PaymentCategory.wifi:
        return 'WiFi';
      case PaymentCategory.parking:
        return 'Parking';
      case PaymentCategory.additionalCharges:
        return 'Additional Charges';
    }
  }
}

/// Represents allocation for a payment category
class PaymentAllocationItem {
  final double amount;
  final DateTime? appliedAt;

  const PaymentAllocationItem({
    required this.amount,
    this.appliedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'appliedAt': appliedAt?.toIso8601String(),
    };
  }

  factory PaymentAllocationItem.fromMap(Map<String, dynamic> map) {
    return PaymentAllocationItem(
      amount: (map['amount'] as num).toDouble(),
      appliedAt: map['appliedAt'] != null ? DateTime.parse(map['appliedAt'] as String) : null,
    );
  }
}

/// Represents a payment transaction
class PaymentModel {
  final String paymentId;
  final String billId;
  final String userId;
  final String userEmail;
  final String userName;
  final String unitId;
  final int billingMonth; // Billing period month (1-12)
  final int billingYear;  // Billing period year
  final double amount;
  final PaymentType paymentType;
  final PaymentMethod paymentMethod;
  final PaymentAllocationItem rentAllocation;
  final PaymentAllocationItem electricityAllocation;
  final PaymentAllocationItem waterAllocation;
  final PaymentAllocationItem trashAllocation;
  final PaymentAllocationItem wifiAllocation;
  final PaymentAllocationItem parkingAllocation;
  final PaymentAllocationItem additionalChargesAllocation;
  final List<PaymentCategory> paidFor;
  final DateTime transactionDate;
  final String receiptNumber;
  final PaymentStatus status;
  final PaymentVerificationStatus paymentStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? proofOfPaymentUrl;
  final DateTime? proofUploadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String notes;
  final String adminNotes;

  const PaymentModel({
    required this.paymentId,
    required this.billId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.unitId,
    required this.billingMonth,
    required this.billingYear,
    required this.amount,
    required this.paymentType,
    required this.paymentMethod,
    required this.rentAllocation,
    required this.electricityAllocation,
    required this.waterAllocation,
    required this.trashAllocation,
    required this.wifiAllocation,
    required this.parkingAllocation,
    required this.additionalChargesAllocation,
    required this.paidFor,
    required this.transactionDate,
    required this.receiptNumber,
    required this.status,
    required this.paymentStatus,
    this.verifiedBy,
    this.verifiedAt,
    this.proofOfPaymentUrl,
    this.proofUploadedAt,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.adminNotes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'billId': billId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'unitId': unitId,
      'billingMonth': billingMonth,
      'billingYear': billingYear,
      'amount': amount,
      'paymentType': paymentType.toJson(),
      'paymentMethod': paymentMethod.toJson(),
      'paymentAllocation': {
        'rent': rentAllocation.toMap(),
        'electricity': electricityAllocation.toMap(),
        'water': waterAllocation.toMap(),
        'trash': trashAllocation.toMap(),
        'wifi': wifiAllocation.toMap(),
        'parking': parkingAllocation.toMap(),
        'additionalCharges': additionalChargesAllocation.toMap(),
      },
      'paidFor': paidFor.map((c) => c.toJson()).toList(),
      'transactionDate': transactionDate.toIso8601String(),
      'receiptNumber': receiptNumber,
      'status': status.toJson(),
      'paymentStatus': paymentStatus.toJson(),
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'proofOfPayment': proofOfPaymentUrl != null
          ? {
              'imageUrl': proofOfPaymentUrl,
              'uploadedAt': proofUploadedAt?.toIso8601String(),
            }
          : null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'adminNotes': adminNotes,
    };
  }

  factory PaymentModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel.fromMap(data);
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    final allocationData = map['paymentAllocation'] as Map<String, dynamic>?;
    final proofData = map['proofOfPayment'] as Map<String, dynamic>?;

    return PaymentModel(
      paymentId: map['paymentId'] as String,
      billId: map['billId'] as String,
      userId: map['userId'] as String,
      userEmail: map['userEmail'] as String,
      userName: map['userName'] as String,
      unitId: map['unitId'] as String,
      billingMonth: map['billingMonth'] as int? ?? 1, // Default to January if missing (legacy data)
      billingYear: map['billingYear'] as int? ?? DateTime.now().year, // Default to current year if missing
      amount: (map['amount'] as num).toDouble(),
      paymentType: PaymentType.fromJson(map['paymentType'] as String),
      paymentMethod: PaymentMethod.fromJson(map['paymentMethod'] as String),
      rentAllocation: allocationData != null && allocationData.containsKey('rent')
          ? PaymentAllocationItem.fromMap(allocationData['rent'] as Map<String, dynamic>)
          : const PaymentAllocationItem(amount: 0.0),
      electricityAllocation: allocationData != null && allocationData.containsKey('electricity')
          ? PaymentAllocationItem.fromMap(allocationData['electricity'] as Map<String, dynamic>)
          : const PaymentAllocationItem(amount: 0.0),
      waterAllocation: allocationData != null && allocationData.containsKey('water')
          ? PaymentAllocationItem.fromMap(allocationData['water'] as Map<String, dynamic>)
          : const PaymentAllocationItem(amount: 0.0),
      trashAllocation: allocationData != null && allocationData.containsKey('trash') 
          ? PaymentAllocationItem.fromMap(allocationData['trash'] as Map<String, dynamic>)
          : const PaymentAllocationItem(amount: 0.0),
      wifiAllocation: allocationData != null && allocationData.containsKey('wifi')
          ? PaymentAllocationItem.fromMap(allocationData['wifi'] as Map<String, dynamic>)
          : const PaymentAllocationItem(amount: 0.0),
      parkingAllocation: allocationData != null && allocationData.containsKey('parking')
          ? PaymentAllocationItem.fromMap(allocationData['parking'] as Map<String, dynamic>)
          : const PaymentAllocationItem(amount: 0.0),
      additionalChargesAllocation: allocationData != null && allocationData.containsKey('additionalCharges')
          ? PaymentAllocationItem.fromMap(allocationData['additionalCharges'] as Map<String, dynamic>)
          : const PaymentAllocationItem(amount: 0.0),
      paidFor: (map['paidFor'] as List<dynamic>)
          .map((c) => PaymentCategory.fromJson(c as String))
          .toList(),
      transactionDate: DateTime.parse(map['transactionDate'] as String),
      receiptNumber: map['receiptNumber'] as String,
      status: PaymentStatus.fromJson(map['status'] as String),
      paymentStatus: PaymentVerificationStatus.fromJson(map['paymentStatus'] as String),
      verifiedBy: map['verifiedBy'] as String?,
      verifiedAt: map['verifiedAt'] != null ? DateTime.parse(map['verifiedAt'] as String) : null,
      proofOfPaymentUrl: proofData?['imageUrl'] as String?,
      proofUploadedAt: proofData?['uploadedAt'] != null ? DateTime.parse(proofData!['uploadedAt'] as String) : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      notes: map['notes'] as String? ?? '',
      adminNotes: map['adminNotes'] as String? ?? '',
    );
  }

  PaymentModel copyWith({
    String? paymentId,
    String? billId,
    String? userId,
    String? userEmail,
    String? userName,
    String? unitId,
    int? billingMonth,
    int? billingYear,
    double? amount,
    PaymentType? paymentType,
    PaymentMethod? paymentMethod,
    PaymentAllocationItem? rentAllocation,
    PaymentAllocationItem? electricityAllocation,
    PaymentAllocationItem? waterAllocation,
    PaymentAllocationItem? trashAllocation,
    PaymentAllocationItem? wifiAllocation,
    PaymentAllocationItem? parkingAllocation,
    PaymentAllocationItem? additionalChargesAllocation,
    List<PaymentCategory>? paidFor,
    DateTime? transactionDate,
    String? receiptNumber,
    PaymentStatus? status,
    PaymentVerificationStatus? paymentStatus,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? proofOfPaymentUrl,
    DateTime? proofUploadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? adminNotes,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      billId: billId ?? this.billId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      unitId: unitId ?? this.unitId,
      billingMonth: billingMonth ?? this.billingMonth,
      billingYear: billingYear ?? this.billingYear,
      amount: amount ?? this.amount,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rentAllocation: rentAllocation ?? this.rentAllocation,
      electricityAllocation: electricityAllocation ?? this.electricityAllocation,
      waterAllocation: waterAllocation ?? this.waterAllocation,
      trashAllocation: trashAllocation ?? this.trashAllocation,
      wifiAllocation: wifiAllocation ?? this.wifiAllocation,
      parkingAllocation: parkingAllocation ?? this.parkingAllocation,
      additionalChargesAllocation: additionalChargesAllocation ?? this.additionalChargesAllocation,
      paidFor: paidFor ?? this.paidFor,
      transactionDate: transactionDate ?? this.transactionDate,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      proofOfPaymentUrl: proofOfPaymentUrl ?? this.proofOfPaymentUrl,
      proofUploadedAt: proofUploadedAt ?? this.proofUploadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  /// Check if payment is verified
  bool get isVerified => paymentStatus == PaymentVerificationStatus.verified;

  /// Check if payment is pending verification
  bool get isPendingVerification => paymentStatus == PaymentVerificationStatus.pendingVerification;

  /// Check if payment was rejected
  bool get isRejected => paymentStatus == PaymentVerificationStatus.rejected;
  
  /// Get formatted billing period (e.g., "October 2025")
  String get formattedBillingPeriod {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[billingMonth]} $billingYear';
  }
}
