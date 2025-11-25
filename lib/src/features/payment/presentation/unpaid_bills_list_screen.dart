import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../billing/presentation/billing_providers.dart';
import '../../billing/domain/bill_model.dart';
import 'view_billing_screen.dart';

class UnpaidBillsListScreen extends ConsumerWidget {
  const UnpaidBillsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = AuthRepository.instance.authUser?.uid ?? '';
    final unpaidBillsAsync = ref.watch(unpaidBillsOldestFirstProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Unpaid Bills',
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
      body: unpaidBillsAsync.when(
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
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
                    'No Unpaid Bills',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingSM),
                  Text(
                    'You have no outstanding bills at the moment',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppConstants.spacingLG),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return _UnpaidBillCard(
                bill: bill,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ViewBillingScreen(bill: bill),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.warning_2,
                size: 64,
                color: context.colorScheme.error,
              ),
              SizedBox(height: AppConstants.spacingMD),
              Text(
                'Error loading bills',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
}

class _UnpaidBillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback onTap;

  const _UnpaidBillCard({
    required this.bill,
    required this.onTap,
  });

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _getMonthName(bill.billingPeriod.month);
    final isOverdue = bill.isOverdue || bill.lateFeeDetails.isLate;
    
    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.spacingMD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: context.radiusMD,
        side: BorderSide(
          color: isOverdue 
              ? context.colorScheme.error.withValues(alpha: 0.3)
              : context.colorScheme.outline.withValues(alpha: 0.2),
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radiusMD,
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$monthName ${bill.billingPeriod.year}',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingSM,
                        vertical: AppConstants.spacingXS / 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.errorContainer,
                        borderRadius: context.radiusSM,
                      ),
                      child: Text(
                        'OVERDUE',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppConstants.spacingSM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(bill.billingPeriod.dueDate),
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Balance',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '₱${bill.balance.toStringAsFixed(2)}',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOverdue 
                              ? context.colorScheme.error 
                              : context.colorScheme.primary,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (bill.lateFeeDetails.isLate) ...[
                SizedBox(height: AppConstants.spacingSM),
                Container(
                  padding: EdgeInsets.all(AppConstants.spacingSM),
                  decoration: BoxDecoration(
                    color: context.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: context.radiusSM,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.warning_2,
                        size: 16,
                        color: context.colorScheme.error,
                      ),
                      SizedBox(width: AppConstants.spacingXS),
                      Expanded(
                        child: Text(
                          'Late fee: ₱${bill.lateFeeDetails.totalLateFee.toStringAsFixed(2)} (${bill.lateFeeDetails.weeksOverdue} week${bill.lateFeeDetails.weeksOverdue == 1 ? '' : 's'})',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.error,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
