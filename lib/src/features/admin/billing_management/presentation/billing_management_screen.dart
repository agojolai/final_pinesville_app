import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../../../billing/presentation/billing_providers.dart';
import '../../../billing/domain/bill_model.dart';
import '../../../billing/domain/payment_model.dart';
import '../../../billing/domain/unit_billing_model.dart';
import '../../../billing/data/billing_repository.dart';
import '../../../../core/repositories/auth_repository.dart';
import '../../../../core/snackbars/loaders.dart';
import '../../../../core/utils/app_logger.dart';
import 'admin_create_bill_screen.dart';
import 'admin_bill_detail_screen.dart';

class BillingManagementScreen extends ConsumerStatefulWidget {
  const BillingManagementScreen({
    super.key,
    required this.onMenuTap,
  });

  final VoidCallback onMenuTap;

  @override
  ConsumerState<BillingManagementScreen> createState() => _BillingManagementScreenState();
}

class _BillingManagementScreenState extends ConsumerState<BillingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filters for Bills Overview tab
  String? _selectedPropertyFilter;
  String _selectedStatusFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Iconsax.menu,
            color: context.colorScheme.onSurface,
          ),
          tooltip: 'Open navigation menu',
          onPressed: widget.onMenuTap,
        ),
        title: Text(
          'Billing Management',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Iconsax.add_circle),
              text: 'Create Bills',
            ),
            Tab(
              icon: Icon(Iconsax.verify),
              text: 'Validate Payments',
            ),
            Tab(
              icon: Icon(Iconsax.document_text),
              text: 'Bills Overview',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateBillsTab(),
          _buildValidatePaymentsTab(),
          _buildBillsOverviewTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: CREATE BILLS ====================

  Widget _buildCreateBillsTab() {
    final propertiesAsync = ref.watch(propertiesProvider);

    return propertiesAsync.when(
      data: (properties) {
        if (properties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.building,
                  size: 64,
                  color: context.colorScheme.primary.withValues(alpha: 0.5),
                ),
                SizedBox(height: AppConstants.spacingMD),
                Text(
                  'No Properties Found',
                  style: context.textTheme.titleMedium,
                ),
                SizedBox(height: AppConstants.spacingSM),
                Text(
                  'Add properties to start creating bills',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppConstants.spacingMD),
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            final propertyId = property['id'] as String;
            final propertyName = property['name'] as String? ?? 'Unknown Property';

            return _buildPropertySection(propertyId, propertyName);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading properties: $error'),
      ),
    );
  }

  Widget _buildPropertySection(String propertyId, String propertyName) {
    final unitsAsync = ref.watch(unitsForPropertyProvider(propertyId));
    final now = DateTime.now();

    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.spacingMD),
      child: ExpansionTile(
        leading: Icon(Iconsax.building, color: context.colorScheme.primary),
        title: Text(
          propertyName,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          unitsAsync.when(
            data: (units) {
              if (units.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(AppConstants.spacingMD),
                  child: Text(
                    'No occupied units in this property',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              }

              return Column(
                children: units.map((unit) {
                  return _buildUnitCard(unit, propertyName, now.month, now.year);
                }).toList(),
              );
            },
            loading: () => Padding(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              child: const CircularProgressIndicator(),
            ),
            error: (error, stack) => Padding(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              child: Text('Error: $error'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(UnitBillingInfo unit, String propertyName, int month, int year) {
    // Check if bill exists for this unit for current month
    final billId = 'BILL_${year}_${month.toString().padLeft(2, '0')}_${unit.tenantId}';
    final billAsync = ref.watch(billProvider(billId));

    return billAsync.when(
      data: (bill) {
        final bool isBilled = bill != null;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isBilled 
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.2),
            child: Icon(
              isBilled ? Iconsax.tick_circle5 : Iconsax.info_circle,
              color: isBilled ? Colors.green : Colors.orange,
            ),
          ),
          title: Text(
            'Unit ${unit.unitNumber}',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tenant ID: ${unit.tenantId ?? "N/A"}'),
              Text(
                'Rent: ₱${unit.monthlyRent.toStringAsFixed(2)}',
                style: const TextStyle(fontFamily: 'Montserrat'),
              ),
            ],
          ),
          trailing: isBilled
              ? FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminBillDetailScreen(billId: billId),
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.eye),
                  label: const Text('View Bill'),
                )
              : FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminCreateBillScreen(
                          propertyId: unit.propertyId,
                          propertyName: propertyName,
                          unit: unit,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.add_circle),
                  label: const Text('Create Bill'),
                ),
        );
      },
      loading: () => ListTile(
        leading: const CircularProgressIndicator(),
        title: Text('Unit ${unit.unitNumber}'),
        subtitle: const Text('Checking billing status...'),
      ),
      error: (error, stack) => ListTile(
        leading: const Icon(Iconsax.danger),
        title: Text('Unit ${unit.unitNumber}'),
        subtitle: Text('Error: $error'),
      ),
    );
  }

  // ==================== TAB 2: VALIDATE PAYMENTS ====================

  Widget _buildValidatePaymentsTab() {
    final paymentsAsync = ref.watch(pendingVerificationPaymentsProvider);

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.tick_circle,
                  size: 64,
                  color: context.colorScheme.primary.withValues(alpha: 0.5),
                ),
                SizedBox(height: AppConstants.spacingMD),
                Text(
                  'No Pending Payments',
                  style: context.textTheme.titleMedium,
                ),
                SizedBox(height: AppConstants.spacingSM),
                Text(
                  'All payments have been verified',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppConstants.spacingMD),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _buildPaymentCard(payment);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        AppLogger.error('Error loading payments', error, stack);
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
                'Error Loading Payments',
                style: context.textTheme.titleMedium,
              ),
              SizedBox(height: AppConstants.spacingSM),
              Text(
                '$error',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.spacingMD),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Payment Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Iconsax.wallet_money,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(width: AppConstants.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.userName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Unit: ${payment.unitId}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSM,
                    vertical: AppConstants.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                  child: Text(
                    '₱${payment.amount.toStringAsFixed(2)}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            
            Divider(height: AppConstants.spacingLG),
            
            // Payment Details
            _buildDetailRow('Payment Method', payment.paymentMethod.displayName, Iconsax.card),
            SizedBox(height: AppConstants.spacingXS),
            _buildDetailRow(
              'Transaction Date',
              _formatDate(payment.transactionDate),
              Iconsax.calendar,
            ),
            SizedBox(height: AppConstants.spacingXS),
            _buildDetailRow(
              'Paid For',
              payment.paidFor.map((c) => c.displayName).join(', '),
              Iconsax.receipt_item,
            ),
            
            if (payment.notes.isNotEmpty) ...[
              SizedBox(height: AppConstants.spacingSM),
              Container(
                padding: EdgeInsets.all(AppConstants.spacingSM),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Iconsax.message_text,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: AppConstants.spacingXS),
                    Expanded(
                      child: Text(
                        payment.notes,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Proof of Payment
            if (payment.proofOfPaymentUrl != null) ...[
              SizedBox(height: AppConstants.spacingMD),
              Text(
                'Proof of Payment',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppConstants.spacingSM),
              InkWell(
                onTap: () => _showProofImage(payment.proofOfPaymentUrl!),
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    child: Image.network(
                      payment.proofOfPaymentUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.gallery_slash,
                                size: 48,
                                color: colorScheme.error,
                              ),
                              SizedBox(height: AppConstants.spacingSM),
                              Text(
                                'Failed to load image',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppConstants.spacingXS),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showProofImage(payment.proofOfPaymentUrl!),
                  icon: const Icon(Iconsax.eye, size: 16),
                  label: const Text('View Full Size'),
                ),
              ),
            ],
            
            SizedBox(height: AppConstants.spacingMD),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _approvePayment(payment),
                    icon: const Icon(Iconsax.tick_circle),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.spacingSM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPayment(payment),
                    icon: const Icon(Iconsax.close_circle),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        SizedBox(width: AppConstants.spacingXS),
        Text(
          '$label: ',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month]} ${date.day}, ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showProofImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Proof of Payment'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.gallery_slash,
                            size: 64,
                            color: context.colorScheme.error,
                          ),
                          SizedBox(height: AppConstants.spacingMD),
                          Text(
                            'Failed to load image',
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: context.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approvePayment(PaymentModel payment) async {
    final adminUser = AuthRepository.instance.authUser;
    if (adminUser == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Error',
        message: 'Admin user not found',
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payment'),
        content: Text(
          'Approve payment of ₱${payment.amount.toStringAsFixed(2)} from ${payment.userName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repository = ref.read(billingRepositoryProvider);
      await repository.verifyPayment(
        paymentId: payment.paymentId,
        adminUserId: adminUser.uid,
        approve: true,
        adminNotes: 'Payment approved by admin',
      );

      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Success',
          message: 'Payment approved successfully',
        );
      }

      // Refresh the payments list
      ref.invalidate(pendingVerificationPaymentsProvider);
    } catch (e) {
      AppLogger.error('Error approving payment', e);
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to approve payment: $e',
        );
      }
    }
  }

  Future<void> _rejectPayment(PaymentModel payment) async {
    final adminUser = AuthRepository.instance.authUser;
    if (adminUser == null) {
      Loaders.errorSnackBar(
        context,
        title: 'Error',
        message: 'Admin user not found',
      );
      return;
    }

    // Show rejection reason dialog
    String? rejectionReason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject payment of ₱${payment.amount.toStringAsFixed(2)} from ${payment.userName}?',
            ),
            SizedBox(height: AppConstants.spacingMD),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => rejectionReason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colorScheme.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (rejectionReason == null || rejectionReason!.trim().isEmpty) {
      Loaders.warningSnackBar(
        context,
        title: 'Warning',
        message: 'Please provide a rejection reason',
      );
      return;
    }

    try {
      final repository = ref.read(billingRepositoryProvider);
      await repository.verifyPayment(
        paymentId: payment.paymentId,
        adminUserId: adminUser.uid,
        approve: false,
        adminNotes: rejectionReason!,
      );

      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Success',
          message: 'Payment rejected',
        );
      }

      // Refresh the payments list
      ref.invalidate(pendingVerificationPaymentsProvider);
    } catch (e) {
      AppLogger.error('Error rejecting payment', e);
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to reject payment: $e',
        );
      }
    }
  }

  // ==================== TAB 3: BILLS OVERVIEW ====================

  Widget _buildBillsOverviewTab() {
    return Column(
      children: [
        _buildOverviewFilters(),
        Expanded(child: _buildBillsTable()),
      ],
    );
  }

  Widget _buildOverviewFilters() {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Property Filter
              Expanded(
                flex: 3,
                child: propertiesAsync.when(
                  data: (properties) {
                    return DropdownButtonFormField<String>(
                      value: _selectedPropertyFilter,
                      decoration: const InputDecoration(
                        labelText: 'Property',
                        prefixIcon: Icon(Iconsax.building),
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Properties', overflow: TextOverflow.ellipsis),
                        ),
                        ...properties.map((p) {
                          final propertyName = p['name'] as String? ?? 'Unknown';
                          return DropdownMenuItem(
                            value: p['id'] as String,
                            child: Text(
                              propertyName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPropertyFilter = value;
                        });
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              // Status Filter
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Iconsax.filter),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'partial', child: Text('Partial')),
                    DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatusFilter = value ?? 'all';
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingMD),
          // Search
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search by Unit Number',
              prefixIcon: Icon(Iconsax.search_normal),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillsTable() {
    final billsAsync = ref.watch(currentMonthBillsProvider);

    return billsAsync.when(
      data: (bills) {
        // Apply filters
        var filteredBills = bills.where((bill) {
          // Property filter
          if (_selectedPropertyFilter != null && bill.propertyId != _selectedPropertyFilter) {
            return false;
          }

          // Status filter
          if (_selectedStatusFilter != 'all') {
            if (_selectedStatusFilter == 'paid' && !bill.isPaid) return false;
            if (_selectedStatusFilter == 'partial' && !bill.isPartiallyPaid) return false;
            if (_selectedStatusFilter == 'overdue' && !bill.isOverdue) return false;
          }

          // Search filter
          if (_searchQuery.isNotEmpty && !bill.unitId.toLowerCase().contains(_searchQuery)) {
            return false;
          }

          return true;
        }).toList();

        if (filteredBills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.document_text,
                  size: 64,
                  color: context.colorScheme.primary.withValues(alpha: 0.5),
                ),
                SizedBox(height: AppConstants.spacingMD),
                Text(
                  'No Bills Found',
                  style: context.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // Group by property
        final billsByProperty = <String, List<BillModel>>{};
        for (final bill in filteredBills) {
          billsByProperty.putIfAbsent(bill.propertyId, () => []).add(bill);
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Unit')),
                DataColumn(label: Text('Tenant')),
                DataColumn(label: Text('Rent')),
                DataColumn(label: Text('⚡ Electricity')),
                DataColumn(label: Text('💧 Water')),
                DataColumn(label: Text('🗑️ Trash')),
                DataColumn(label: Text('📶 WiFi')),
                DataColumn(label: Text('🅿️ Parking')),
                DataColumn(label: Text('Additional')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Paid')),
                DataColumn(label: Text('Balance')),
                DataColumn(label: Text('Status')),
              ],
              rows: billsByProperty.entries.expand((entry) {
                final propertyId = entry.key;
                final propertyBills = entry.value;
                
                return [
                  // Property header row
                  DataRow(
                    color: WidgetStateProperty.all(
                      context.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    ),
                    cells: [
                      DataCell(
                        Text(
                          '🏢 Property: $propertyId',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...List.generate(12, (_) => const DataCell(Text(''))),
                    ],
                  ),
                  // Bill rows
                  ...propertyBills.map((bill) => _buildBillRow(bill)),
                ];
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading bills: $error'),
      ),
    );
  }

  DataRow _buildBillRow(BillModel bill) {
    Color statusColor;
    String statusText;

    if (bill.isPaid) {
      statusColor = Colors.green;
      statusText = 'Paid ✓';
    } else if (bill.isPartiallyPaid) {
      statusColor = Colors.orange;
      statusText = 'Partial';
    } else if (bill.isOverdue) {
      statusColor = Colors.red;
      statusText = 'Overdue';
    } else {
      statusColor = Colors.grey;
      statusText = 'Pending';
    }

    return DataRow(
      onSelectChanged: (_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminBillDetailScreen(billId: bill.billId),
          ),
        );
      },
      cells: [
        DataCell(Text(bill.unitId)),
        DataCell(Text(bill.userName)),
        DataCell(_buildAmountCell(bill.baseRent, bill.rentBreakdown.isPaid)),
        DataCell(_buildAmountCell(bill.electricity.amount, bill.electricityBreakdown.isPaid)),
        DataCell(_buildAmountCell(bill.water.amount, bill.waterBreakdown.isPaid)),
        DataCell(_buildAmountCell(bill.trashBreakdown.amount, bill.trashBreakdown.isPaid)),
        DataCell(_buildAmountCell(bill.wifiBreakdown.amount, bill.wifiBreakdown.isPaid)),
        DataCell(_buildAmountCell(bill.parkingBreakdown.amount, bill.parkingBreakdown.isPaid)),
        DataCell(_buildAmountCell(bill.additionalChargesBreakdown.amount, bill.additionalChargesBreakdown.isPaid)),
        DataCell(
          Text(
            '₱${bill.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Text(
            '₱${bill.amountPaid.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Text(
            '₱${bill.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCell(double amount, bool isPaid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '₱${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          isPaid ? Iconsax.tick_circle5 : Iconsax.close_circle5,
          color: isPaid ? Colors.green : Colors.grey,
          size: 16,
        ),
      ],
    );
  }
}
