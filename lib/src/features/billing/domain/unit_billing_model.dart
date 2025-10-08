import 'package:cloud_firestore/cloud_firestore.dart';

//THIS FILE IS FOR UNIT MODEL SUBCOLLECTION INSIDE THE PROPERTY COLLECTION

/// Represents the last meter reading for a utility
class LastMeterReading {
  final double reading;
  final DateTime readingDate;
  final String meterNumber;

  const LastMeterReading({
    required this.reading,
    required this.readingDate,
    required this.meterNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'reading': reading,
      'readingDate': readingDate.toIso8601String(),
      'meterNumber': meterNumber,
    };
  }

  factory LastMeterReading.fromMap(Map<String, dynamic> map) {
    return LastMeterReading(
      reading: (map['reading'] as num).toDouble(),
      readingDate: DateTime.parse(map['readingDate'] as String),
      meterNumber: map['meterNumber'] as String,
    );
  }

  LastMeterReading copyWith({
    double? reading,
    DateTime? readingDate,
    String? meterNumber,
  }) {
    return LastMeterReading(
      reading: reading ?? this.reading,
      readingDate: readingDate ?? this.readingDate,
      meterNumber: meterNumber ?? this.meterNumber,
    );
  }
}

/// Represents unit billing information
class UnitBillingInfo {
  final String unitId;
  final String unitNumber;
  final String propertyId;
  final double monthlyRent;
  final String? tenantId;
  final LastMeterReading? lastElectricityReading;
  final LastMeterReading? lastWaterReading;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UnitBillingInfo({
    required this.unitId,
    required this.unitNumber,
    required this.propertyId,
    required this.monthlyRent,
    this.tenantId,
    this.lastElectricityReading,
    this.lastWaterReading,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'unitId': unitId,
      'unitNumber': unitNumber,
      'propertyId': propertyId,
      'rental': {
        'monthlyRent': monthlyRent,
        'status': tenantId != null ? 'occupied' : 'vacant',
        'tenantId': tenantId,
      },
      'lastReadings': {
        'electricity': lastElectricityReading?.toMap(),
        'water': lastWaterReading?.toMap(),
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UnitBillingInfo.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnitBillingInfo.fromMap(data);
  }

  factory UnitBillingInfo.fromMap(Map<String, dynamic> map) {
    print('🔍 UnitBillingInfo.fromMap - Raw map keys: ${map.keys.toList()}');
    print('🔍 UnitBillingInfo.fromMap - Map data: $map');
    
    final rentalData = map['rental'] as Map<String, dynamic>?;
    final lastReadingsData = map['lastReadings'] as Map<String, dynamic>?;

    // Defensive null handling with debug info
    final unitId = map['unitId'] as String? ?? map['unitNumber'] as String? ?? 'UNKNOWN';
    final unitNumber = map['unitNumber'] as String? ?? 'UNKNOWN';
    final propertyId = map['propertyId'] as String? ?? 'UNKNOWN';
    
    print('🔍 Parsed - unitId: $unitId, unitNumber: $unitNumber, propertyId: $propertyId');

    return UnitBillingInfo(
      unitId: unitId,
      unitNumber: unitNumber,
      propertyId: propertyId,
      monthlyRent: (rentalData?['monthlyRent'] as num?)?.toDouble() ?? 0.0,
      tenantId: rentalData?['tenantId'] as String?,
      lastElectricityReading: lastReadingsData?['electricity'] != null
          ? LastMeterReading.fromMap(lastReadingsData!['electricity'] as Map<String, dynamic>)
          : null,
      lastWaterReading: lastReadingsData?['water'] != null
          ? LastMeterReading.fromMap(lastReadingsData!['water'] as Map<String, dynamic>)
          : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }

  UnitBillingInfo copyWith({
    String? unitId,
    String? unitNumber,
    String? propertyId,
    double? monthlyRent,
    String? tenantId,
    LastMeterReading? lastElectricityReading,
    LastMeterReading? lastWaterReading,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnitBillingInfo(
      unitId: unitId ?? this.unitId,
      unitNumber: unitNumber ?? this.unitNumber,
      propertyId: propertyId ?? this.propertyId,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      tenantId: tenantId ?? this.tenantId,
      lastElectricityReading: lastElectricityReading ?? this.lastElectricityReading,
      lastWaterReading: lastWaterReading ?? this.lastWaterReading,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if unit is occupied
  bool get isOccupied => tenantId != null && tenantId!.isNotEmpty;
}
