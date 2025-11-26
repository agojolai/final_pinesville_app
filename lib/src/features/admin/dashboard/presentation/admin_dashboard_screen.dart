import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../../../../core/snackbars/loaders.dart';
import '../../auth/data/admin_repository.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onMenuTap,
  });

  final VoidCallback onMenuTap;

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> 
    with TickerProviderStateMixin {
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
          'Admin Dashboard',
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
            onPressed: () => _showNotifications(),
            icon: Stack(
              children: [
                Icon(
                  Iconsax.notification,
                  color: context.colorScheme.onSurface,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: context.colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
   
          SizedBox(width: AppConstants.spacingSM),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: ResponsiveLayoutWrapper(
            centerContent: true,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeSection(),
                  SizedBox(height: AppConstants.spacingLG),
                  _QuickStatsSection(),
                  SizedBox(height: AppConstants.spacingLG),
                  _RecentActivitySection(),
                  SizedBox(height: AppConstants.spacingLG),
                  _QuickActionsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _WelcomeSection() {
    // Watch the current admin's profile
    final adminAsync = ref.watch(currentAdminProvider);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary,
            context.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: context.radiusMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adminAsync.when(
            data: (admin) => Text(
              admin != null 
                  ? 'Welcome back, ${admin.profile.firstName.isNotEmpty ? admin.profile.firstName : admin.email}' 
                  : 'Welcome back, Admin',
              style: context.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            loading: () => Text(
              'Welcome back, Admin',
              style: context.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            error: (_, __) => Text(
              'Welcome back, Admin',
              style: context.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            'Here\'s what\'s happening in your property today',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(height: AppConstants.spacingMD),
          Row(
            children: [
              Icon(
                Iconsax.calendar,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: AppConstants.spacingXS),
              Text(
                'Sunday, September 29, 2025',
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _QuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Overview',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingMD),
        ResponsiveGridView(
          mobileColumns: 2,
          customAspectRatio: context.isTablet || context.isDesktop ? 1.5 : 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              title: 'Total Units',
              value: '150',
              subtitle: 'Available: 12',
              icon: Iconsax.home,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Occupied',
              value: '138',
              subtitle: '92% occupancy',
              icon: Iconsax.people,
              color: Colors.green,
            ),
            _StatCard(
              title: 'Monthly Revenue',
              value: '₱2.1M',
              subtitle: '+5.2% vs last month',
              icon: Iconsax.money_send,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'Pending Issues',
              value: '8',
              subtitle: '3 urgent',
              icon: Iconsax.warning_2,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _StatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxHeight < 160;
        final double basePadding = isCompact ? AppConstants.spacingSM : AppConstants.spacingMD;
        final double headerSpacing = isCompact ? AppConstants.spacingSM : AppConstants.spacingMD;
        final double secondarySpacing = isCompact ? AppConstants.spacingXS * 0.75 : AppConstants.spacingXS;
        final double iconPadding = isCompact ? AppConstants.spacingXS : AppConstants.spacingSM;
        final double iconSize = isCompact ? 18 : 20;
        final textTheme = context.textTheme;

        final valueStyle = (isCompact ? textTheme.headlineSmall : textTheme.headlineMedium)?.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
          color: context.colorScheme.onSurface,
        );

        final titleStyle = (isCompact ? textTheme.bodyMedium : textTheme.titleSmall)?.copyWith(
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat',
          color: context.colorScheme.onSurface,
        );

        final subtitleStyle = textTheme.bodySmall?.copyWith(
          fontFamily: 'Montserrat',
          color: context.colorScheme.onSurface.withValues(alpha: 0.7),
        );

        return Container(
          padding: EdgeInsets.all(basePadding),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: context.radiusMD,
            border: Border.all(
              color: context.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: context.radiusSM,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: iconSize,
                  ),
                ),
              ),
              SizedBox(height: headerSpacing),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    ),
                    SizedBox(height: secondarySpacing),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    SizedBox(height: secondarySpacing),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _RecentActivitySection() {
    final isTabletOrDesktop = context.isTablet || context.isDesktop;
    
    final activityList = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) => SizedBox(height: AppConstants.spacingSM),
      itemBuilder: (context, index) => _ActivityItem(
        title: _getActivityTitle(index),
        subtitle: _getActivitySubtitle(index),
        time: _getActivityTime(index),
        icon: _getActivityIcon(index),
        color: _getActivityColor(index),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingMD),
        if (isTabletOrDesktop)
          // Two column layout for tablets/desktop
          AdaptiveTwoPanelLayout(
            primaryPanel: Column(
              children: List.generate(3, (index) => Padding(
                padding: EdgeInsets.only(bottom: index < 2 ? AppConstants.spacingSM : 0),
                child: _ActivityItem(
                  title: _getActivityTitle(index),
                  subtitle: _getActivitySubtitle(index),
                  time: _getActivityTime(index),
                  icon: _getActivityIcon(index),
                  color: _getActivityColor(index),
                ),
              )),
            ),
            secondaryPanel: Column(
              children: List.generate(2, (index) {
                final actualIndex = index + 3;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < 1 ? AppConstants.spacingSM : 0),
                  child: _ActivityItem(
                    title: _getActivityTitle(actualIndex),
                    subtitle: _getActivitySubtitle(actualIndex),
                    time: _getActivityTime(actualIndex),
                    icon: _getActivityIcon(actualIndex),
                    color: _getActivityColor(actualIndex),
                  ),
                );
              }),
            ),
          )
        else
          // Single column layout for mobile
          activityList,
      ],
    );
  }

  String _getActivityTitle(int index) {
    const titles = [
      'New tenant registered',
      'Maintenance request submitted',
      'Payment received',
      'Lease renewal signed',
      'Unit inspection completed',
    ];
    return titles[index % titles.length];
  }

  String _getActivitySubtitle(int index) {
    const subtitles = [
      'John Doe - Unit 204-B',
      'Sarah Miller - Unit 105-A (AC repair)',
      'Michael Chen - Unit 301-C (₱15,000)',
      'Emma Wilson - Unit 202-A (1 year)',
      'Unit 150-B - All systems good',
    ];
    return subtitles[index % subtitles.length];
  }

  String _getActivityTime(int index) {
    const times = [
      '2 hours ago',
      '4 hours ago',
      '6 hours ago',
      '8 hours ago',
      '1 day ago',
    ];
    return times[index % times.length];
  }

  IconData _getActivityIcon(int index) {
    const icons = [
      Iconsax.profile_add,
      Iconsax.setting_4,
      Iconsax.money_recive,
      Iconsax.document_text,
      Iconsax.tick_circle,
    ];
    return icons[index % icons.length];
  }

  Color _getActivityColor(int index) {
    const colors = [
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  Widget _ActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusMD,
        border: Border.all(
          color: context.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacingSM),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: context.radiusSM,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: AppConstants.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(height: AppConstants.spacingXS),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Montserrat',
                    color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: context.textTheme.bodySmall?.copyWith(
              fontFamily: 'Montserrat',
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _QuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: AppConstants.spacingMD),
        ResponsiveGridView(
          mobileColumns: 2,
          customAspectRatio: context.isTablet || context.isDesktop ? 1.4 : 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _QuickActionCard(
              title: 'Add Tenant',
              icon: Iconsax.profile_add,
              color: Colors.blue,
              onTap: () => _navigateToAddTenant(),
            ),
            _QuickActionCard(
              title: 'Create Bill',
              icon: Iconsax.receipt_add,
              color: Colors.green,
              onTap: () => _navigateToCreateBill(),
            ),
            _QuickActionCard(
              title: 'Send Notice',
              icon: Iconsax.message_add,
              color: Colors.orange,
              onTap: () => _navigateToSendNotice(),
            ),
            _QuickActionCard(
              title: 'View Reports',
              icon: Iconsax.chart_square,
              color: Colors.purple,
              onTap: () => _navigateToReports(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _QuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacingMD),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: context.radiusMD,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              SizedBox(height: AppConstants.spacingMD),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showNotifications() {
    // TODO: Implement notifications
    Loaders.infoSnackBar(
      context,
      title: 'Coming Soon',
      message: 'Notifications feature will be available in a future update.',
    );
  }

  void _navigateToAddTenant() {
    // TODO: Navigate to add tenant screen
    Loaders.infoSnackBar(
      context,
      title: 'Coming Soon',
      message: 'Add tenant feature will be available soon.',
    );
  }

  void _navigateToCreateBill() {
    // TODO: Navigate to create bill screen
    Loaders.infoSnackBar(
      context,
      title: 'Coming Soon',
      message: 'Create bill feature will be available soon.',
    );
  }

  void _navigateToSendNotice() {
    // TODO: Navigate to send notice screen
    Loaders.infoSnackBar(
      context,
      title: 'Coming Soon',
      message: 'Send notice feature will be available soon.',
    );
  }

  void _navigateToReports() {
    // TODO: Navigate to reports screen
    Loaders.infoSnackBar(
      context,
      title: 'Coming Soon',
      message: 'Reports feature will be available soon.',
    );
  }
}