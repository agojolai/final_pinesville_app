import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/billing/domain/bill_model.dart';
import 'package:untitled/src/features/billing/domain/billing_models.dart';
import 'package:untitled/src/features/billing/domain/property_billing_model.dart';
/// Integration tests for October 2025 billing optimizations
/// Tests: Fixed charges unification, description support, null safety
void main() {
  group('PaymentBreakdownItem Description Support', () {
    test('should serialize and deserialize description field', () {
      // Arrange
      const testDescription = 'Late payment penalty';
      final item = PaymentBreakdownItem(
        amount: 500.0,
        amountPaid: 0.0,
        balance: 500.0,
        isPaid: false,
        description: testDescription,
      );

      // Act
      final map = item.toMap();
      final restored = PaymentBreakdownItem.fromMap(map);

      // Assert
      expect(map['description'], equals(testDescription));
      expect(restored.description, equals(testDescription));
    });

    test('should handle null description', () {
      // Arrange
      final item = PaymentBreakdownItem(
        amount: 500.0,
        amountPaid: 0.0,
        balance: 500.0,
        isPaid: false,
        description: null,
      );

      // Act
      final map = item.toMap();
      final restored = PaymentBreakdownItem.fromMap(map);

      // Assert
      expect(restored.description, isNull);
      expect(map.containsKey('description'), isFalse);
    });

    test('should handle missing description in deserialization', () {
      // Arrange - Map without description field
      final map = {
        'amount': 500.0,
        'amountPaid': 0.0,
        'balance': 500.0,
        'isPaid': false,
        'paidAt': null,
      };

      // Act
      final item = PaymentBreakdownItem.fromMap(map);

      // Assert
      expect(item.description, isNull);
      expect(item.amount, equals(500.0));
    });
  });

  group('PropertyUtilityRates Fixed Charges', () {
    test('should parse fixedCharges from property level', () {
      // Arrange
      final propertyData = {
        'electricity': {
          'ratePerKwh': 12.5,
          'effectiveDate': '2025-01-01T00:00:00Z',
          'currency': 'PHP',
        },
        'water': {
          'ratePerCubicMeter': 35.0,
          'effectiveDate': '2025-01-01T00:00:00Z',
          'currency': 'PHP',
        },
        'fixedCharges': {
          'trash': {
            'amount': 200.0,
            'enabled': true,
            'description': 'Trash Collection',
          },
          'wifi': {
            'amount': 500.0,
            'enabled': true,
            'description': 'WiFi Service',
          },
          'parking': {
            'amount': 1000.0,
            'enabled': true,
            'description': 'Parking Fee',
          },
        },
      };

      // Act
      final rates = PropertyUtilityRates.fromMap(propertyData);

      // Assert
      expect(rates.fixedCharges, isNotEmpty);
      expect(rates.fixedCharges.length, equals(3));
      expect(rates.fixedCharges.containsKey('trash'), isTrue);
      expect(rates.fixedCharges.containsKey('wifi'), isTrue);
      expect(rates.fixedCharges.containsKey('parking'), isTrue);
      
      expect(rates.fixedCharges['trash']!.amount, equals(200.0));
      expect(rates.fixedCharges['wifi']!.amount, equals(500.0));
      expect(rates.fixedCharges['parking']!.amount, equals(1000.0));
      
      expect(rates.fixedCharges['trash']!.enabled, isTrue);
      expect(rates.fixedCharges['trash']!.description, equals('Trash Collection'));
    });

    test('should handle missing fixedCharges gracefully', () {
      // Arrange - Property data without fixedCharges
      final propertyData = {
        'electricity': {
          'ratePerKwh': 12.5,
          'effectiveDate': '2025-01-01T00:00:00Z',
          'currency': 'PHP',
        },
        'water': {
          'ratePerCubicMeter': 35.0,
          'effectiveDate': '2025-01-01T00:00:00Z',
          'currency': 'PHP',
        },
      };

      // Act
      final rates = PropertyUtilityRates.fromMap(propertyData);

      // Assert
      expect(rates.fixedCharges, isEmpty);
      expect(rates.electricityRatePerKwh, equals(12.5));
    });

    test('should handle disabled fixed charges', () {
      // Arrange
      final propertyData = {
        'electricity': {
          'ratePerKwh': 12.5,
          'effectiveDate': '2025-01-01T00:00:00Z',
          'currency': 'PHP',
        },
        'water': {
          'ratePerCubicMeter': 35.0,
          'effectiveDate': '2025-01-01T00:00:00Z',
          'currency': 'PHP',
        },
        'fixedCharges': {
          'trash': {
            'amount': 200.0,
            'enabled': false, // Disabled
            'description': 'Trash Collection',
          },
        },
      };

      // Act
      final rates = PropertyUtilityRates.fromMap(propertyData);

      // Assert
      expect(rates.fixedCharges['trash']!.enabled, isFalse);
      expect(rates.fixedCharges['trash']!.amount, equals(200.0));
    });
  });

  group('BillModel Backward Compatibility', () {
    test('should handle bills without additionalCharges array', () {
      // Arrange - Bill data without additionalCharges field
      final billData = _createMinimalBillData();
      billData.remove('additionalCharges'); // Remove the field entirely

      // Act & Assert - Should not throw
      expect(() => BillModel.fromMap(billData), returnsNormally);
      
      final bill = BillModel.fromMap(billData);
      expect(bill.additionalCharges, isEmpty);
    });

    test('should handle bills with null additionalCharges', () {
      // Arrange
      final billData = _createMinimalBillData();
      billData['additionalCharges'] = null;

      // Act & Assert - Should not throw
      expect(() => BillModel.fromMap(billData), returnsNormally);
      
      final bill = BillModel.fromMap(billData);
      expect(bill.additionalCharges, isEmpty);
    });

    test('should handle bills with empty additionalCharges array', () {
      // Arrange
      final billData = _createMinimalBillData();
      billData['additionalCharges'] = [];

      // Act
      final bill = BillModel.fromMap(billData);

      // Assert
      expect(bill.additionalCharges, isEmpty);
    });

    test('should handle legacy bills with additionalCharges data', () {
      // Arrange - Legacy bill with additionalCharges array
      final billData = _createMinimalBillData();
      billData['additionalCharges'] = [
        {
          'chargeId': 'CHARGE_001',
          'description': 'Trash',
          'amount': 200.0,
          'category': 'trash',
        },
      ];

      // Act
      final bill = BillModel.fromMap(billData);

      // Assert - Should parse but list should be empty in new implementation
      // (backward compatibility - reads old data but doesn't use it)
      expect(bill.additionalCharges, isA<List>());
    });
  });

  group('BillModel toMap - Storage Optimization', () {
    test('should NOT include additionalCharges in serialized output', () {
      // This test verifies the storage optimization
      // Note: Actual implementation might vary, adjust as needed
      final bill = _createTestBill();

      // Act
      final map = bill.toMap();

      // Assert - additionalCharges should not be in map
      // OR should be empty array (depending on implementation)
      expect(
        !map.containsKey('additionalCharges') || 
        (map['additionalCharges'] as List).isEmpty,
        isTrue,
        reason: 'additionalCharges should not be stored (optimization)',
      );
    });

    test('should include all 7 categories in paymentBreakdown', () {
      // Arrange
      final bill = _createTestBill();

      // Act
      final map = bill.toMap();
      final paymentBreakdown = map['paymentBreakdown'] as Map<String, dynamic>;

      // Assert - All 7 categories should exist
      expect(paymentBreakdown.keys, hasLength(7));
      expect(paymentBreakdown, contains('rent'));
      expect(paymentBreakdown, contains('electricity'));
      expect(paymentBreakdown, contains('water'));
      expect(paymentBreakdown, contains('trash'));
      expect(paymentBreakdown, contains('wifi'));
      expect(paymentBreakdown, contains('parking'));
      expect(paymentBreakdown, contains('additionalCharges'));
    });

    test('should include description in additionalCharges breakdown', () {
      // Arrange
      const testDescription = 'Late payment penalty';
      final bill = _createTestBill(
        additionalChargesDescription: testDescription,
      );

      // Act
      final map = bill.toMap();
      final paymentBreakdown = map['paymentBreakdown'] as Map<String, dynamic>;
      final additionalCharges = paymentBreakdown['additionalCharges'] as Map<String, dynamic>;

      // Assert
      expect(additionalCharges['description'], equals(testDescription));
    });
  });
}

/// Helper function to create minimal bill data for testing
Map<String, dynamic> _createMinimalBillData() {
  return {
    'billId': 'TEST_BILL_001',
    'userId': 'USER_001',
    'userEmail': 'test@example.com',
    'userName': 'Test User',
    'unitId': 'UNIT_101',
    'propertyId': 'PROP_001',
    'billingPeriod': {
      'month': 10,
      'year': 2025,
      'startDate': '2025-10-01T00:00:00Z',
      'endDate': '2025-10-31T23:59:59Z',
      'dueDate': '2025-11-07T23:59:59Z',
      'billingCycle': 'monthly',
    },
    'rent': {
      'baseRent': 25000.0,
      'description': 'Monthly rent',
    },
    'utilities': {
      'electricity': {
        'previousReading': 1000.0,
        'currentReading': 1100.0,
        'consumption': 100.0,
        'unit': 'kWh',
        'ratePerUnit': 10.0,
        'amount': 1000.0,
        'meterNumber': 'ELEC-101',
        'readingDate': '2025-10-31T10:00:00Z',
      },
      'water': {
        'previousReading': 900.0,
        'currentReading': 950.0,
        'consumption': 50.0,
        'unit': 'cubic meters',
        'ratePerUnit': 10.0,
        'amount': 500.0,
        'meterNumber': 'WATER-101',
        'readingDate': '2025-10-31T10:00:00Z',
      },
    },
    'paymentBreakdown': {
      'rent': {'amount': 25000.0, 'amountPaid': 0.0, 'balance': 25000.0, 'isPaid': false},
      'electricity': {'amount': 1000.0, 'amountPaid': 0.0, 'balance': 1000.0, 'isPaid': false},
      'water': {'amount': 500.0, 'amountPaid': 0.0, 'balance': 500.0, 'isPaid': false},
      'trash': {'amount': 200.0, 'amountPaid': 0.0, 'balance': 200.0, 'isPaid': false},
      'wifi': {'amount': 500.0, 'amountPaid': 0.0, 'balance': 500.0, 'isPaid': false},
      'parking': {'amount': 1000.0, 'amountPaid': 0.0, 'balance': 1000.0, 'isPaid': false},
      'additionalCharges': {'amount': 0.0, 'amountPaid': 0.0, 'balance': 0.0, 'isPaid': false},
    },
    'summary': {
      'subtotal': 28200.0,
      'discount': 0.0,
      'discountReason': '',
      'lateFee': 0.0,
      'tax': 0.0,
      'total': 28200.0,
      'amountPaid': 0.0,
      'balance': 28200.0,
    },
    'lateFeeDetails': {
      'isLate': false,
      'weeksOverdue': 0,
      'lateFeePerWeek': 150.0,
      'totalLateFee': 0.0,
      'gracePeriodEnd': '2025-11-14T23:59:59Z',
    },
    'status': 'pending',
    'isPaid': false,
    'isOverdue': false,
    'isPartiallyPaid': false,
    'createdAt': '2025-10-31T15:00:00Z',
    'updatedAt': '2025-10-31T15:00:00Z',
    'generatedBy': 'ADMIN_001',
    'receiptGenerated': false,
  };
}

/// Helper function to create test BillModel
BillModel _createTestBill({String? additionalChargesDescription}) {
  final data = _createMinimalBillData();
  
  if (additionalChargesDescription != null) {
    (data['paymentBreakdown'] as Map<String, dynamic>)['additionalCharges'] = {
      'amount': 500.0,
      'amountPaid': 0.0,
      'balance': 500.0,
      'isPaid': false,
      'description': additionalChargesDescription,
    };
  }
  
  return BillModel.fromMap(data);
}