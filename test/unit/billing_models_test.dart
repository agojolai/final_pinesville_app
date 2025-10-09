import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/billing/domain/billing_models.dart';

void main() {
  group('LateFeeDetails Tests', () {
    test('should create LateFeeDetails with correct values', () {
      final lateFee = LateFeeDetails(
        isLate: true,
        weeksOverdue: 2,
        lateFeePerWeek: 150.0,
        totalLateFee: 300.0,
        gracePeriodEnd: DateTime(2025, 11, 14),
        lateFeeAppliedAt: DateTime(2025, 11, 15),
      );

      expect(lateFee.isLate, true);
      expect(lateFee.weeksOverdue, 2);
      expect(lateFee.totalLateFee, 300.0);
      expect(lateFee.lateFeePerWeek, 150.0);
    });

    test('should convert to map correctly', () {
      final lateFee = LateFeeDetails(
        isLate: false,
        weeksOverdue: 0,
        lateFeePerWeek: 150.0,
        totalLateFee: 0.0,
        gracePeriodEnd: DateTime(2025, 11, 14),
      );

      final map = lateFee.toMap();

      expect(map['isLate'], false);
      expect(map['weeksOverdue'], 0);
      expect(map['totalLateFee'], 0.0);
    });

    test('should calculate late fee correctly when overdue (NO GRACE PERIOD)', () {
      final dueDate = DateTime.now().subtract(const Duration(days: 21)); // 3 weeks ago
      final lateFee = LateFeeDetails.calculate(
        dueDate: dueDate,
        gracePeriodDays: 0, // No grace period anymore
        lateFeePerWeek: 150.0,
      );

      expect(lateFee.isLate, true);
      expect(lateFee.weeksOverdue, 3); // 21 days = 3 weeks (no grace period)
      expect(lateFee.totalLateFee, 450.0); // 3 weeks * 150
    });

    test('should not charge late fee before due date', () {
      final dueDate = DateTime.now().add(const Duration(days: 3)); // 3 days in future
      final lateFee = LateFeeDetails.calculate(
        dueDate: dueDate,
        gracePeriodDays: 0,
        lateFeePerWeek: 150.0,
      );

      expect(lateFee.isLate, false);
      expect(lateFee.weeksOverdue, 0);
      expect(lateFee.totalLateFee, 0.0);
    });
  });

  group('UtilityCharge Tests', () {
    test('should calculate consumption correctly', () {
      final charge = UtilityCharge(
        previousReading: 5000.0,
        currentReading: 5150.0,
        consumption: 150.0,
        unit: 'kWh',
        ratePerUnit: 12.0,
        amount: 1800.0,
        meterNumber: 'METER001',
        readingDate: DateTime(2025, 10, 31),
      );

      expect(charge.consumption, 150.0);
      expect(charge.amount, 1800.0);
      expect(charge.currentReading, 5150.0);
      expect(charge.previousReading, 5000.0);
    });

    test('should convert to map and back', () {
      final original = UtilityCharge(
        previousReading: 5000.0,
        currentReading: 5150.0,
        consumption: 150.0,
        unit: 'kWh',
        ratePerUnit: 12.0,
        amount: 1800.0,
        meterNumber: 'METER001',
        readingDate: DateTime(2025, 10, 31),
      );

      final map = original.toMap();
      final restored = UtilityCharge.fromMap(map);

      expect(restored.consumption, original.consumption);
      expect(restored.amount, original.amount);
      expect(restored.unit, original.unit);
    });
  });

  group('BillingPeriod Tests', () {
    test('should create billing period with all required fields', () {
      final period = BillingPeriod(
        month: 10,
        year: 2025,
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 31),
        dueDate: DateTime(2025, 11, 7),
      );

      expect(period.month, 10);
      expect(period.year, 2025);
      expect(period.billingCycle, 'monthly');
    });

    test('should serialize to map and deserialize correctly', () {
      final original = BillingPeriod(
        month: 10,
        year: 2025,
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 31),
        dueDate: DateTime(2025, 11, 7),
        billingCycle: 'monthly',
      );

      final map = original.toMap();
      final restored = BillingPeriod.fromMap(map);

      expect(restored.month, original.month);
      expect(restored.year, original.year);
      expect(restored.billingCycle, original.billingCycle);
    });
  });

  group('PaymentBreakdownItem Tests', () {
    test('should track payment status correctly', () {
      final item = PaymentBreakdownItem(
        amount: 10000.0,
        amountPaid: 10000.0,
        balance: 0.0,
        isPaid: true,
        paidAt: DateTime(2025, 10, 15),
      );

      expect(item.isPaid, true);
      expect(item.balance, 0.0);
      expect(item.amount, item.amountPaid);
    });

    test('should track partial payment correctly', () {
      final item = PaymentBreakdownItem(
        amount: 10000.0,
        amountPaid: 5000.0,
        balance: 5000.0,
        isPaid: false,
      );

      expect(item.isPaid, false);
      expect(item.balance, 5000.0);
      expect(item.amountPaid, 5000.0);
    });

    test('should use copyWith to update payment', () {
      final original = PaymentBreakdownItem(
        amount: 10000.0,
        amountPaid: 5000.0,
        balance: 5000.0,
        isPaid: false,
      );

      final updated = original.copyWith(
        amountPaid: 10000.0,
        balance: 0.0,
        isPaid: true,
        paidAt: DateTime(2025, 10, 20),
      );

      expect(updated.isPaid, true);
      expect(updated.balance, 0.0);
      expect(updated.amountPaid, 10000.0);
    });

    test('should serialize and deserialize correctly', () {
      final original = PaymentBreakdownItem(
        amount: 10000.0,
        amountPaid: 5000.0,
        balance: 5000.0,
        isPaid: false,
        paidAt: DateTime(2025, 10, 15),
      );

      final map = original.toMap();
      final restored = PaymentBreakdownItem.fromMap(map);

      expect(restored.amount, original.amount);
      expect(restored.amountPaid, original.amountPaid);
      expect(restored.balance, original.balance);
      expect(restored.isPaid, original.isPaid);
      expect(restored.paidAt, original.paidAt);
    });
  });

  group('AdditionalCharge Tests', () {
    test('should create additional charge', () {
      final charge = AdditionalCharge(
        chargeId: 'CHARGE_001',
        description: 'Parking fee',
        amount: 500.0,
        category: 'parking',
      );

      expect(charge.chargeId, 'CHARGE_001');
      expect(charge.description, 'Parking fee');
      expect(charge.amount, 500.0);
      expect(charge.category, 'parking');
    });

    test('should serialize additional charge', () {
      final original = AdditionalCharge(
        chargeId: 'CHARGE_002',
        description: 'WiFi subscription',
        amount: 1000.0,
        category: 'internet',
      );

      final map = original.toMap();
      final restored = AdditionalCharge.fromMap(map);

      expect(restored.chargeId, original.chargeId);
      expect(restored.description, original.description);
      expect(restored.amount, original.amount);
      expect(restored.category, original.category);
    });
  });

  group('Payment Workflow Integration Tests', () {
    test('should handle full payment workflow', () {
      // Initial bill with no payment
      final rentBreakdown = PaymentBreakdownItem(
        amount: 5000.0,
        amountPaid: 0.0,
        balance: 5000.0,
        isPaid: false,
      );

      expect(rentBreakdown.isPaid, false);
      expect(rentBreakdown.balance, 5000.0);

      // Apply full payment
      final paidRent = rentBreakdown.copyWith(
        amountPaid: 5000.0,
        balance: 0.0,
        isPaid: true,
        paidAt: DateTime(2025, 10, 15),
      );

      expect(paidRent.isPaid, true);
      expect(paidRent.balance, 0.0);
      expect(paidRent.paidAt, isNotNull);
    });

    test('should handle partial payment workflow', () {
      // Initial bill
      final electricityBreakdown = PaymentBreakdownItem(
        amount: 1200.0,
        amountPaid: 0.0,
        balance: 1200.0,
        isPaid: false,
      );

      // First partial payment
      final firstPayment = electricityBreakdown.copyWith(
        amountPaid: 500.0,
        balance: 700.0,
        isPaid: false,
      );

      expect(firstPayment.amountPaid, 500.0);
      expect(firstPayment.balance, 700.0);
      expect(firstPayment.isPaid, false);

      // Second partial payment (complete)
      final secondPayment = firstPayment.copyWith(
        amountPaid: 1200.0,
        balance: 0.0,
        isPaid: true,
        paidAt: DateTime(2025, 10, 20),
      );

      expect(secondPayment.isPaid, true);
      expect(secondPayment.balance, 0.0);
      expect(secondPayment.amountPaid, secondPayment.amount);
    });

    test('should calculate total bill with all breakdown items', () {
      final rent = PaymentBreakdownItem(
        amount: 5000.0,
        amountPaid: 5000.0,
        balance: 0.0,
        isPaid: true,
      );

      final electricity = PaymentBreakdownItem(
        amount: 1200.0,
        amountPaid: 600.0,
        balance: 600.0,
        isPaid: false,
      );

      final water = PaymentBreakdownItem(
        amount: 300.0,
        amountPaid: 0.0,
        balance: 300.0,
        isPaid: false,
      );

      final trash = PaymentBreakdownItem(
        amount: 150.0,
        amountPaid: 0.0,
        balance: 150.0,
        isPaid: false,
      );

      // Calculate totals
      final totalAmount = rent.amount + electricity.amount + water.amount + trash.amount;
      final totalPaid = rent.amountPaid + electricity.amountPaid + water.amountPaid + trash.amountPaid;
      final totalBalance = rent.balance + electricity.balance + water.balance + trash.balance;

      expect(totalAmount, 6650.0);
      expect(totalPaid, 5600.0);
      expect(totalBalance, 1050.0);
      expect(totalAmount, totalPaid + totalBalance);
    });

    test('should track payment status across multiple categories', () {
      final breakdowns = [
        PaymentBreakdownItem(
          amount: 5000.0,
          amountPaid: 5000.0,
          balance: 0.0,
          isPaid: true,
        ),
        PaymentBreakdownItem(
          amount: 1200.0,
          amountPaid: 1200.0,
          balance: 0.0,
          isPaid: true,
        ),
        PaymentBreakdownItem(
          amount: 300.0,
          amountPaid: 0.0,
          balance: 300.0,
          isPaid: false,
        ),
      ];

      final allPaid = breakdowns.every((b) => b.isPaid);
      final anyUnpaid = breakdowns.any((b) => !b.isPaid);
      final totalBalance = breakdowns.fold<double>(0.0, (sum, b) => sum + b.balance);

      expect(allPaid, false);
      expect(anyUnpaid, true);
      expect(totalBalance, 300.0);
    });
  });

  group('Billing Period Edge Cases', () {
    test('should handle month boundaries correctly', () {
      final period = BillingPeriod(
        month: 12,
        year: 2025,
        startDate: DateTime(2025, 12, 1),
        endDate: DateTime(2025, 12, 31),
        dueDate: DateTime(2026, 1, 7), // Due date in next year
      );

      expect(period.month, 12);
      expect(period.year, 2025);
      expect(period.dueDate.year, 2026);
      expect(period.dueDate.month, 1);
    });

    test('should handle February in leap year', () {
      final period = BillingPeriod(
        month: 2,
        year: 2024, // Leap year
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 29), // 29 days
        dueDate: DateTime(2024, 3, 7),
      );

      final days = period.endDate.difference(period.startDate).inDays + 1;
      expect(days, 29);
    });
  });

  group('Utility Consumption Edge Cases', () {
    test('should handle zero consumption', () {
      final charge = UtilityCharge(
        previousReading: 5000.0,
        currentReading: 5000.0,
        consumption: 0.0,
        unit: 'kWh',
        ratePerUnit: 12.0,
        amount: 0.0,
        meterNumber: 'METER001',
        readingDate: DateTime(2025, 10, 31),
      );

      expect(charge.consumption, 0.0);
      expect(charge.amount, 0.0);
    });

    test('should handle high consumption', () {
      final charge = UtilityCharge(
        previousReading: 5000.0,
        currentReading: 6000.0,
        consumption: 1000.0,
        unit: 'kWh',
        ratePerUnit: 12.0,
        amount: 12000.0,
        meterNumber: 'METER001',
        readingDate: DateTime(2025, 10, 31),
      );

      expect(charge.consumption, 1000.0);
      expect(charge.amount, 12000.0);
      expect(charge.amount, charge.consumption * charge.ratePerUnit);
    });

    test('should validate consumption calculation', () {
      final previous = 5000.0;
      final current = 5150.0;
      final consumption = current - previous;

      final charge = UtilityCharge(
        previousReading: previous,
        currentReading: current,
        consumption: consumption,
        unit: 'kWh',
        ratePerUnit: 12.0,
        amount: consumption * 12.0,
        meterNumber: 'METER001',
        readingDate: DateTime(2025, 10, 31),
      );

      expect(charge.consumption, current - previous);
      expect(charge.amount, consumption * 12.0);
    });
  });

  group('Late Fee Calculation Edge Cases (NO GRACE PERIOD)', () {
    test('should not be late on the due date', () {
      final dueDate = DateTime.now(); // Exactly now
      final lateFee = LateFeeDetails.calculate(
        dueDate: dueDate,
        gracePeriodDays: 0, // No grace period
        lateFeePerWeek: 150.0,
      );

      expect(lateFee.isLate, false);
      expect(lateFee.weeksOverdue, 0);
      expect(lateFee.totalLateFee, 0.0);
    });

    test('should be late one day after due date', () {
      final dueDate = DateTime.now().subtract(const Duration(days: 1));
      final lateFee = LateFeeDetails.calculate(
        dueDate: dueDate,
        gracePeriodDays: 0, // No grace period
        lateFeePerWeek: 150.0,
      );

      expect(lateFee.isLate, true);
      expect(lateFee.weeksOverdue, 1); // ceil(1/7) = 1 week
      expect(lateFee.totalLateFee, 150.0); // 1 week * 150
    });

    test('should calculate multiple weeks late correctly', () {
      final dueDate = DateTime.now().subtract(const Duration(days: 35)); // 5 weeks ago
      final lateFee = LateFeeDetails.calculate(
        dueDate: dueDate,
        gracePeriodDays: 0, // No grace period
        lateFeePerWeek: 150.0,
      );

      expect(lateFee.isLate, true);
      expect(lateFee.weeksOverdue, 5); // 35 days = 5 weeks (no grace period)
      expect(lateFee.totalLateFee, 750.0); // 5 weeks * 150
    });

    test('should round up partial weeks', () {
      final dueDate = DateTime.now().subtract(const Duration(days: 18)); // 18 days overdue
      final lateFee = LateFeeDetails.calculate(
        dueDate: dueDate,
        gracePeriodDays: 0, // No grace period
        lateFeePerWeek: 150.0,
      );

      expect(lateFee.isLate, true);
      expect(lateFee.weeksOverdue, 3); // 18 days = ceil(18/7) = 3 weeks
      expect(lateFee.totalLateFee, 450.0);
    });
  });
}
