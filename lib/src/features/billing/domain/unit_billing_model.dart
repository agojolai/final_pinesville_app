import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/app_logger.dart';

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

/// Represents rental information for a unit
class RentalInfo {
  final double monthlyRent;
  final String status; // "occupied", "vacant", "maintenance"
  final String? tenantId;
  final String? tenantName;

  const RentalInfo({
    required this.monthlyRent,
    required this.status,
    this.tenantId,
    this.tenantName,
  });

  Map<String, dynamic> toMap() {
    return {
      'monthlyRent': monthlyRent,
      'status': status,
      if (tenantId != null) 'tenantId': tenantId,
      if (tenantName != null) 'tenantName': tenantName,
    };
  }

  factory RentalInfo.fromMap(Map<String, dynamic> map) {
    return RentalInfo(
      monthlyRent: (map['monthlyRent'] as num).toDouble(),
      status: map['status'] as String,
      tenantId: map['tenantId'] as String?,
      tenantName: map['tenantName'] as String?,
    );
  }

  RentalInfo copyWith({
    double? monthlyRent,
    String? status,
    String? tenantId,
    String? tenantName,
  }) {
    return RentalInfo(
      monthlyRent: monthlyRent ?? this.monthlyRent,
      status: status ?? this.status,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
    );
  }

  /// Check if unit is occupied
  bool get isOccupied => status == 'occupied' && tenantId != null && tenantId!.isNotEmpty;
}

/// Represents unit details
class UnitDetails {
  final List<String> amenities;
  final String description;
  final String furnishing;
  final List<String> images;
  final int maxOccupants;
  final double monthlyRent;
  final String size;
  final String unitType;

  const UnitDetails({
    required this.amenities,
    required this.description,
    required this.furnishing,
    required this.images,
    required this.maxOccupants,
    required this.monthlyRent,
    required this.size,
    required this.unitType,
  });

  Map<String, dynamic> toMap() {
    return {
      'amenities': amenities,
      'description': description,
      'furnishing': furnishing,
      'images': images,
      'maxOccupants': maxOccupants,
      'monthlyRent': monthlyRent,
      'size': size,
      'unitType': unitType,
    };
  }

  factory UnitDetails.fromMap(Map<String, dynamic> map) {
    return UnitDetails(
      amenities: List<String>.from(map['amenities'] as List? ?? []),
      description: map['description'] as String? ?? '',
      furnishing: map['furnishing'] as String? ?? '',
      images: List<String>.from(map['images'] as List? ?? []),
      maxOccupants: map['maxOccupants'] as int? ?? 1,
      monthlyRent: (map['monthlyRent'] as num?)?.toDouble() ?? 0.0,
      size: map['size'] as String? ?? '',
      unitType: map['unitType'] as String? ?? '',
    );
  }

  UnitDetails copyWith({
    List<String>? amenities,
    String? description,
    String? furnishing,
    List<String>? images,
    int? maxOccupants,
    double? monthlyRent,
    String? size,
    String? unitType,
  }) {
    return UnitDetails(
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      furnishing: furnishing ?? this.furnishing,
      images: images ?? this.images,
      maxOccupants: maxOccupants ?? this.maxOccupants,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      size: size ?? this.size,
      unitType: unitType ?? this.unitType,
    );
  }
}

/// Represents complete unit information
class UnitBillingInfo {
  final String unitId;
  final String unitNumber;
  final String propertyId;
  final UnitDetails details;
  final RentalInfo? rental;
  final LastMeterReading? lastElectricityReading;
  final LastMeterReading? lastWaterReading;
  final DateTime updatedAt;

  const UnitBillingInfo({
    required this.unitId,
    required this.unitNumber,
    required this.propertyId,
    required this.details,
    this.rental,
    this.lastElectricityReading,
    this.lastWaterReading,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'unitId': unitId,
      'unitNumber': unitNumber,
      'propertyId': propertyId,
      'details': details.toMap(),
      if (rental != null) 'rental': rental!.toMap(),
      'lastReadings': {
        if (lastElectricityReading != null) 'electricity': lastElectricityReading!.toMap(),
        if (lastWaterReading != null) 'water': lastWaterReading!.toMap(),
      },
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UnitBillingInfo.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnitBillingInfo.fromMap(data);
  }

  factory UnitBillingInfo.fromMap(Map<String, dynamic> map) {
    AppLogger.trace('UnitBillingInfo.fromMap - Raw map keys: ${map.keys.toList()}');
    AppLogger.trace('UnitBillingInfo.fromMap - Map data: $map');
    
    final detailsData = map['details'] as Map<String, dynamic>?;
    final rentalData = map['rental'] as Map<String, dynamic>?;
    final lastReadingsData = map['lastReadings'] as Map<String, dynamic>?;

    // Defensive null handling with debug info
    final unitId = map['unitId'] as String? ?? map['unitNumber'] as String? ?? 'UNKNOWN';
    final unitNumber = map['unitNumber'] as String? ?? 'UNKNOWN';
    final propertyId = map['propertyId'] as String? ?? 'UNKNOWN';
    
    AppLogger.trace('Parsed - unitId: $unitId, unitNumber: $unitNumber, propertyId: $propertyId');

    return UnitBillingInfo(
      unitId: unitId,
      unitNumber: unitNumber,
      propertyId: propertyId,
      details: detailsData != null 
          ? UnitDetails.fromMap(detailsData)
          : UnitDetails(
              amenities: [],
              description: '',
              furnishing: '',
              images: [],
              maxOccupants: 1,
              monthlyRent: 0.0,
              size: '',
              unitType: '',
            ),
      rental: rentalData != null ? RentalInfo.fromMap(rentalData) : null,
      lastElectricityReading: lastReadingsData?['electricity'] != null
          ? LastMeterReading.fromMap(lastReadingsData!['electricity'] as Map<String, dynamic>)
          : null,
      lastWaterReading: lastReadingsData?['water'] != null
          ? LastMeterReading.fromMap(lastReadingsData!['water'] as Map<String, dynamic>)
          : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : DateTime.now(),
    );
  }

  UnitBillingInfo copyWith({
    String? unitId,
    String? unitNumber,
    String? propertyId,
    UnitDetails? details,
    RentalInfo? rental,
    LastMeterReading? lastElectricityReading,
    LastMeterReading? lastWaterReading,
    DateTime? updatedAt,
  }) {
    return UnitBillingInfo(
      unitId: unitId ?? this.unitId,
      unitNumber: unitNumber ?? this.unitNumber,
      propertyId: propertyId ?? this.propertyId,
      details: details ?? this.details,
      rental: rental ?? this.rental,
      lastElectricityReading: lastElectricityReading ?? this.lastElectricityReading,
      lastWaterReading: lastWaterReading ?? this.lastWaterReading,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if unit is occupied
  bool get isOccupied => rental?.isOccupied ?? false;

  /// Get tenant ID (for backward compatibility)
  String? get tenantId => rental?.tenantId;

  /// Get tenant name
  String? get tenantName => rental?.tenantName;

  /// Get monthly rent (from rental info if available, otherwise from details)
  double get monthlyRent => rental?.monthlyRent ?? details.monthlyRent;
}
