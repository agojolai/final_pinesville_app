import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../../../billing/presentation/billing_providers.dart';
import '../../../billing/domain/bill_model.dart';

class AdminBillDetailScreen extends ConsumerWidget {
  const AdminBillDetailScreen({
    super.key,
    required this.billId,
  });

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billAsync = ref.watch(billProvider(billId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bill Details',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.printer),
            tooltip: 'Print Bill',
            onPressed: () {
              // TODO: Implement print/download receipt
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: billAsync.when(
        data: (bill) {
          if (bill == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.danger,
                    size: 64,
                    color: context.colorScheme.error,
                  ),
                  SizedBox(height: AppConstants.spacingMD),
                  Text(
                    'Bill not found',
                    style: context.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.all(AppConstants.spacingMD),
            children: [
              _buildBillHeader(context, bill),
              SizedBox(height: AppConstants.spacingMD),
              _buildStatusCard(context, bill),
              SizedBox(height: AppConstants.spacingMD),
              _buildChargesBreakdown(context, bill),
              SizedBox(height: AppConstants.spacingMD),
              _buildPaymentHistory(context, bill),
              SizedBox(height: AppConstants.spacingMD),
              _buildTotalCard(context, bill),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.danger,
                size: 64,
                color: context.colorScheme.error,
              ),
              SizedBox(height: AppConstants.spacingMD),
              Text(
                'Error loading bill',
                style: context.textTheme.titleMedium,
              ),
              SizedBox(height: AppConstants.spacingSM),
              Text(
                error.toString(),
                style: context.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillHeader(BuildContext context, BillModel bill) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Bill #${bill.billId}',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: AppConstants.spacingSM),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${bill.billingPeriod.month}/${bill.billingPeriod.year}',
                    style: context.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingMD),
            _buildInfoRow(context, 'Property ID', bill.propertyId),
            _buildInfoRow(context, 'Unit', bill.unitId),
            _buildInfoRow(context, 'Tenant', bill.userName),
            _buildInfoRow(context, 'Tenant ID', bill.userId),
            _buildInfoRow(context, 'Due Date', dateFormat.format(bill.billingPeriod.dueDate)),
            _buildInfoRow(context, 'Created', dateFormat.format(bill.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, BillModel bill) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (bill.isPaid) {
      statusColor = Colors.green;
      statusText = 'Paid in Full';
      statusIcon = Iconsax.tick_circle5;
    } else if (bill.isPartiallyPaid) {
      statusColor = Colors.orange;
      statusText = 'Partially Paid';
      statusIcon = Iconsax.info_circle;
    } else if (bill.isOverdue) {
      statusColor = Colors.red;
      statusText = 'Overdue';
      statusIcon = Iconsax.danger;
    } else {
      statusColor = Colors.grey;
      statusText = 'Pending Payment';
      statusIcon = Iconsax.clock;
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            SizedBox(width: AppConstants.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (!bill.isPaid) ...[
                    SizedBox(height: AppConstants.spacingXS),
                    Text(
                      'Balance: ₱${bill.balance.toStringAsFixed(2)}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargesBreakdown(BuildContext context, BillModel bill) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Charges Breakdown',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            _buildChargeRow(
              context,
              'Rent',
              bill.baseRent,
              bill.rentBreakdown.isPaid,
              bill.rentBreakdown.amountPaid,
            ),
            _buildChargeRow(
              context,
              '⚡ Electricity',
              bill.electricity.amount,
              bill.electricityBreakdown.isPaid,
              bill.electricityBreakdown.amountPaid,
              details: '${bill.electricity.consumption} kWh × ₱${bill.electricity.ratePerUnit.toStringAsFixed(2)}',
            ),
            _buildChargeRow(
              context,
              '💧 Water',
              bill.water.amount,
              bill.waterBreakdown.isPaid,
              bill.waterBreakdown.amountPaid,
              details: '${bill.water.consumption} m³ × ₱${bill.water.ratePerUnit.toStringAsFixed(2)}',
            ),
            _buildChargeRow(
              context,
              '🗑️ Trash Collection',
              bill.trashBreakdown.amount,
              bill.trashBreakdown.isPaid,
              bill.trashBreakdown.amountPaid,
            ),
            _buildChargeRow(
              context,
              '📶 WiFi',
              bill.wifiBreakdown.amount,
              bill.wifiBreakdown.isPaid,
              bill.wifiBreakdown.amountPaid,
            ),
            _buildChargeRow(
              context,
              '🅿️ Parking',
              bill.parkingBreakdown.amount,
              bill.parkingBreakdown.isPaid,
              bill.parkingBreakdown.amountPaid,
            ),
            if (bill.additionalChargesBreakdown.amount > 0)
              _buildChargeRow(
                context,
                'Additional Charges',
                bill.additionalChargesBreakdown.amount,
                bill.additionalChargesBreakdown.isPaid,
                bill.additionalChargesBreakdown.amountPaid,
                details: bill.additionalChargesBreakdown.description, // Show admin's description
              ),
            if (bill.lateFee > 0)
              _buildChargeRow(
                context,
                '⚠️ Late Fee',
                bill.lateFee,
                false,
                0,
                isLateFee: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargeRow(
    BuildContext context,
    String label,
    double amount,
    bool isPaid,
    double amountPaid, {
    String? details,
    bool isLateFee = false,
  }) {
    final balance = amount - amountPaid;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isLateFee ? Colors.red : null,
                      ),
                    ),
                    if (details != null) ...[
                      SizedBox(height: AppConstants.spacingXS / 2),
                      Text(
                        details,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        '₱${amount.toStringAsFixed(2)}',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      SizedBox(width: AppConstants.spacingSM),
                      Icon(
                        isPaid ? Iconsax.tick_circle5 : Iconsax.close_circle5,
                        color: isPaid ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                  if (amountPaid > 0 && !isPaid) ...[
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Text(
                      'Paid: ₱${amountPaid.toStringAsFixed(2)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      'Balance: ₱${balance.toStringAsFixed(2)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(BuildContext context, BillModel bill) {
    // For now, show simplified payment summary
    // TODO: Implement separate query to fetch payment history for this bill
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.spacingMD),
            if (bill.amountPaid > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Paid',
                    style: context.textTheme.bodyMedium,
                  ),
                  Text(
                    '₱${bill.amountPaid.toStringAsFixed(2)}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
              if (bill.paidAt != null) ...[
                SizedBox(height: AppConstants.spacingXS),
                Text(
                  'Last payment: ${DateFormat('MMM dd, yyyy').format(bill.paidAt!)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Iconsax.wallet,
                      size: 48,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: AppConstants.spacingSM),
                    Text(
                      'No payments recorded yet',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, BillModel bill) {
    return Card(
      color: context.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          children: [
            _buildTotalRow(context, 'Subtotal', bill.total - bill.lateFee),
            if (bill.lateFee > 0)
              _buildTotalRow(context, 'Late Fee', bill.lateFee, isLateFee: true),
            _buildTotalRow(context, 'Total Amount', bill.total, isLarge: true),
            Divider(height: AppConstants.spacingMD * 2),
            _buildTotalRow(context, 'Amount Paid', bill.amountPaid, isPaid: true),
            _buildTotalRow(
              context,
              'Balance Due',
              bill.balance,
              isLarge: true,
              isBalance: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context,
    String label,
    double amount, {
    bool isLarge = false,
    bool isPaid = false,
    bool isLateFee = false,
    bool isBalance = false,
  }) {
    Color? amountColor;
    if (isPaid) amountColor = Colors.green;
    if (isLateFee) amountColor = Colors.red;
    if (isBalance && amount > 0) amountColor = Colors.orange;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isLarge ? context.textTheme.titleMedium : context.textTheme.bodyMedium)?.copyWith(
              fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: (isLarge ? context.textTheme.titleMedium : context.textTheme.bodyMedium)?.copyWith(
              fontWeight: FontWeight.bold,
              color: amountColor,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}
