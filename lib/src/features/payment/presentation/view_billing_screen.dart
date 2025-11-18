import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../theme/app_theme.dart';
import '../../billing/domain/bill_model.dart';

class ViewBillingScreen extends StatefulWidget {
  final BillModel? bill;
  
  const ViewBillingScreen({
    super.key,
    this.bill,
  });

  @override
  State<ViewBillingScreen> createState() => _ViewBillingScreenState();
}

class _ViewBillingScreenState extends State<ViewBillingScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.durationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  BillingData _convertBillToBillingData(BillModel bill) {
    // Convert BillModel status to BillingStatus
    BillingStatus status;
    if (bill.isPaid) {
      status = BillingStatus.paid;
    } else if (bill.isOverdue || bill.lateFeeDetails.isLate) {
      status = BillingStatus.overdue;
    } else {
      status = BillingStatus.pending;
    }

    // Format due date
    final dueDate = '${_getMonthName(bill.billingPeriod.dueDate.month)} ${bill.billingPeriod.dueDate.day}, ${bill.billingPeriod.dueDate.year}';

    return BillingData(
      billNumber: bill.billId,
      dueDate: dueDate,
      status: status,
      rent: bill.rentBreakdown.amount,
      waterReading: WaterReading(
        previousReading: bill.water.previousReading,
        currentReading: bill.water.currentReading,
        rate: bill.water.ratePerUnit,
      ),
      electricityReading: ElectricityReading(
        previousReading: bill.electricity.previousReading,
        currentReading: bill.electricity.currentReading,
        rate: bill.electricity.ratePerUnit,
      ),
      wifi: bill.wifiBreakdown.amount,
      parking: bill.parkingBreakdown.amount,
      extra: bill.additionalChargesBreakdown.amount,
      extraDescription: bill.additionalChargesBreakdown.description,
      trash: bill.trashBreakdown.amount,
      discount: bill.discount,
      lateFee: bill.lateFee,
      tax: bill.tax,
      subtotal: bill.subtotal,
      total: bill.total,
      balance: bill.balance,
      amountPaid: bill.amountPaid,
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // If no bill provided, show error state
    if (widget.bill == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'View Billing',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          leading: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            icon: Icon(
              Iconsax.arrow_left,
              color: context.colorScheme.onSurface,
            ),
          ),
          toolbarHeight: AppConstants.appBarHeight,
          elevation: 0,
          backgroundColor: context.colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.document_text,
                size: 80,
                color: context.colorScheme.outline.withValues(alpha: 0.5),
              ),
              SizedBox(height: AppConstants.spacingMD),
              Text(
                'No Bill Selected',
                style: context.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppConstants.spacingSM),
              Text(
                'Please select a bill to view details',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final billingData = _convertBillToBillingData(widget.bill!);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Billing',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          icon: Icon(
            Iconsax.arrow_left,
            color: context.colorScheme.onSurface,
          ),
        ),
        toolbarHeight: AppConstants.appBarHeight,
        elevation: 0,
        backgroundColor: context.colorScheme.surface,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: context.paddingHorizontal(AppConstants.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppConstants.spacingSM),
                _BillHeaderCard(billingData: billingData),
                SizedBox(height: AppConstants.spacingLG),
                _BillBreakdownCard(billingData: billingData),
                SizedBox(height: AppConstants.spacingLG),
                _BillSummaryCard(billingData: billingData),
                SizedBox(height: AppConstants.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bill Header Card Widget
class _BillHeaderCard extends StatelessWidget {
  final BillingData billingData;

  const _BillHeaderCard({required this.billingData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary,
            context.colorScheme.primary.withValues(alpha:0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: context.radiusXL,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withValues(alpha:0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bill Statement',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
              _StatusChip(status: billingData.status),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          Text(
            'Bill #: ${billingData.billNumber}',
            style: context.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha:0.9),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Row(
            children: [
              Icon(
                Iconsax.calendar,
                color: Colors.white.withValues(alpha:0.9),
                size: 16,
              ),
              SizedBox(width: AppConstants.spacingXS),
              Text(
                'Due Date: ${billingData.dueDate}',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha:0.9),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Status Chip Widget
class _StatusChip extends StatelessWidget {
  final BillingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case BillingStatus.paid:
        backgroundColor = context.colorScheme.success;
        textColor = Colors.white;
        text = 'PAID';
        icon = Iconsax.tick_circle;
        break;
      case BillingStatus.pending:
        backgroundColor = context.colorScheme.warning;
        textColor = Colors.black;
        text = 'PENDING';
        icon = Iconsax.clock;
        break;
      case BillingStatus.overdue:
        backgroundColor = context.colorScheme.error;
        textColor = Colors.white;
        text = 'OVERDUE';
        icon = Iconsax.warning_2;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSM,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: context.radiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          SizedBox(width: AppConstants.spacingXS / 2),
          Text(
            text,
            style: context.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}

// Bill Breakdown Card Widget
class _BillBreakdownCard extends StatelessWidget {
  final BillingData billingData;

  const _BillBreakdownCard({required this.billingData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha:0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Breakdown',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingLG),
          _BillLineItem(
            icon: Iconsax.home,
            label: 'Rent',
            amount: billingData.rent,
          ),
          _WaterBillItem(waterReading: billingData.waterReading),
          _ElectricityBillItem(electricityReading: billingData.electricityReading),
          _BillLineItem(
            icon: Iconsax.wifi,
            label: 'Wi-Fi',
            amount: billingData.wifi,
          ),
          _BillLineItem(
            icon: Iconsax.trash,
            label: 'Trash',
            amount: billingData.trash,
          ),
          _BillLineItem(
            icon: Iconsax.car,
            label: 'Parking',
            amount: billingData.parking,
          ),
          if (billingData.extra > 0)
            _BillLineItem(
              icon: Iconsax.add_circle,
              label: 'Extra Charges',
              amount: billingData.extra,
              description: billingData.extraDescription,
            ),
          if (billingData.discount > 0)
            _BillLineItem(
              icon: Iconsax.ticket_discount,
              label: 'Discount',
              amount: -billingData.discount,
            ),
          if (billingData.lateFee > 0)
            _BillLineItem(
              icon: Iconsax.warning_2,
              label: 'Late Fee',
              amount: billingData.lateFee,
            ),
        ],
      ),
    );
  }
}

// Bill Line Item Widget
class _BillLineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final String? description;

  const _BillLineItem({
    required this.icon,
    required this.label,
    required this.amount,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppConstants.spacingMD,
        horizontal: AppConstants.spacingSM,
      ),
      margin: EdgeInsets.only(bottom: AppConstants.spacingSM),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: context.radiusMD,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacingXS),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha:0.1),
              borderRadius: context.radiusSM,
            ),
            child: Icon(
              icon,
              size: 20,
              color: context.colorScheme.primary,
            ),
          ),
          SizedBox(width: AppConstants.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Montserrat',
                  ),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  SizedBox(height: AppConstants.spacingXS / 2),
                  Text(
                    description!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}

// Water Bill Item Widget
class _WaterBillItem extends StatelessWidget {
  final WaterReading waterReading;

  const _WaterBillItem({required this.waterReading});

  @override
  Widget build(BuildContext context) {
    final consumption = waterReading.currentReading - waterReading.previousReading;
    final total = consumption * waterReading.rate;

    return Container(
      padding: EdgeInsets.all(AppConstants.spacingSM),
      margin: EdgeInsets.only(bottom: AppConstants.spacingSM),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: context.radiusMD,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacingXS),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha:0.1),
                  borderRadius: context.radiusSM,
                ),
                child: Icon(
                  Iconsax.drop,
                  size: 20,
                  color: context.colorScheme.primary,
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: Text(
                  'Water',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSM),
          Container(
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              color: context.colorScheme.surface.withValues(alpha:0.8),
              borderRadius: context.radiusSM,
            ),
            child: Column(
              children: [
                _ReadingRow(
                  label: 'Previous Reading',
                  value: '${waterReading.previousReading} m³',
                ),
                _ReadingRow(
                  label: 'Current Reading',
                  value: '${waterReading.currentReading} m³',
                ),
                _ReadingRow(
                  label: 'Consumption',
                  value: '${consumption.toStringAsFixed(1)} m³',
                ),
                _ReadingRow(
                  label: 'Rate per m³',
                  value: '₱${waterReading.rate.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Electricity Bill Item Widget
class _ElectricityBillItem extends StatelessWidget {
  final ElectricityReading electricityReading;

  const _ElectricityBillItem({required this.electricityReading});

  @override
  Widget build(BuildContext context) {
    final consumption = electricityReading.currentReading - electricityReading.previousReading;
    final total = consumption * electricityReading.rate;

    return Container(
      padding: EdgeInsets.all(AppConstants.spacingSM),
      margin: EdgeInsets.only(bottom: AppConstants.spacingSM),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: context.radiusMD,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacingXS),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha:0.1),
                  borderRadius: context.radiusSM,
                ),
                child: Icon(
                  Iconsax.flash,
                  size: 20,
                  color: context.colorScheme.primary,
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: Text(
                  'Electricity',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSM),
          Container(
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              color: context.colorScheme.surface.withValues(alpha:0.8),
              borderRadius: context.radiusSM,
            ),
            child: Column(
              children: [
                _ReadingRow(
                  label: 'Previous Reading',
                  value: '${electricityReading.previousReading} kWh',
                ),
                _ReadingRow(
                  label: 'Current Reading',
                  value: '${electricityReading.currentReading} kWh',
                ),
                _ReadingRow(
                  label: 'Consumption',
                  value: '${consumption.toStringAsFixed(1)} kWh',
                ),
                _ReadingRow(
                  label: 'Rate per kWh',
                  value: '₱${electricityReading.rate.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Reading Row Widget
class _ReadingRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadingRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXS / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha:0.7),
              fontFamily: 'Montserrat',
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}

// Bill Summary Card Widget
class _BillSummaryCard extends StatelessWidget {
  final BillingData billingData;

  const _BillSummaryCard({required this.billingData});

  @override
  Widget build(BuildContext context) {
    final double total = billingData.totalAmountDue;

    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primaryContainer,
            context.colorScheme.primaryContainer.withValues(alpha:0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: context.radiusXL,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha:0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount Due',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: context.colorScheme.onPrimaryContainer,
                ),
              ),
              Icon(
                Iconsax.receipt,
                color: context.colorScheme.primary,
                size: 24,
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          Text(
            '₱${total.toStringAsFixed(2)}',
            style: context.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: context.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class BillingData {
  final String billNumber;
  final String dueDate;
  final BillingStatus status;
  final double rent;
  final WaterReading waterReading;
  final ElectricityReading electricityReading;
  final double wifi;
  final double parking;
  final double extra;
  final String? extraDescription;
  final double trash;
  final double discount;
  final double lateFee;
  final double tax;
  final double subtotal;
  final double total;
  final double balance;
  final double amountPaid;

  const BillingData({
    required this.billNumber,
    required this.dueDate,
    required this.status,
    required this.rent,
    required this.waterReading,
    required this.electricityReading,
    required this.wifi,
    required this.parking,
    required this.extra,
    this.extraDescription,
    required this.trash,
    required this.discount,
    required this.lateFee,
    required this.tax,
    required this.subtotal,
    required this.total,
    required this.balance,
    required this.amountPaid,
  });

  // Use the actual balance from BillModel (amount still owed)
  double get totalAmountDue => balance;
}

class WaterReading {
  final double previousReading;
  final double currentReading;
  final double rate;

  const WaterReading({
    required this.previousReading,
    required this.currentReading,
    required this.rate,
  });
}

class ElectricityReading {
  final double previousReading;
  final double currentReading;
  final double rate;

  const ElectricityReading({
    required this.previousReading,
    required this.currentReading,
    required this.rate,
  });
}

enum BillingStatus {
  paid,
  pending,
  overdue,
}
