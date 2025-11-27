import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the leases subcollection under Users collection
/// Path: Users/{userId}/leases/{leaseId}
class LeaseModel {
  final String? leaseId; // Document ID in Firestore
  final DateTime createdAt;
  final String currentTenantId;
  final DateTime leaseEndDate;
  final DateTime leaseStartDate;
  final int monthsBasedOnContract; // 6, 9, or 12 months
  final String pdfDocumentName; // e.g., 'blank contract.pdf'
  final String pdfDocumentUrl; // Firebase Storage URL
  final String propertyId;
  final String propertyName;
  final double rentAmount;
  final int? renewalOptions; // 0 for move-out, 3/6/9 for renewal months, null if unset
  final double securityDeposit;
  final String tenantName;
  final String unitId;

  const LeaseModel({
    this.leaseId,
    required this.createdAt,
    required this.currentTenantId,
    required this.leaseEndDate,
    required this.leaseStartDate,
    required this.monthsBasedOnContract,
    required this.pdfDocumentName,
    required this.pdfDocumentUrl,
    required this.propertyId,
    required this.propertyName,
    required this.rentAmount,
    this.renewalOptions,
    required this.securityDeposit,
    required this.tenantName,
    required this.unitId,
  });

  /// Create empty lease model
  static LeaseModel empty() => LeaseModel(
        leaseId: '',
        createdAt: DateTime.now(),
        currentTenantId: '',
        leaseEndDate: DateTime.now(),
        leaseStartDate: DateTime.now(),
        monthsBasedOnContract: 6,
        pdfDocumentName: '',
        pdfDocumentUrl: '',
        propertyId: '',
        propertyName: '',
        rentAmount: 0.0,
        renewalOptions: null,
        securityDeposit: 0.0,
        tenantName: '',
        unitId: '',
      );

  /// Convert model to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'currentTenantId': currentTenantId,
      'leaseEndDate': leaseEndDate.toIso8601String(),
      'leaseStartDate': leaseStartDate.toIso8601String(),
      'monthsBasedOnContract': monthsBasedOnContract,
      'pdfDocumentName': pdfDocumentName,
      'pdfDocumentUrl': pdfDocumentUrl,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'rentAmount': rentAmount,
      'renewalOptions': renewalOptions,
      'securityDeposit': securityDeposit,
      'tenantName': tenantName,
      'unitId': unitId,
    };
  }

  /// Create model from Firestore snapshot
  factory LeaseModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return LeaseModel.fromJson(data, snapshot.id);
  }

  /// Create model from JSON map
  factory LeaseModel.fromJson(Map<String, dynamic> json, [String? id]) {
    return LeaseModel(
      leaseId: id,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      currentTenantId: json['currentTenantId'] ?? '',
      leaseEndDate: _parseDateTime(json['leaseEndDate']) ?? DateTime.now(),
      leaseStartDate: _parseDateTime(json['leaseStartDate']) ?? DateTime.now(),
      monthsBasedOnContract: json['monthsBasedOnContract'] ?? 6,
      pdfDocumentName: json['pdfDocumentName'] ?? '',
      pdfDocumentUrl: json['pdfDocumentUrl'] ?? '',
      propertyId: json['propertyId'] ?? '',
      propertyName: json['propertyName'] ?? '',
      rentAmount: (json['rentAmount'] ?? 0).toDouble(),
      renewalOptions: json['renewalOptions'],
      securityDeposit: (json['securityDeposit'] ?? 0).toDouble(),
      tenantName: json['tenantName'] ?? '',
      unitId: json['unitId'] ?? '',
    );
  }

  /// Helper method to parse DateTime from either Timestamp or ISO8601 string
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    // Handle Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // Handle ISO8601 string
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  /// Create a copy with modified fields
  LeaseModel copyWith({
    String? leaseId,
    DateTime? createdAt,
    String? currentTenantId,
    DateTime? leaseEndDate,
    DateTime? leaseStartDate,
    int? monthsBasedOnContract,
    String? pdfDocumentName,
    String? pdfDocumentUrl,
    String? propertyId,
    String? propertyName,
    double? rentAmount,
    int? renewalOptions,
    bool resetRenewalOptions = false, // Flag to explicitly set renewalOptions to null
    double? securityDeposit,
    String? tenantName,
    String? unitId,
  }) {
    return LeaseModel(
      leaseId: leaseId ?? this.leaseId,
      createdAt: createdAt ?? this.createdAt,
      currentTenantId: currentTenantId ?? this.currentTenantId,
      leaseEndDate: leaseEndDate ?? this.leaseEndDate,
      leaseStartDate: leaseStartDate ?? this.leaseStartDate,
      monthsBasedOnContract: monthsBasedOnContract ?? this.monthsBasedOnContract,
      pdfDocumentName: pdfDocumentName ?? this.pdfDocumentName,
      pdfDocumentUrl: pdfDocumentUrl ?? this.pdfDocumentUrl,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      rentAmount: rentAmount ?? this.rentAmount,
      renewalOptions: resetRenewalOptions ? null : (renewalOptions ?? this.renewalOptions),
      securityDeposit: securityDeposit ?? this.securityDeposit,
      tenantName: tenantName ?? this.tenantName,
      unitId: unitId ?? this.unitId,
    );
  }

  @override
  String toString() {
    return 'LeaseModel(leaseId: $leaseId, tenantName: $tenantName, propertyName: $propertyName, leaseStartDate: $leaseStartDate, leaseEndDate: $leaseEndDate)';
  }
}
