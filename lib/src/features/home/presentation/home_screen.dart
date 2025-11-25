import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled/src/theme/app_theme.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import 'package:iconsax/iconsax.dart';
import '../../payment/presentation/pay_rent_screen.dart';
import '../../payment/presentation/view_billing_screen.dart';
import '../../payment/presentation/unpaid_bills_list_screen.dart';
import '../../payment/presentation/transaction_history_screen.dart';
import '../../../core/snackbars/loaders.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/widgets/eviction_warning_dialog.dart';
import '../../billing/presentation/billing_providers.dart';
import '../../billing/domain/bill_model.dart';
import '../../billing/domain/eviction_status.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/data/models/user_model.dart';
import '../../consumption/providers/consumption_providers.dart';
import '../../admin/announcements/providers/announcements_providers.dart';
import '../../admin/announcements/data/models/announcement_model.dart';

// Transaction model for type safety
class Transaction {
  final String date;
  final String reference;
  final double amount;
  final BillModel bill; // Add bill reference for navigation

  const Transaction({
    required this.date,
    required this.reference,
    required this.amount,
    required this.bill,
  });

  bool get isPositive => amount >= 0;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}





class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int currentPage = 0;
  bool _hasShownEvictionWarning = false; // Track if eviction warning shown

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: AppConstants.durationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    // Check eviction status after build (removed persistent flag)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Eviction status now monitored via ref.listen in build method
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<Transaction> _convertBillsToTransactions(List<BillModel> bills) {
    // Filter to only show paid bills
    return bills
        .where((bill) => bill.isPaid)
        .take(6)
        .map((bill) {
      final monthName = _getMonthName(bill.billingPeriod.month);
      final date = '$monthName ${bill.billingPeriod.year}';

      return Transaction(
        date: date,
        reference: bill.billId,
        amount: bill.amountPaid,
        bill: bill,
      );
    }).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Get current user ID
    final currentUser = AuthRepository.instance.authUser;
    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final userId = currentUser.uid;

    // Watch user profile provider
    final userProfileAsync = ref.watch(userProfileProvider);

    // Watch bills provider
    final billsAsync = ref.watch(userBillsProvider(userId));

    // Watch eviction status and show dialog when needed
    ref.listen<AsyncValue<EvictionStatus>>(
      evictionStatusProvider(userId),
      (previous, next) {
        next.whenData((evictionStatus) {
          if (evictionStatus.isFacingEviction && !_hasShownEvictionWarning && mounted) {
            _hasShownEvictionWarning = true;
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              EvictionWarningDialog.show(
                context,
                evictionStatus: evictionStatus,
                onContactAdmin: () {
                  Loaders.infoSnackBar(
                    context,
                    title: 'Contact Admin',
                    message: 'Please switch to the "Chat Admin" tab to contact the admin.',
                  );
                },
              );
            });
          } else if (!evictionStatus.isFacingEviction) {
            // Reset flag when no longer facing eviction
            _hasShownEvictionWarning = false;
          }
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: context.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        fontFamily: 'Montserrat',
          ),
        ),
        toolbarHeight: AppConstants.appBarHeight,
        elevation: 0,
        backgroundColor: context.colorScheme.surface,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppConstants.spacingSM),
            child: IconButton(
              icon: Icon(Iconsax.notification_bing, color: context.colorScheme.primary),
              tooltip: 'Notifications',
              onPressed: () {
          // TODO: Implement notification screen navigation
          Loaders.infoSnackBar(
            context,
            title: 'Coming Soon',
            message: 'Notifications feature is coming soon!',
          );
              },
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ResponsiveLayoutWrapper(
          centerContent: true,
          child: billsAsync.when(
            data: (bills) {
              // Get user profile data
              return userProfileAsync.when(
                data: (userModel) {
                  // Watch announcements stream
                  final announcementsAsync = ref.watch(activeAnnouncementsStreamProvider);

                  // Find latest unpaid bill for the billing card
                  BillModel? latestUnpaidBill;
                  try {
                    latestUnpaidBill = bills.firstWhere((bill) => !bill.isPaid);
                  } catch (e) {
                    // If no unpaid bills, use the latest bill (if any)
                    latestUnpaidBill = bills.isNotEmpty ? bills.first : null;
                  }

                  // Convert bills to transactions
                  final transactions = _convertBillsToTransactions(bills);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BillingCard(
                          bill: latestUnpaidBill,
                          userModel: userModel,
                          onRentPaid: _showRentPaidMessage,
                        ),
                        SizedBox(height: AppConstants.spacingSM),
                        announcementsAsync.when(
                          data: (allAnnouncements) {
                            // Debug: Print all announcements and their recipients
                            print('📢 DEBUG: Total announcements: ${allAnnouncements.length}');
                            for (var ann in allAnnouncements) {
                              print('  - Title: "${ann.title}"');
                              print('    Recipients: ${ann.recipients}');
                              print('    Recipients length: ${ann.recipients.length}');
                            }
                            
                            // Filter announcements for this user's property
                            final userPropertyId = userModel.propertyId;
                            final userPropertyName = userModel.propertyName;
                            print('🏠 DEBUG: User propertyId: "$userPropertyId"');
                            print('🏠 DEBUG: User propertyName: "$userPropertyName"');
                            print('🏠 DEBUG: User full name: "${userModel.fullName}"');
                            
                            final filteredAnnouncements = allAnnouncements.where((announcement) {
                              // Check if recipients is empty
                              if (announcement.recipients.isEmpty) {
                                print('  ⚠️ ${announcement.title}: Empty recipients array!');
                                return false;
                              }
                              
                              // Case-insensitive check for "All Properties"
                              final hasAllProperties = announcement.recipients.any(
                                (recipient) => recipient.toLowerCase() == 'all properties'
                              );
                              
                              // Check if user's property ID or name is in recipients
                              final hasUserProperty = announcement.recipients.contains(userPropertyId) ||
                                                     announcement.recipients.contains(userPropertyName);
                              
                              print('  🔍 Checking "${announcement.title}":');
                              print('     - Has "All Properties": $hasAllProperties');
                              print('     - Has User Property: $hasUserProperty');
                              
                              return hasAllProperties || hasUserProperty;
                            }).toList();
                            
                            print('✅ DEBUG: Filtered announcements: ${filteredAnnouncements.length}');
                            if (filteredAnnouncements.isEmpty && allAnnouncements.isNotEmpty) {
                              print('⚠️ WARNING: Announcements exist but none match user property!');
                            }

                            return _AnnouncementSection(
                              announcements: filteredAnnouncements,
                              pageController: _pageController,
                              currentPage: currentPage,
                              onPageChanged: (index) =>
                                  setState(() => currentPage = index),
                            );
                          },
                          loading: () => Container(
                            height: 250,
                            margin: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                            decoration: BoxDecoration(
                              color: context.colorScheme.surface,
                              borderRadius: context.radiusXL,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stack) => Container(
                            height: 250,
                            margin: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                            decoration: BoxDecoration(
                              color: context.colorScheme.surface,
                              borderRadius: context.radiusXL,
                            ),
                            child: Center(
                              child: Text(
                                'No announcements available',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppConstants.spacingSM),
                        _TransactionSection(
                          transactions: transactions,
                          onRequestHistory: _showTransactionHistoryDialog,
                          onTransactionTap: (transaction) {
                            HapticFeedback.lightImpact();
                            // Navigate to Transaction History for paid bills, View Billing for unpaid
                            if (transaction.bill.isPaid) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TransactionHistoryScreen(
                                          bill: transaction.bill),
                                ),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ViewBillingScreen(bill: transaction.bill),
                                ),
                              );
                            }
                          },
                        ),
                        _ImageCard(),
                        SizedBox(height: AppConstants.spacingSM),
                        _ConsumptionSection(userId: userId),
                        SizedBox(height: AppConstants.spacingXL),
                      ],
                    ),
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error loading user data: $error'),
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(),
            ),
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
        ),
      ),
    );
  }

  void _showRentPaidMessage(BuildContext context) {
    HapticFeedback.lightImpact();
    Loaders.infoSnackBar(
      context,
      title: 'Rent Paid',
      message: 'You have no pending bills to pay at this time.',
    );
  }


  void _showTransactionHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Iconsax.document_text,
              color: context.colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Text(
              'Transaction History',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like to request your complete transaction history?',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
              ),
            ),
            SizedBox(height: AppConstants.spacingSM),
            Container(
              padding: EdgeInsets.all(AppConstants.spacingSM),
              decoration: BoxDecoration(
                color:
                    context.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 16,
                    color: context.colorScheme.primary,
                  ),
                  SizedBox(width: AppConstants.spacingXS),
                  Expanded(
                    child: Text(
                      'Your full transaction history will be emailed to you within 24 hours.',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _requestTransactionHistory();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.send_2, size: 16),
                SizedBox(width: AppConstants.spacingXS),
                Text(
                  'Request History',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _requestTransactionHistory() {
    HapticFeedback.heavyImpact();
    Loaders.successSnackBar(
      context,
      title: 'Request Submitted!',
      message: 'You\'ll receive transaction history via email within 24 hours.',
      duration: 4,
    );
  }
}

// Billing Card Widget
class _BillingCard extends ConsumerWidget {
  final BillModel? bill;
  final UserModel userModel;
  final Function(BuildContext) onRentPaid;

  const _BillingCard({
    this.bill,
    required this.userModel,
    required this.onRentPaid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch total debt provider
    final totalDebtAsync = ref.watch(userTotalDebtProvider(userModel.id ?? ''));
    
    // Watch oldest unpaid bill provider for Pay Rent navigation
    final oldestBillAsync = ref.watch(oldestUnpaidBillProvider(userModel.id ?? ''));
    
    final hasUnpaidBill = bill != null && !bill!.isPaid;

    return Container(
      margin: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary,
            context.colorScheme.primary.withValues(alpha: 0.92),
            context.colorScheme.primaryContainer,
          ],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
        ),
        borderRadius: context.radiusXL,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, ${userModel.fullName.split(' ').first}!',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            hasUnpaidBill ? 'Your total outstanding balance is' : 'No pending bills',
            style: context.textTheme.bodyLarge?.copyWith(
              fontFamily: 'Montserrat',
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (hasUnpaidBill) ...[
            SizedBox(height: AppConstants.spacingSM),
            totalDebtAsync.when(
              data: (totalDebt) => Text(
                '₱${totalDebt.toStringAsFixed(2)}',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                ),
              ),
              loading: () => Text(
                '₱${(bill?.balance ?? 0.0).toStringAsFixed(2)}',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                ),
              ),
              error: (_, __) => Text(
                '₱${(bill?.balance ?? 0.0).toStringAsFixed(2)}',
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                ),
              ),
            ),
          ],
          SizedBox(height: AppConstants.spacingMD),
          Row(
            children: [
              Expanded(
                child: _BillingButton(
                  label: 'Pay Rent',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (hasUnpaidBill) {
                      // Use the watched oldest unpaid bill
                      final oldestBill = oldestBillAsync.value;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PayRentScreen(bill: oldestBill),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PayRentScreen(bill: bill),
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(width: AppConstants.spacingMD),
              Expanded(
                child: _BillingButton(
                  label: 'View Billing',
                  onPressed: bill != null
                      ? () {
                          HapticFeedback.lightImpact();
                          if (!hasUnpaidBill) {
                            // Show "Rent Paid" message if bill is already paid
                            onRentPaid(context);
                          } else {
                            // Navigate to unpaid bills list screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const UnpaidBillsListScreen(),
                              ),
                            );
                          }
                        }
                      : () => onRentPaid(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Billing Button Widget
class _BillingButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _BillingButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colorScheme.primaryContainer,
        foregroundColor: context.colorScheme.onPrimaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusSM,
        ),
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
        shadowColor: context.colorScheme.primary.withValues(alpha: 0.18),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}

// Announcement Section Widget
class _AnnouncementSection extends StatelessWidget {
  final List<AnnouncementModel> announcements;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _AnnouncementSection({
    required this.announcements,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    // If no announcements, show a message
    if (announcements.isEmpty) {
      return Container(
        height: 250,
        margin: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          border: Border.all(
            color: context.colorScheme.primary.withValues(alpha: 0.3),
            width: AppConstants.borderWidthMedium,
          ),
          borderRadius: context.radiusXL,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.message_text,
                size: 48,
                color: context.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              SizedBox(height: AppConstants.spacingSM),
              Text(
                'No announcements yet',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Announcements',
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            if (announcements.length > 1)
              Text(
                '${currentPage + 1} of ${announcements.length}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontFamily: 'Montserrat',
                ),
              ),
          ],
        ),
        SizedBox(height: AppConstants.spacingSM),
        Stack(
          children: [
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingXS),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      border: Border.all(
                        color: context.colorScheme.primary,
                        width: AppConstants.borderWidthMedium,
                      ),
                      borderRadius: context.radiusXL,
                      boxShadow: [
                        BoxShadow(
                          color: context.colorScheme.primary
                              .withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.spacingLG),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            announcements[index].title,
                            style: context.textTheme.titleLarge?.copyWith(
                              color: context.colorScheme.primary,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppConstants.spacingSM),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                announcements[index].message,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontFamily: 'Montserrat',
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          SizedBox(height: AppConstants.spacingSM),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              _formatAnnouncementTimestamp(announcements[index].timestamp),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (announcements.length > 1)
              Positioned(
                bottom: AppConstants.spacingSM,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingSM,
                      vertical: AppConstants.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(announcements.length, (index) {
                        return AnimatedContainer(
                          duration: AppConstants.durationFast,
                          width: currentPage == index ? 16 : 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingXS / 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: currentPage == index
                                ? context.colorScheme.primary
                                : context.colorScheme.primary
                                    .withValues(alpha: .3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatAnnouncementTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Format date
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months[timestamp.month - 1];
    final day = timestamp.day;
    final year = timestamp.year;
    
    // Convert to 12-hour format
    final hour12 = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final timeString = '$hour12:$minute $amPm';

    // If posted today, show time only
    if (difference.inDays == 0 && timestamp.day == now.day) {
      return timeString;
    }
    // If posted yesterday
    else if (difference.inDays == 1 || 
             (difference.inHours < 48 && timestamp.day == now.day - 1)) {
      return 'Yesterday $timeString';
    }
    // If posted this year, show month, day, and time
    else if (timestamp.year == now.year) {
      return '$month $day, $year $timeString';
    }
    // If posted in previous years, include year
    else {
      return '$month $day, $year $timeString';
    }
  }
}

// Transaction Section Widget
class _TransactionSection extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onRequestHistory;
  final Function(Transaction) onTransactionTap;

  const _TransactionSection({
    required this.transactions,
    required this.onRequestHistory,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions',
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
          padding: EdgeInsets.all(AppConstants.spacingMD),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: context.radiusXL,
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.outline.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.spacingXL),
                    child: Text(
                      'No transactions yet',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              else
                ...transactions.take(6).map((transaction) {
                  return _TransactionItem(
                    transaction: transaction,
                    onTap: () => onTransactionTap(transaction),
                  );
                }),
              if (transactions.length > 6)
                Padding(
                  padding: EdgeInsets.only(top: AppConstants.spacingSM),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onRequestHistory();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppConstants.spacingXS,
                          horizontal: AppConstants.spacingSM,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '+ more transactions',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            SizedBox(width: AppConstants.spacingXS),
                            Icon(
                              Iconsax.arrow_right_3,
                              size: 14,
                              color: context.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Transaction Item Widget
class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionItem({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get color based on bill status
    Color statusColor;
    if (transaction.bill.isPaid) {
      statusColor = context.colorScheme.success; // Green
    } else if (transaction.bill.isOverdue ||
        transaction.bill.lateFeeDetails.isLate) {
      statusColor = context.colorScheme.error; // Red
    } else {
      statusColor = context.colorScheme.warning; // Yellow/Orange
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppConstants.spacingSM,
            horizontal: AppConstants.spacingXS,
          ),
          margin: EdgeInsets.only(bottom: AppConstants.spacingXS),
          child: Row(
            children: [
              // Left side - Color indicator, Date and Reference
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.date,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Text(
                      transaction.reference,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Right side - Amount
              Expanded(
                flex: 2,
                child: Text(
                  '₱${transaction.amount.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Image Card Widget
class _ImageCard extends StatelessWidget {
  const _ImageCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
      shape: RoundedRectangleBorder(
        borderRadius: context.radiusXL,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Image.asset(
          'assets/images/IMG.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// Consumption Data Model
class ConsumptionData {
  final String month;
  final double value;
  final String unit;

  const ConsumptionData({
    required this.month,
    required this.value,
    required this.unit,
  });
}

// Consumption Section Widget
class _ConsumptionSection extends ConsumerWidget {
  final String userId;

  const _ConsumptionSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch electricity and water consumption providers
    final electricitySummaryAsync =
        ref.watch(tenantElectricityProvider(userId));
    final waterSummaryAsync = ref.watch(tenantWaterProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consumption Overview',
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingSM),

        // Electricity Consumption Chart
        electricitySummaryAsync.when(
          data: (summary) {
            // Convert ConsumptionDataPoint to ConsumptionData for chart widget
            final chartData = summary.dataPoints
                .map((point) => ConsumptionData(
                      month: point.month,
                      value: point.value,
                      unit: point.unit,
                    ))
                .toList();

            return _ConsumptionChart(
              title: 'Electricity Usage',
              icon: Iconsax.flash_1,
              iconColor: Colors.amber,
              data: chartData,
              barColor: Colors.amber,
            );
          },
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _NoDataCard(
            title: 'Electricity Usage',
            icon: Iconsax.flash_1,
            iconColor: Colors.amber,
          ),
        ),

        SizedBox(height: AppConstants.spacingMD),

        // Water Consumption Chart
        waterSummaryAsync.when(
          data: (summary) {
            // Convert ConsumptionDataPoint to ConsumptionData for chart widget
            final chartData = summary.dataPoints
                .map((point) => ConsumptionData(
                      month: point.month,
                      value: point.value,
                      unit: point.unit,
                    ))
                .toList();

            return _ConsumptionChart(
              title: 'Water Usage',
              icon: Iconsax.drop,
              iconColor: Colors.blue,
              data: chartData,
              barColor: Colors.blue,
            );
          },
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _NoDataCard(
            title: 'Water Usage',
            icon: Iconsax.drop,
            iconColor: Colors.blue,
          ),
        ),
      ],
    );
  }
}

// No Data Card Widget - Shows when there's no consumption data
class _NoDataCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _NoDataCard({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.outline.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacingXS),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          
          // No data message
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXL),
              child: Column(
                children: [
                  Icon(
                    Iconsax.chart,
                    size: 48,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: AppConstants.spacingSM),
                  Text(
                    'No consumption data yet',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingXS),
                  Text(
                    'Data will appear after your first billing cycle',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Consumption Chart Widget
class _ConsumptionChart extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<ConsumptionData> data;
  final Color barColor;

  const _ConsumptionChart({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.data,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    // If no data, show no data card
    if (data.isEmpty) {
      return _NoDataCard(
        title: title,
        icon: icon,
        iconColor: iconColor,
      );
    }

    // Determine default max value based on utility type
    final defaultMaxValue = _getDefaultMaxValue();

    // Find actual max value from data
    final actualMaxValue = data.isEmpty
        ? defaultMaxValue
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Use default max or actual max (whichever is higher)
    final maxValue =
        actualMaxValue > defaultMaxValue ? actualMaxValue : defaultMaxValue;

    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusXL,
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.outline.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacingXS),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),

          // Bar Chart
          Column(
            children: data.map((item) {
              // Ensure barWidth is always between 0.0 and 0.85
              final barWidth = maxValue > 0
                  ? ((item.value / maxValue) * 0.85).clamp(0.0, 0.85)
                  : 0.0;
              return _BarChartRow(
                month: item.month,
                value: item.value,
                unit: item.unit,
                barWidth: barWidth,
                barColor: barColor,
              );
            }).toList(),
          ),

          // Average Info
          SizedBox(height: AppConstants.spacingSM),
          Container(
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.chart_1,
                  size: 16,
                  color: barColor,
                ),
                SizedBox(width: AppConstants.spacingXS),
                Text(
                  'Avg: ${_calculateAverage().toStringAsFixed(0)} ${data.first.unit}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get default max value based on utility type
  /// Electricity: 200 kWh, Water: 10 m³
  double _getDefaultMaxValue() {
    // Check if this is electricity (kWh) or water (m³)
    if (data.isEmpty) return 200.0; // Default to electricity

    final unit = data.first.unit;
    if (unit == 'kWh') {
      return 50.0; // Default max for electricity
    } else if (unit == 'm³' || unit == 'm') {
      return 15.0; // Default max for water
    }
    return 150.0; // Fallback
  }

  double _calculateAverage() {
    if (data.isEmpty) return 0.0;
    final sum = data.fold(0.0, (sum, item) => sum + item.value);
    return sum / data.length;
  }
}

// Bar Chart Row Widget
class _BarChartRow extends StatelessWidget {
  final String month;
  final double value;
  final String unit;
  final double barWidth;
  final Color barColor;

  const _BarChartRow({
    required this.month,
    required this.value,
    required this.unit,
    required this.barWidth,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingSM),
      child: Row(
        children: [
          // Month label
          SizedBox(
            width: 40,
            child: Text(
              month,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          SizedBox(width: AppConstants.spacingXS),

          // Bar
          Expanded(
            child: Stack(
              children: [
                // Background bar
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Actual value bar
                FractionallySizedBox(
                  widthFactor: barWidth,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          barColor.withValues(alpha: 0.8),
                          barColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingXS),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppConstants.spacingXS),

          // Unit label
          SizedBox(
            width: 35,
            child: Text(
              unit,
              style: context.textTheme.bodySmall?.copyWith(
                fontFamily: 'Montserrat',
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
