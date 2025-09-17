
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled/src/theme/app_theme.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import 'package:iconsax/iconsax.dart';
import '../../payment/presentation/pay_rent_screen.dart';
import '../../payment/presentation/view_billing_screen.dart';
import '../../../core/snackbars/loaders.dart';



// Transaction model for type safety
class Transaction {
  final String date;
  final String reference;
  final double amount;

  const Transaction({
    required this.date,
    required this.reference,
    required this.amount,
  });

  bool get isPositive => amount >= 0;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int currentPage = 0;
  
  
  // Sample announcements
  static const List<Map<String, String>> announcements = [
    {
      'title': 'Welcome to Our Community!',
      'content': 'Welcome to Pinesville! We\'re excited to have you as part of our community. Check out our amenities and don\'t hesitate to reach out if you need anything.',
    },
    {
      'title': 'Monthly Community Meeting',
      'content': 'Reminder: Monthly community meeting this Saturday at 2 PM in the clubhouse. We\'ll discuss upcoming improvements and address any concerns.',
    },
    {
      'title': 'Pool Maintenance Notice',
      'content': 'Pool maintenance scheduled for next Tuesday from 8 AM to 12 PM. The pool will be temporarily closed during this time. Thank you for your understanding.',
    },
  ];
  
  // Sample transaction data (up to 6 transactions)
  static const List<Transaction> transactions = [
    Transaction(date: '2025-08-25', reference: 'TXN001', amount: 1250.00),
    Transaction(date: '2025-08-23', reference: 'TXN003', amount: 2100.50),
    Transaction(date: '2025-08-21', reference: 'TXN005', amount: 750.25),
    Transaction(date: '2025-08-21', reference: 'TXN005', amount: 750.25),
    Transaction(date: '2025-08-23', reference: 'TXN003', amount: 2100.50),
    Transaction(date: '2025-08-21', reference: 'TXN005', amount: 750.25),
    Transaction(date: '2025-08-21', reference: 'TXN005', amount: 750.25),
  ];

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _BillingCard(onComingSoon: _showComingSoon),
              SizedBox(height: AppConstants.spacingSM),
              _AnnouncementSection(
                announcements: announcements,
                pageController: _pageController,
                currentPage: currentPage,
                onPageChanged: (index) => setState(() => currentPage = index),
              ),
              SizedBox(height: AppConstants.spacingSM),
              _TransactionSection(
                transactions: transactions,
                onRequestHistory: _showTransactionHistoryDialog,
              ),
              _ImageCard(),
              SizedBox(height: AppConstants.spacingXL),
            ],
          ),
        ),
      ),
    ));
  }

  void _showComingSoon(BuildContext context, String feature) {
    HapticFeedback.lightImpact();
    Loaders.customToast(context, message: '$feature - Coming Soon!');
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
                color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                        color: context.colorScheme.onSurface.withValues(alpha: 0.8),
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
class _BillingCard extends StatelessWidget {
  final Function(BuildContext, String) onComingSoon;
  
  const _BillingCard({required this.onComingSoon});

  @override
  Widget build(BuildContext context) {
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
            'Hi, Caleb!',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'Your rent for this month is',
            style: context.textTheme.bodyLarge?.copyWith(
              fontFamily: 'Montserrat',
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            '₱25,000.00',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          Row(
            children: [
              Expanded(
                child: _BillingButton(
                  label: 'Pay Rent',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PayRentScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: AppConstants.spacingMD),
              Expanded(
                child: _BillingButton(
                  label: 'View Billing',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ViewBillingScreen(),
                      ),
                    );
                  },
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
  final List<Map<String, String>> announcements;
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
                  color: context.colorScheme.onSurface.withValues(alpha:0.6),
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
                    margin: EdgeInsets.symmetric(horizontal: AppConstants.spacingXS),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      border: Border.all(
                        color: context.colorScheme.primary,
                        width: AppConstants.borderWidthMedium,
                      ),
                      borderRadius: context.radiusXL,
                      boxShadow: [
                        BoxShadow(
                          color: context.colorScheme.primary.withValues(alpha: 0.1),
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
                            announcements[index]['title'] ?? 'Announcement',
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
                                announcements[index]['content'] ?? '',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontFamily: 'Montserrat',
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
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
                      color: Colors.black.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(announcements.length, (index) {
                        return AnimatedContainer(
                          duration: AppConstants.durationFast,
                          width: currentPage == index ? 16 : 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: AppConstants.spacingXS / 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: currentPage == index
                                ? context.colorScheme.primary
                                : context.colorScheme.primary.withValues(alpha: .3),
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
}

// Transaction Section Widget
class _TransactionSection extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onRequestHistory;

  const _TransactionSection({
    required this.transactions,
    required this.onRequestHistory,
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
                color: context.colorScheme.outline.withValues(alpha:0.1),
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
                        color: context.colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                    ),
                  ),
                )
              else
                ...transactions.take(6).map((transaction) {
                  return _TransactionItem(transaction: transaction);
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

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppConstants.spacingSM,
        horizontal: AppConstants.spacingXS,
      ),
      margin: EdgeInsets.only(bottom: AppConstants.spacingXS),
      child: Row(
        children: [
          // Left side - Date and Reference
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
                    color: context.colorScheme.onSurface.withValues(alpha:0.7),
                  ),
                ),
              ],
            ),
          ),
          // Right side - Amount
          Expanded(
            flex: 2,
            child: Text(
              '₱${transaction.amount.abs().toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: transaction.isPositive 
                    ? context.colorScheme.success
                    : context.colorScheme.error,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
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
