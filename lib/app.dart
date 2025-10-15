import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/theme/app_theme.dart';
import 'src/features/auth/presentation/login_screen.dart';
import 'src/common/widgets/role_based_navigation.dart';
import 'src/features/auth/providers/auth_provider.dart';
import 'src/features/onboarding/presentation/onboarding_screen.dart';
import 'src/features/onboarding/data/onboarding_repository.dart';
import 'src/core/utils/app_logger.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
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
                  // If user is logged in, go to role-based navigation
                  if (user != null) {
                    AppLogger.debug('🏠 APP NAVIGATION: User authenticated, showing RoleBasedNavigation');
                    AppLogger.debug('   ├─ UID: ${user.uid}');
                    AppLogger.debug('   └─ Email: ${user.email}');
                    // Use key based on user ID to force widget recreation on user change
                    return RoleBasedNavigation(key: ValueKey(user.uid));
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
}