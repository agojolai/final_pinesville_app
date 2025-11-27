import 'package:cloud_firestore/cloud_firestore.dart';

/// Feedback categories for move-out decisions
enum MoveOutReason {
  rentTooHigh('RENT_TOO_HIGH', 'Rent Too High'),
  relocatingWork('RELOCATING_WORK', 'Relocating for Work'),
  boughtHouse('BOUGHT_HOUSE', 'Bought a House'),
  maintenanceIssues('MAINTENANCE_ISSUES', 'Maintenance Issues'),
  unitTooSmall('UNIT_TOO_SMALL', 'Unit Too Small'),
  personalIssues('FOR_PERSONAL_ISSUES', 'Personal Issues'),
  others('OTHERS', 'Others');

  final String code;
  final String label;
  const MoveOutReason(this.code, this.label);
}

/// Feedback categories for renewal decisions
enum RenewalReason {
  locationConvenience('LOCATION_CONVENIENCE', 'Location Convenience'),
  goodManagement('GOOD_MANAGEMENT', 'Good Management'),
  priceValue('PRICE_VALUE', 'Price Value'),
  unitComfort('UNIT_COMFORT', 'Unit Comfort'),
  communityVibe('COMMUNITY_VIBE', 'Community Vibe'),
  personalIssues('FOR_PERSONAL_ISSUES', 'Personal Issues'),
  others('OTHERS', 'Others');

  final String code;
  final String label;
  const RenewalReason(this.code, this.label);
}

/// Lease decision analytics model for business intelligence
class LeaseAnalyticsModel {
  final String analyticsId;
  final String tenantId;
  final String propertyName;
  final String unitId;
  final DateTime decisionDate;
  final String decisionType; // 'renew' or 'move_out'
  final bool isEarlyTermination;
  final DateTime previousLeaseEndDate;
  final int? renewalMonths; // null if move_out
  final String primaryReasonCategory;
  final String? feedbackNote;
  final String unitType; // e.g., 'studio', '1BR', '2BR'

  const LeaseAnalyticsModel({
    required this.analyticsId,
    required this.tenantId,
    required this.propertyName,
    required this.unitId,
    required this.decisionDate,
    required this.decisionType,
    required this.isEarlyTermination,
    required this.previousLeaseEndDate,
    this.renewalMonths,
    required this.primaryReasonCategory,
    this.feedbackNote,
    required this.unitType,
  });

  /// Create LeaseAnalyticsModel from Firestore document
  factory LeaseAnalyticsModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaseAnalyticsModel(
      analyticsId: doc.id,
      tenantId: data['tenantId'] ?? '',
      propertyName: data['propertyName'] ?? '',
      unitId: data['unitId'] ?? '',
      decisionDate: (data['decisionDate'] as Timestamp).toDate(),
      decisionType: data['decisionType'] ?? '',
      isEarlyTermination: data['isEarlyTermination'] ?? false,
      previousLeaseEndDate: (data['previousLeaseEndDate'] as Timestamp).toDate(),
      renewalMonths: data['renewalMonths'],
      primaryReasonCategory: data['primaryReasonCategory'] ?? '',
      feedbackNote: data['feedbackNote'],
      unitType: data['unitType'] ?? '',
    );
  }

  /// Convert model to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'propertyName': propertyName,
      'unitId': unitId,
      'decisionDate': Timestamp.fromDate(decisionDate),
      'decisionType': decisionType,
      'isEarlyTermination': isEarlyTermination,
      'previousLeaseEndDate': Timestamp.fromDate(previousLeaseEndDate),
      'renewalMonths': renewalMonths,
      'primaryReasonCategory': primaryReasonCategory,
      'feedbackNote': feedbackNote,
      'unitType': unitType,
    };
  }

  /// Create a copy with updated fields
  LeaseAnalyticsModel copyWith({
    String? analyticsId,
    String? tenantId,
    String? propertyName,
    String? unitId,
    DateTime? decisionDate,
    String? decisionType,
    bool? isEarlyTermination,
    DateTime? previousLeaseEndDate,
    int? renewalMonths,
    String? primaryReasonCategory,
    String? feedbackNote,
    String? unitType,
  }) {
    return LeaseAnalyticsModel(
      analyticsId: analyticsId ?? this.analyticsId,
      tenantId: tenantId ?? this.tenantId,
      propertyName: propertyName ?? this.propertyName,
      unitId: unitId ?? this.unitId,
      decisionDate: decisionDate ?? this.decisionDate,
      decisionType: decisionType ?? this.decisionType,
      isEarlyTermination: isEarlyTermination ?? this.isEarlyTermination,
      previousLeaseEndDate: previousLeaseEndDate ?? this.previousLeaseEndDate,
      renewalMonths: renewalMonths ?? this.renewalMonths,
      primaryReasonCategory: primaryReasonCategory ?? this.primaryReasonCategory,
      feedbackNote: feedbackNote ?? this.feedbackNote,
      unitType: unitType ?? this.unitType,
    );
  }
}
