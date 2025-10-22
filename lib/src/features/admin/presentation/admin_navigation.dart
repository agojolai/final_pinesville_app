import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import 'admin_dashboard_screen.dart';
import 'tenant_management_screen.dart';
import 'billing_management_screen.dart';
import 'admin_reports_management_screen.dart';
import 'announcements_management_screen.dart';
import '../../data_import/presentation/import_data_screen.dart';
import '../../../features/auth/presentation/login_screen.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/snackbars/loaders.dart';
import '../../../core/utils/app_logger.dart';

class _DrawerEntry {
  const _DrawerEntry({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() {
    AppLogger.debug('🏗️ AdminNavigation: Creating new state instance');
    return _AdminNavigationState();
  }
}

class _AdminNavigationState extends State<AdminNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  late final List<Widget> _screens;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Iconsax.home),
      selectedIcon: Icon(Iconsax.home5),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Iconsax.people),
      selectedIcon: Icon(Iconsax.people5),
      label: 'Tenants',
    ),
    const NavigationDestination(
      icon: Icon(Iconsax.receipt),
      selectedIcon: Icon(Iconsax.receipt_15),
      label: 'Billing',
    ),
    const NavigationDestination(
      icon: Icon(Iconsax.chart),
      selectedIcon: Icon(Iconsax.chart_25),
      label: 'Reports',
    ),
    const NavigationDestination(
      icon: Icon(Iconsax.message_text),
      selectedIcon: Icon(Iconsax.message_text_15),
      label: 'Announcements',
    ),
  ];

  final List<_DrawerEntry> _upcomingEntries = const [
    _DrawerEntry(label: 'Units', icon: Icons.apartment_outlined),
    _DrawerEntry(label: 'Chats', icon: Icons.chat_bubble_outline),
    _DrawerEntry(label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
  AppLogger.debug('🚀 AdminNavigation: initState called - Admin UI is initializing');
    _screens = [
  AdminDashboardScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
  TenantManagementScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
  BillingManagementScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
  AdminReportsManagementScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
  AnnouncementsManagementScreen(onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
    ];
  }

  void _onNavBarTap(int index) {
    if (index != _currentIndex) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        elevation: AppConstants.elevationLevel4,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppConstants.spacingMD,
                  AppConstants.spacingLG,
                  AppConstants.spacingMD,
                  AppConstants.spacingSM,
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.building,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                    SizedBox(width: AppConstants.spacingSM),
                    Text(
                      'Admin Menu',
                      style: textTheme.titleMedium?.copyWith(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMD,
                          vertical: AppConstants.spacingSM,
                        ),
                        children: [
                          ..._buildPrimaryNavigationTiles(colorScheme, textTheme),
                          SizedBox(height: AppConstants.spacingLG),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
                            child: Text(
                              'UTILITIES',
                              style: textTheme.labelSmall?.copyWith(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: AppConstants.spacingSM),
                          _buildImportDataTile(colorScheme, textTheme),
                          SizedBox(height: AppConstants.spacingLG),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
                            child: Text(
                              'COMING SOON',
                              style: textTheme.labelSmall?.copyWith(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: AppConstants.spacingSM),
                          ..._buildUpcomingTiles(colorScheme, textTheme),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppConstants.spacingMD,
                        AppConstants.spacingSM,
                        AppConstants.spacingMD,
                        AppConstants.spacingSM,
                      ),
                      child: _buildLogoutTile(colorScheme, textTheme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }

  List<Widget> _buildPrimaryNavigationTiles(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final tiles = <Widget>[];

    for (int index = 0; index < _destinations.length; index++) {
      if (index > 0) {
        tiles.add(SizedBox(height: AppConstants.spacingXS));
      }
      tiles.add(_buildDestinationTile(index, colorScheme, textTheme));
    }

    return tiles;
  }

  Widget _buildDestinationTile(
    int index,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final destination = _destinations[index];
    final bool isSelected = index == _currentIndex;
    final Color iconColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.7);

    return ListTile(
      dense: true,
      leading: IconTheme(
        data: IconThemeData(
          color: iconColor,
          size: 24,
        ),
        child: isSelected && destination.selectedIcon != null
            ? destination.selectedIcon!
            : destination.icon,
      ),
      title: Text(
        destination.label,
        style: textTheme.bodyLarge?.copyWith(
          fontFamily: 'Montserrat',
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
      onTap: () {
        Navigator.of(context).pop();
        _onNavBarTap(index);
      },
    );
  }

  List<Widget> _buildUpcomingTiles(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final tiles = <Widget>[];

    for (int index = 0; index < _upcomingEntries.length; index++) {
      if (index > 0) {
        tiles.add(SizedBox(height: AppConstants.spacingXS));
      }
      tiles.add(_buildComingSoonTile(_upcomingEntries[index], colorScheme, textTheme));
    }

    return tiles;
  }

  Widget _buildImportDataTile(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final Color iconColor = colorScheme.primary;
    final Color labelColor = colorScheme.onSurface;

    return ListTile(
      dense: true,
      leading: Icon(
        Iconsax.import,
        color: iconColor,
        size: 24,
      ),
      title: Text(
        'Import Historical Data',
        style: textTheme.bodyLarge?.copyWith(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
          color: labelColor,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImportDataScreen(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComingSoonTile(
    _DrawerEntry entry,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final Color iconColor = colorScheme.onSurface.withValues(alpha: 0.7);
    final Color labelColor = colorScheme.onSurface.withValues(alpha: 0.8);

    return ListTile(
      dense: true,
      leading: Icon(
        entry.icon,
        color: iconColor,
        size: 24,
      ),
      title: Text(
        entry.label,
        style: textTheme.bodyLarge?.copyWith(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
          color: labelColor,
        ),
      ),
      trailing: Chip(
        label: Text(
          'Soon',
          style: textTheme.labelSmall?.copyWith(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        side: BorderSide.none,
        backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSM,
          vertical: AppConstants.spacingXS / 2,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('${entry.label} is coming soon.'),
              duration: AppConstants.durationNormal,
            ),
          );
      },
    );
  }

  Widget _buildLogoutTile(ColorScheme colorScheme, TextTheme textTheme) {
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.logout,
        color: colorScheme.error,
        size: 24,
      ),
      title: Text(
        'Log out',
        style: textTheme.bodyLarge?.copyWith(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
          color: colorScheme.error,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      onTap: _handleLogout,
    );
  }

  void _handleLogout() {
    Navigator.of(context).pop();
 HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Real logout logic
                await AuthRepository.instance.logout();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                  Loaders.successSnackBar(
                    context,
                    title: 'Logged out successfully',
                    message: 'You have been logged out.',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Loaders.errorSnackBar(
                    context,
                    title: 'Logout Failed',
                    message: 'Please try again.',
                  );
                }
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}