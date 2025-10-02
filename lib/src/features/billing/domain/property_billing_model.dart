/// Represents property-specific utility rates
class PropertyUtilityRates {
  final double electricityRatePerKwh;
  final double waterRatePerCubicMeter;
  final DateTime effectiveDate;
  final String currency;

  const PropertyUtilityRates({
    required this.electricityRatePerKwh,
    required this.waterRatePerCubicMeter,
    required this.effectiveDate,
    this.currency = 'PHP',
  });

  Map<String, dynamic> toMap() {
    return {
      'electricity': {
        'ratePerKwh': electricityRatePerKwh,
        'effectiveDate': effectiveDate.toIso8601String(),
        'currency': currency,
      },
      'water': {
        'ratePerCubicMeter': waterRatePerCubicMeter,
        'effectiveDate': effectiveDate.toIso8601String(),
        'currency': currency,
      },
    };
  }

  factory PropertyUtilityRates.fromMap(Map<String, dynamic> map) {
    final electricityData = map['electricity'] as Map<String, dynamic>;
    final waterData = map['water'] as Map<String, dynamic>;

    return PropertyUtilityRates(
      electricityRatePerKwh: (electricityData['ratePerKwh'] as num).toDouble(),
      waterRatePerCubicMeter: (waterData['ratePerCubicMeter'] as num).toDouble(),
      effectiveDate: DateTime.parse(electricityData['effectiveDate'] as String),
      currency: electricityData['currency'] as String? ?? 'PHP',
    );
  }

  PropertyUtilityRates copyWith({
    double? electricityRatePerKwh,
    double? waterRatePerCubicMeter,
    DateTime? effectiveDate,
    String? currency,
  }) {
    return PropertyUtilityRates(
      electricityRatePerKwh: electricityRatePerKwh ?? this.electricityRatePerKwh,
      waterRatePerCubicMeter: waterRatePerCubicMeter ?? this.waterRatePerCubicMeter,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      currency: currency ?? this.currency,
    );
  }
}

/// Represents a fixed charge (trash, wifi, etc.)
class FixedCharge {
  final String category;
  final double amount;
  final bool enabled;
  final String description;

  const FixedCharge({
    required this.category,
    required this.amount,
    required this.enabled,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'enabled': enabled,
      'description': description,
    };
  }

  factory FixedCharge.fromMap(String category, Map<String, dynamic> map) {
    return FixedCharge(
      category: category,
      amount: (map['amount'] as num).toDouble(),
      enabled: map['enabled'] as bool? ?? true,
      description: map['description'] as String,
    );
  }

  FixedCharge copyWith({
    String? category,
    double? amount,
    bool? enabled,
    String? description,
  }) {
    return FixedCharge(
      category: category ?? this.category,
      amount: amount ?? this.amount,
      enabled: enabled ?? this.enabled,
      description: description ?? this.description,
    );
  }
}
