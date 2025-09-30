import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../features/auth/data/models/user_model.dart';

class TenantManagementScreen extends ConsumerStatefulWidget {
  const TenantManagementScreen({
    super.key,
    required this.onMenuTap,
  });

  final VoidCallback onMenuTap;

  @override
  ConsumerState<TenantManagementScreen> createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends ConsumerState<TenantManagementScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, active, pending, suspended
  Timer? _debounceTimer;

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
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value);
      }
    });
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
          'Tenant Management',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        automaticallyImplyLeading: false,
        toolbarHeight: AppConstants.appBarHeight,
        elevation: 0,
        backgroundColor: context.colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => _showSortOptions(),
            icon: Icon(
              Iconsax.sort,
              color: context.colorScheme.onSurface,
            ),
          ),
          IconButton(
            tooltip: 'Refresh Tenants',
            icon: Icon(Icons.refresh, color: context.colorScheme.primary),
            onPressed: () async {
              await ref.read(tenantListProvider.notifier).fetchTenants();
              Loaders.infoSnackBar(context, title: 'Refreshed', message: 'Tenant list updated.');
            },
          ),
          SizedBox(width: AppConstants.spacingSM),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ResponsiveLayoutWrapper(
          centerContent: true,
          child: Column(
            children: [
              _SearchAndStatsSection(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshTenants,
                  child: _TenantList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewTenant(),
        backgroundColor: context.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: Icon(Iconsax.profile_add),
        label: Text('Add Tenant'),
      ),
    );
  }

  Widget _SearchAndStatsSection() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      color: context.colorScheme.surface,
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: context.radiusMD,
              border: Border.all(
                color: context.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search tenants...',
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: Icon(
                          Iconsax.close_circle,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: AppConstants.spacingMD,
                ),
              ),
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All (245)',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                SizedBox(width: AppConstants.spacingSM),
                _FilterChip(
                  label: 'Active (195)',
                  isSelected: _selectedFilter == 'active',
                  onTap: () => setState(() => _selectedFilter = 'active'),
                  color: Colors.green,
                ),
                SizedBox(width: AppConstants.spacingSM),
                _FilterChip(
                  label: 'Pending (8)',
                  isSelected: _selectedFilter == 'pending',
                  onTap: () => setState(() => _selectedFilter = 'pending'),
                  color: Colors.orange,
                ),
                SizedBox(width: AppConstants.spacingSM),
                _FilterChip(
                  label: 'Suspended (2)',
                  isSelected: _selectedFilter == 'suspended',
                  onTap: () => setState(() => _selectedFilter = 'suspended'),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _FilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? context.colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: context.radiusMD,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMD,
            vertical: AppConstants.spacingSM,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? chipColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: context.radiusMD,
            border: Border.all(
              color: isSelected 
                  ? chipColor
                  : context.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: isSelected 
                  ? chipColor
                  : context.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ),
    );
  }

  Widget _TenantList() {
    final tenantAsync = ref.watch(tenantListProvider);
    final isTabletOrDesktop = context.isTablet || context.isDesktop;
    return tenantAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading tenants')), 
      data: (tenants) {
        var filtered = tenants.where((t) {
          if (_selectedFilter != 'all' && t.status != _selectedFilter) return false;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            return t.fullName.toLowerCase().contains(query) ||
                   t.email.toLowerCase().contains(query) ||
                   t.unitId.toLowerCase().contains(query);
          }
          return true;
        }).toList();
        if (isTabletOrDesktop) {
          return GridView.builder(
            padding: EdgeInsets.all(AppConstants.spacingMD),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.getResponsiveColumns(mobileColumns: 1),
              crossAxisSpacing: context.responsiveGridSpacing,
              mainAxisSpacing: context.responsiveGridSpacing,
              childAspectRatio: 2.2,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _TenantCard(
              tenant: filtered[index],
              onTap: () => _viewTenantDetails(filtered[index]),
              isCompact: true,
            ),
          );
        } else {
          return ListView.separated(
            padding: EdgeInsets.all(AppConstants.spacingMD),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => SizedBox(height: AppConstants.spacingMD),
            itemBuilder: (context, index) => _TenantCard(
              tenant: filtered[index],
              onTap: () => _viewTenantDetails(filtered[index]),
              isCompact: false,
            ),
          );
        }
      },
    );
  }

  Widget _TenantCard({
    required UserModel tenant,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    final status = tenant.status;
    final statusColor = _getStatusColor(status);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radiusMD,
        child: Container(
          padding: EdgeInsets.all(AppConstants.spacingMD),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: context.radiusMD,
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Profile image
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: context.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      tenant.fullName.split(' ').map((e) => e[0]).join().toUpperCase(),
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingMD),
                  
                  // Tenant info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tenant.fullName,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingSM,
                                vertical: AppConstants.spacingXS,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: context.radiusSM,
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppConstants.spacingXS),
                        Wrap(
                          spacing: AppConstants.spacingSM,
                          runSpacing: AppConstants.spacingXS,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildInfoChip(
                              icon: Iconsax.home,
                              label: 'Unit ${tenant.unitId}',
                              textColor: context.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            _buildInfoChip(
                              icon: Iconsax.calendar,
                              label: 'Since ${tenant.moveInDate?.toString().substring(0, 10) ?? 'Unknown'}',
                              textColor: context.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                        SizedBox(height: AppConstants.spacingXS),
                        Wrap(
                          spacing: AppConstants.spacingSM,
                          runSpacing: AppConstants.spacingXS,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildInfoChip(
                              icon: Iconsax.money_send,
                              label: '₱${tenant.rentAmount.toStringAsFixed(0)}/month',
                              textColor: context.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                            // Note: Unread messages feature to be implemented
                            // Will need to add this to UserModel or fetch separately
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action button (only for non-pending tenants)
                  if (tenant.status != 'pending')
                    IconButton(
                      onPressed: () => _showTenantActions(tenant),
                      icon: Icon(
                        Iconsax.more_2,
                        color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  // Eye button for pending tenants, Accept button removed
                  if (tenant.status == 'pending')
                    IconButton(
                      onPressed: () => _showPendingTenantDetails(tenant),
                      icon: Icon(
                        Iconsax.eye,
                        color: context.colorScheme.primary,
                        size: 24,
                      ),
                      tooltip: 'View Details',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return context.colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }


  Future<void> _refreshTenants() async {
    // Actually refresh tenants from the provider
    await ref.read(tenantListProvider.notifier).fetchTenants();
  }


  void _showSortOptions() {
    // TODO: Implement sort options
    Loaders.infoSnackBar(
      context,
      title: 'Coming Soon',
      message: 'Sort options will be available in a future update.',
    );
  }

  void _addNewTenant() {
    // TODO: Navigate to add tenant screen
    Loaders.infoSnackBar(
      context,
      title: 'Coming Soon',
      message: 'Add new tenant feature will be available soon.',
    );
  }

  void _viewTenantDetails(UserModel tenant) {
    // TODO: Navigate to tenant details screen
    Loaders.infoSnackBar(
      context,
      title: 'Tenant Details',
      message: 'Viewing details for ${tenant.fullName}',
    );
  }

  void _showPendingTenantDetails(UserModel tenant) {
    final scaffoldContext = context; // Capture the main screen context
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLG),
        ),
      ),
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.only(
            left: AppConstants.spacingLG,
            right: AppConstants.spacingLG,
            top: AppConstants.spacingLG,
            bottom: MediaQuery.of(context).viewPadding.bottom + AppConstants.spacingLG,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: AppConstants.spacingLG),
                    decoration: BoxDecoration(
                      color: context.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: context.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        tenant.fullName.split(' ').map((e) => e[0]).join().toUpperCase(),
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant.fullName,
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: AppConstants.spacingXS),
                            padding: EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingSM,
                              vertical: AppConstants.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: context.radiusSM,
                            ),
                            child: Text(
                              'PENDING APPROVAL',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.spacingLG),
                // Details
                _buildDetailSection('Contact Information', [
                  _buildDetailRow('Email', tenant.email),
                  _buildDetailRow('Phone', tenant.phoneNumber.isNotEmpty ? tenant.phoneNumber : 'Not provided'),
                ]),
                SizedBox(height: AppConstants.spacingMD),
                _buildDetailSection('Property Information', [
                  _buildDetailRow('Unit', tenant.unitId),
                  _buildDetailRow('Property', tenant.propertyName.isNotEmpty ? tenant.propertyName : 'Unknown Property'),
                  _buildDetailRow('Applied On', tenant.createdAt?.toString().substring(0, 10) ?? 'Unknown'),
                ]),
                SizedBox(height: AppConstants.spacingXL),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          _showRejectConfirmation(tenant, scaffoldContext);
                        },
                        icon: Icon(Iconsax.close_circle),
                        label: Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMD),
                        ),
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingMD),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          
                          // Show loading indicator on scaffold context
                          Loaders.infoSnackBar(
                            scaffoldContext,
                            title: 'Processing',
                            message: 'Approving tenant...',
                          );
                          
                          try {
                            await ref.read(tenantListProvider.notifier).approveTenant(tenant.email);
                            Loaders.successSnackBar(
                              scaffoldContext,
                              title: 'Tenant Approved',
                              message: '${tenant.firstName} ${tenant.lastName} is now active.',
                            );
                          } catch (e) {
                            final errorMessage = e.toString().contains('User not found') 
                                ? 'Tenant not found in the system.'
                                : e.toString().contains('not in pending status')
                                ? 'Tenant is not in pending status.'
                                : 'Failed to approve tenant. Please try again.';
                            
                            Loaders.errorSnackBar(
                              scaffoldContext,
                              title: 'Approval Failed',
                              message: errorMessage,
                            );
                          }
                        },
                        icon: Icon(Iconsax.tick_circle),
                        label: Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMD),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            color: context.colorScheme.primary,
          ),
        ),
        SizedBox(height: AppConstants.spacingSM),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: 'Montserrat',
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                fontFamily: 'Montserrat',
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(UserModel tenant, BuildContext scaffoldContext) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Application',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to reject ${tenant.fullName}\'s application? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading indicator
              Loaders.infoSnackBar(
                scaffoldContext,
                title: 'Processing',
                message: 'Rejecting application...',
              );
              
              try {
                await ref.read(tenantListProvider.notifier).updateTenantStatus(
                  tenant.email,
                  'rejected',
                  reason: 'Application rejected by administrator',
                );
                Loaders.successSnackBar(
                  scaffoldContext,
                  title: 'Application Rejected',
                  message: '${tenant.firstName} ${tenant.lastName}\'s application has been rejected.',
                );
              } catch (e) {
                final errorMessage = e.toString().contains('User not found') 
                    ? 'Tenant not found in the system.'
                    : e.toString().contains('Invalid status')
                    ? 'Invalid operation requested.'
                    : 'Failed to reject application. Please try again.';
                    
                Loaders.errorSnackBar(
                  scaffoldContext,
                  title: 'Rejection Failed',
                  message: errorMessage,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showTenantActions(UserModel tenant) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLG),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: AppConstants.spacingLG,
          right: AppConstants.spacingLG,
          top: AppConstants.spacingLG,
          bottom: MediaQuery.of(context).viewPadding.bottom + AppConstants.spacingLG,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: AppConstants.spacingLG),
                decoration: BoxDecoration(
                  color: context.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                tenant.fullName,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: AppConstants.spacingLG),
              _ActionTile(
                icon: Iconsax.profile_circle,
                title: 'View Profile',
                onTap: () {
                  Navigator.pop(context);
                  _viewTenantDetails(tenant);
                },
              ),
              _ActionTile(
                icon: Iconsax.message,
                title: 'Send Message',
                onTap: () {
                  Navigator.pop(context);
                  Loaders.infoSnackBar(
                    context,
                    title: 'Coming Soon',
                    message: 'Message feature will be available soon.',
                  );
                },
              ),
              _ActionTile(
                icon: Iconsax.receipt,
                title: 'Generate Bill',
                onTap: () {
                  Navigator.pop(context);
                  Loaders.infoSnackBar(
                    context,
                    title: 'Coming Soon',
                    message: 'Generate bill feature will be available soon.',
                  );
                },
              ),
              _ActionTile(
                icon: Iconsax.edit,
                title: 'Edit Details',
                onTap: () {
                  Navigator.pop(context);
                  Loaders.infoSnackBar(
                    context,
                    title: 'Coming Soon',
                    message: 'Edit details feature will be available soon.',
                  );
                },
              ),
              if (tenant.status == 'active')
                _ActionTile(
                  icon: Iconsax.pause,
                  title: 'Suspend Account',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showSuspendConfirmation(tenant);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? context.colorScheme.onSurface;
    
    return ListTile(
      leading: Icon(
        icon,
        color: tileColor,
      ),
      title: Text(
        title,
        style: context.textTheme.bodyMedium?.copyWith(
          fontFamily: 'Montserrat',
          color: tileColor,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: context.radiusMD,
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
  }) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSM,
        vertical: AppConstants.spacingXS * 0.75,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.12),
        borderRadius: context.radiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(width: AppConstants.spacingXS),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              color: textColor ?? colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuspendConfirmation(UserModel tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Suspend Account',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to suspend ${tenant.fullName}\'s account? They will lose access to the app until reactivated.',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Loaders.successSnackBar(
                context,
                title: 'Account Suspended',
                message: '${tenant.fullName}\'s account has been suspended.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Suspend'),
          ),
        ],
      ),
    );
  }
}