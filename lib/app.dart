import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:upgrader/upgrader.dart';
import 'src/theme/app_theme.dart';
import 'src/features/auth/presentation/login_screen.dart';
import 'src/features/auth/providers/auth_provider.dart';
import 'src/features/onboarding/presentation/onboarding_screen.dart';
import 'src/features/onboarding/data/onboarding_repository.dart';
import 'src/core/utils/app_logger.dart';
import 'src/common/widgets/main_navigation.dart';
import 'src/features/admin/navigation/presentation/admin_navigation.dart';
import 'src/features/app_update/data/app_update_service.dart';
import 'src/features/app_update/data/apk_download_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Global navigator key for navigation from anywhere in the app
/// Used for FCM notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends ConsumerWidget {
  const App({super.key});
  
  /// Handle APK download when user taps UPDATE NOW
  static void _handleUpdate() async {
    try {
      AppLogger.info('User tapped UPDATE NOW - starting APK download');
      final apkUrl = await AppUpdateService.getApkDownloadUrl();
      
      if (apkUrl != null && apkUrl.isNotEmpty) {
        AppLogger.info('APK URL retrieved: $apkUrl');
        await ApkDownloadService.downloadAndInstall(apkUrl);
      } else {
        AppLogger.error('Failed to retrieve APK download URL');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error handling update: $e', stackTrace);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightMediumContrast,      // Light mode theme
      darkTheme: AppTheme.darkMediumContrast,   // Dark mode theme
      themeMode: ThemeMode.system,  
      home: FutureBuilder(
        future: _ensureFirebaseInitialized(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Firebase initialization failed: ${snapshot.error}'),
                  ],
                ),
              ),
            );
          }
          
          // Check onboarding and authentication status
          return Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider);
              final onboardingRepository = OnboardingRepository();
              
              return currentUser.when(
                data: (user) {
                  // If user is logged in, determine if admin or tenant
                  if (user != null) {
                    AppLogger.debug('🏠 APP NAVIGATION: User authenticated');
                    AppLogger.debug('   ├─ UID: ${user.uid}');
                    AppLogger.debug('   └─ Email: ${user.email}');
                    
                    // Check if user is in admin collection or Users collection
                    return FutureBuilder<String>(
                      future: _determineUserRole(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(fontFamily: 'Montserrat'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        if (snapshot.hasError || !snapshot.hasData) {
                          // On error, default to login screen
                          AppLogger.error('Error determining user role: ${snapshot.error}');
                          return const LoginScreen();
                        }
                        
                        final role = snapshot.data!;
                        AppLogger.debug('   🎯 User role determined: $role');
                        
                        // Get upgrader instance (same for all users)
                        final upgrader = AppUpdateService.getUpgrader();
                        
                        if (role == 'admin') {
                          return UpgradeAlert(
                            upgrader: upgrader,
                            onUpdate: () {
                              _handleUpdate();
                              return true;
                            },
                            child: AdminNavigation(key: ValueKey('admin_${user.uid}')),
                          );
                        } else {
                          return UpgradeAlert(
                            upgrader: upgrader,
                            onUpdate: () {
                              _handleUpdate();
                              return true;
                            },
                            child: MainNavigation(key: ValueKey('tenant_${user.uid}')),
                          );
                        }
                      },
                    );
                  }
                  
                  AppLogger.debug('🏠 APP NAVIGATION: No user authenticated, showing login/onboarding');
                  
                  // If not logged in, check onboarding status
                  if (!onboardingRepository.isOnboardingCompleted) {
                    return const OnboardingScreen();
                  }
                  
                  // Show login screen if onboarding is completed but user not logged in
                  return const LoginScreen();
                },
                loading: () => const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) {
                  // On error, check onboarding status
                  if (!onboardingRepository.isOnboardingCompleted) {
                    return const OnboardingScreen();
                  }
                  return const LoginScreen();
                },
              );
            },
          );
        },
      ),
    );
  }
  
  Future<void> _ensureFirebaseInitialized() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Firebase might already be initialized
      AppLogger.debug('Firebase initialization: $e');
    }
  }
  
  /// Determine if the authenticated user is an admin or tenant
  /// by checking which collection they belong to
  Future<String> _determineUserRole(String uid) async {
    try {
      // First check if user exists in admin collection
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        return 'admin';
      }
      
      // If not in admin, check Users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        return 'tenant';
      }
      
      // If not found in either, throw error
      throw Exception('User not found in admin or Users collection');
    } catch (e) {
      AppLogger.error('Error determining user role: $e');
      rethrow;
    }
  }
}