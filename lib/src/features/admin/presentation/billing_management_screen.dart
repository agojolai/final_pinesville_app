import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../billing/presentation/billing_providers.dart';
import '../../billing/domain/bill_model.dart';
import '../../billing/domain/unit_billing_model.dart';
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
                  color: context.colorScheme.primary.withOpacity(0.5),
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
                    color: context.colorScheme.onSurface.withOpacity(0.6),
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
                      color: context.colorScheme.onSurface.withOpacity(0.6),
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
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
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
              Text('Rent: ₱${unit.monthlyRent.toStringAsFixed(2)}'),
              if (unit.lastElectricityReading != null)
                Text('⚡ Last: ${unit.lastElectricityReading!.reading} kWh'),
              if (unit.lastWaterReading != null)
                Text('💧 Last: ${unit.lastWaterReading!.reading} m³'),
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
                  color: context.colorScheme.primary.withOpacity(0.5),
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
                    color: context.colorScheme.onSurface.withOpacity(0.6),
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
      error: (error, stack) => Center(
        child: Text('Error loading payments: $error'),
      ),
    );
  }

  Widget _buildPaymentCard(payment) {
    // TODO: Implement payment validation card
    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.spacingMD),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: const Text('Payment validation card - Coming soon'),
      ),
    );
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
            color: context.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Property Filter
              Expanded(
                child: propertiesAsync.when(
                  data: (properties) {
                    return DropdownButtonFormField<String>(
                      value: _selectedPropertyFilter,
                      decoration: const InputDecoration(
                        labelText: 'Property',
                        prefixIcon: Icon(Iconsax.building),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Properties'),
                        ),
                        ...properties.map((p) {
                          return DropdownMenuItem(
                            value: p['id'] as String,
                            child: Text(p['name'] as String? ?? 'Unknown'),
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
              SizedBox(width: AppConstants.spacingMD),
              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Iconsax.filter),
                  ),
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
                  color: context.colorScheme.primary.withOpacity(0.5),
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
                      context.colorScheme.primaryContainer.withOpacity(0.3),
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
        DataCell(Text('₱${bill.total.toStringAsFixed(2)}')),
        DataCell(Text('₱${bill.amountPaid.toStringAsFixed(2)}')),
        DataCell(Text('₱${bill.balance.toStringAsFixed(2)}')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
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
        Text('₱${amount.toStringAsFixed(0)}'),
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
