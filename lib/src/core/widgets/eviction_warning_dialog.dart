import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../theme/app_constants.dart';
import '../../theme/theme_extensions.dart';
import '../../features/billing/domain/eviction_status.dart';

class EvictionWarningDialog extends StatelessWidget {
  final EvictionStatus evictionStatus;
  final VoidCallback? onContactAdmin;

  const EvictionWarningDialog({
    super.key,
    required this.evictionStatus,
    this.onContactAdmin,
  });

  static Future<void> show(
    BuildContext context, {
    required EvictionStatus evictionStatus,
    VoidCallback? onContactAdmin,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EvictionWarningDialog(
        evictionStatus: evictionStatus,
        onContactAdmin: onContactAdmin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: context.radiusMD,
      ),
      title: Row(
        children: [
          Icon(
            Iconsax.warning_2,
            color: context.colorScheme.error,
            size: 28,
          ),
          SizedBox(width: AppConstants.spacingSM),
          Expanded(
            child: Text(
              'Eviction Warning',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: context.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              color: context.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: context.radiusSM,
              border: Border.all(
                color: context.colorScheme.error.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Iconsax.info_circle,
                  size: 20,
                  color: context.colorScheme.error,
                ),
                SizedBox(width: AppConstants.spacingSM),
                Expanded(
                  child: Text(
                    evictionStatus.warningMessage,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: context.colorScheme.error,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          Text(
            'Unpaid Months: ${evictionStatus.unpaidMonthsCount}',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (evictionStatus.oldestUnpaidBill != null) ...[
            SizedBox(height: AppConstants.spacingXS),
            Text(
              'Total Debt: ₱${evictionStatus.consecutiveUnpaidBills?.fold<double>(0.0, (sum, bill) => sum + bill.balance).toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onContactAdmin != null)
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              onContactAdmin!();
            },
            child: Text(
              'Contact Admin',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colorScheme.error,
            foregroundColor: context.colorScheme.onError,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Text(
            'I Understand',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
