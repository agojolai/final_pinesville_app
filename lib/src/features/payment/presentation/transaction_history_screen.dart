import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/app_theme.dart';
import '../../../core/snackbars/loaders.dart';
import '../../billing/domain/bill_model.dart';

///TODO: NEED IPDATE YUNG RESIBO, LAGYAN NG PAYMENT METHOD ETC
///AND OTHER DETAILS
/// Transaction History Screen - Receipt-like view for fully paid bills
/// 
/// Features:
/// - Professional receipt design with white background
/// - Bill information section (bill ID, dates, property/unit)
/// - Payment breakdown by category (rent, utilities, charges)
/// - Utility consumption details (X m³ × ₱rate/m³)
/// - Payment summary (total, paid, discount, late fees)
/// - Download as JPEG using screenshot package
/// - Access control: Only shows for fully paid bills
class TransactionHistoryScreen extends StatefulWidget {
  final BillModel bill;

  const TransactionHistoryScreen({
    super.key,
    required this.bill,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    // Security: Only show for fully paid bills
    if (!widget.bill.isPaid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transaction History'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.info_circle,
                size: 64.sp,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: AppConstants.spacingMD),
              Text(
                'This bill has not been fully paid yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Montserrat',
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.spacingSM),
              Text(
                'Transaction history is only available for paid bills',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Montserrat',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Transaction Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          // Download button - saves receipt as JPEG
          IconButton(
            icon: const Icon(Iconsax.document_download),
            onPressed: _downloadReceipt,
            tooltip: 'Download Receipt',
          ),
          SizedBox(width: AppConstants.spacingSM),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Screenshot(
          controller: _screenshotController,
          child: Theme(
            data: AppTheme.lightTheme,
            child: _ReceiptCard(bill: widget.bill),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadReceipt() async {
    try {
      HapticFeedback.lightImpact();
      
      // Show loading indicator
      if (!mounted) return;
      Loaders.infoSnackBar(
        context,
        title: 'Generating receipt...',
        message: 'Please wait while we capture your receipt',
      );

      // Capture screenshot
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        throw Exception('Failed to capture screenshot');
      }

      // Save to gallery using gal package
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'receipt_${widget.bill.billId}_$timestamp.jpg';
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      // Save to gallery - gal handles permissions automatically
      await Gal.putImage(file.path, album: 'Pinesville Receipts');

      // Clean up temp file
      await file.delete();

      if (!mounted) return;
      Loaders.hideSnackBar(context);
      Loaders.successSnackBar(
        context,
        title: 'Success!',
        message: 'Receipt saved to gallery in "Pinesville Receipts" album',
        duration: 4,
      );
      
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      Loaders.hideSnackBar(context);
      Loaders.errorSnackBar(
        context,
        title: 'Download Failed',
        message: e.toString(),
      );
    }
  }
}

/// Receipt Card - White card with professional receipt layout
class _ReceiptCard extends StatelessWidget {
  final BillModel bill;

  const _ReceiptCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt Header
            Center(
              child: Column(
                children: [
                  Text(
                    'OFFICIAL RECEIPT',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                  SizedBox(height: AppConstants.spacingXS),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingMD,
                      vertical: AppConstants.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      'PAID',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontFamily: 'Montserrat',
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppConstants.spacingLG),
            const Divider(),
            SizedBox(height: AppConstants.spacingMD),

            // Bill Information Section
            _SectionHeader(title: 'Bill Information'),
            SizedBox(height: AppConstants.spacingSM),
            _InfoRow(label: 'Bill ID', value: bill.billId),
            _InfoRow(
              label: 'Billing Period',
              value: '${dateFormat.format(bill.billingPeriod.startDate)} - ${dateFormat.format(bill.billingPeriod.endDate)}',
            ),
            _InfoRow(
              label: 'Paid Date',
              value: bill.paidAt != null
                  ? dateFormat.format(bill.paidAt!)
                  : 'N/A',
            ),
            //_InfoRow(label: 'Paid via', value: bill.paymentMethod),
            _InfoRow(label: 'Unit', value: bill.unitId),

            SizedBox(height: AppConstants.spacingLG),
            const Divider(),
            SizedBox(height: AppConstants.spacingMD),

            // Payment Breakdown Section
            _SectionHeader(title: 'Payment Breakdown'),
            SizedBox(height: AppConstants.spacingSM),

            // Rent
            if (bill.rentBreakdown.amount > 0)
              _ReceiptLineItem(
                label: 'Rent',
                amount: currencyFormat.format(bill.rentBreakdown.amount),
              ),

            // Electricity (with consumption)
            if (bill.electricityBreakdown.amount > 0)
              _ReceiptUtilityItem(
                label: 'Electricity',
                amount: currencyFormat.format(bill.electricityBreakdown.amount),
                consumption: bill.electricity.consumption,
                rate: bill.electricity.ratePerUnit,
                unit: 'kWh',
              ),

            // Water (with consumption)
            if (bill.waterBreakdown.amount > 0)
              _ReceiptUtilityItem(
                label: 'Water',
                amount: currencyFormat.format(bill.waterBreakdown.amount),
                consumption: bill.water.consumption,
                rate: bill.water.ratePerUnit,
                unit: 'm³',
              ),

            // Trash
            if (bill.trashBreakdown.amount > 0)
              _ReceiptLineItem(
                label: 'Trash Collection',
                amount: currencyFormat.format(bill.trashBreakdown.amount),
              ),

            // WiFi
            if (bill.wifiBreakdown.amount > 0)
              _ReceiptLineItem(
                label: 'WiFi',
                amount: currencyFormat.format(bill.wifiBreakdown.amount),
              ),

            // Parking
            if (bill.parkingBreakdown.amount > 0)
              _ReceiptLineItem(
                label: 'Parking',
                amount: currencyFormat.format(bill.parkingBreakdown.amount),
              ),

            // Additional Charges
            if (bill.additionalChargesBreakdown.amount > 0)
              _ReceiptLineItem(
                label: 'Additional Charges',
                amount: currencyFormat.format(bill.additionalChargesBreakdown.amount),
                subtitle: bill.additionalChargesBreakdown.description,
              ),

            SizedBox(height: AppConstants.spacingMD),
            const Divider(),
            SizedBox(height: AppConstants.spacingMD),

            // Payment Summary Section
            _SectionHeader(title: 'Payment Summary'),
            SizedBox(height: AppConstants.spacingSM),
            _InfoRow(
              label: 'Subtotal',
              value: currencyFormat.format(bill.total - bill.lateFeeDetails.totalLateFee),
              isBold: false,
            ),
            if (bill.discount > 0)
              _InfoRow(
                label: 'Discount',
                value: '- ${currencyFormat.format(bill.discount)}',
                isBold: false,
                valueColor: Colors.green,
              ),
            if (bill.lateFeeDetails.totalLateFee > 0)
              _InfoRow(
                label: 'Late Fees',
                value: currencyFormat.format(bill.lateFeeDetails.totalLateFee),
                isBold: false,
                valueColor: Colors.red,
              ),

            SizedBox(height: AppConstants.spacingSM),
            const Divider(thickness: 2),
            SizedBox(height: AppConstants.spacingSM),

            _InfoRow(
              label: 'Total Amount',
              value: currencyFormat.format(bill.total),
              isBold: true,
              fontSize: 18.sp,
            ),
            _InfoRow(
              label: 'Amount Paid',
              value: currencyFormat.format(bill.amountPaid),
              isBold: true,
              fontSize: 16.sp,
              valueColor: Colors.green,
            ),
            _InfoRow(
              label: 'Balance',
              value: currencyFormat.format(bill.balance),
              isBold: true,
              fontSize: 16.sp,
              valueColor: bill.balance > 0 ? Colors.red : Colors.green,
            ),

            SizedBox(height: AppConstants.spacingLG),
            const Divider(),
            SizedBox(height: AppConstants.spacingMD),

            // Receipt Footer
            Center(
              child: Column(
                children: [
                   Icon(
                      Iconsax.tick_circle,
                      color: Colors.green,
                      size: 48.sp,
                    ),
                  SizedBox(height: AppConstants.spacingSM),
                  Text(
                    'This bill has been fully paid',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'Montserrat',
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: AppConstants.spacingXS),
                  Text(
                    'Thank you for your payment!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Montserrat',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
    );
  }
}

/// Info Row Widget - Label-value pair
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final double? fontSize;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.fontSize,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Montserrat',
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontSize: fontSize,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Montserrat',
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    fontSize: fontSize,
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Receipt Line Item Widget - Simple amount line
class _ReceiptLineItem extends StatelessWidget {
  final String label;
  final String amount;
  final String? subtitle;

  const _ReceiptLineItem({
    required this.label,
    required this.amount,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Montserrat',
                    ),
              ),
              Text(
                amount,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.only(left: AppConstants.spacingMD),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Montserrat',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Receipt Utility Item Widget - Shows consumption details
class _ReceiptUtilityItem extends StatelessWidget {
  final String label;
  final String amount;
  final double consumption;
  final double rate;
  final String unit;

  const _ReceiptUtilityItem({
    required this.label,
    required this.amount,
    required this.consumption,
    required this.rate,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Montserrat',
                    ),
              ),
              Text(
                amount,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.only(left: AppConstants.spacingMD),
            child: Text(
              '${consumption.toStringAsFixed(2)} $unit × ${currencyFormat.format(rate)}/$unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'Montserrat',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
