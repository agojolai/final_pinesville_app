import 'package:flutter/material.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../theme/theme_extensions.dart';
import 'package:iconsax/iconsax.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Iconsax.home),
      selectedIcon: Icon(Iconsax.home5),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Iconsax.message),
      selectedIcon: Icon(Iconsax.message5),
      label: 'Chat Admin',
    ),
    const NavigationDestination(
      icon: Icon(Iconsax.user),
      selectedIcon: Icon(Iconsax.profile_circle5),
      label: 'Profile',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = context.isTablet || context.isDesktop;
    
    if (isTabletOrDesktop && context.isLandscape) {
      // Side navigation for tablets in landscape
      return Scaffold(
        body: Row(
          children: [
            // Side Navigation Rail
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: context.colorScheme.surface,
              selectedIconTheme: IconThemeData(
                color: context.colorScheme.primary,
                size: 24,
              ),
              unselectedIconTheme: IconThemeData(
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 24,
              ),
              selectedLabelTextStyle: context.textTheme.labelMedium?.copyWith(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: context.colorScheme.primary,
              ),
              unselectedLabelTextStyle: context.textTheme.labelMedium?.copyWith(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.normal,
                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              labelType: NavigationRailLabelType.all,
              minWidth: 80,
              destinations: _destinations.map((dest) => NavigationRailDestination(
                icon: dest.icon,
                selectedIcon: dest.selectedIcon ?? dest.icon,
                label: Text(dest.label),
              )).toList(),
            ),
            // Vertical divider
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
            // Main content
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      );
    } else {
      // Bottom navigation for mobile and portrait tablets
      return Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: context.colorScheme.primary,
          unselectedItemColor: context.colorScheme.onSurface.withValues(alpha: 0.6),
          selectedLabelStyle: context.textTheme.labelSmall?.copyWith(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: context.textTheme.labelSmall?.copyWith(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.normal,
          ),
          items: _destinations.map((dest) => BottomNavigationBarItem(
            icon: dest.icon,
            activeIcon: dest.selectedIcon ?? dest.icon,
            label: dest.label,
          )).toList(),
        ),
      );
    }
  }
}
