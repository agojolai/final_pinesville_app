import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/theme/app_theme.dart';
import 'src/features/auth/presentation/login_screen.dart';
import 'src/common/widgets/main_navigation.dart';
import 'src/features/auth/providers/auth_provider.dart';
import 'src/features/onboarding/presentation/onboarding_screen.dart';
import 'src/features/onboarding/data/onboarding_repository.dart';

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
                  // If user is logged in, go to main navigation
                  if (user != null) {
                    return const MainNavigation();
                  }
                  
                  // If not logged in, check onboarding status asynchronously
                  return FutureBuilder<bool>(
                    future: onboardingRepository.getOnboardingStatus(),
                    builder: (context, onboardingSnapshot) {
                      if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Checking onboarding status...'),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final isOnboardingCompleted = onboardingSnapshot.data ?? false;
                      
                      if (!isOnboardingCompleted) {
                        return const OnboardingScreen();
                      }
                      
                      // Show login screen if onboarding is completed but user not logged in
                      return const LoginScreen();
                    },
                  );
                },
                loading: () => const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) {
                  // On error, use fallback async check
                  return FutureBuilder<bool>(
                    future: onboardingRepository.getOnboardingStatus(),
                    builder: (context, onboardingSnapshot) {
                      if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final isOnboardingCompleted = onboardingSnapshot.data ?? false;
                      
                      if (!isOnboardingCompleted) {
                        return const OnboardingScreen();
                      }
                      
                      return const LoginScreen();
                    },
                  );
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
      print('Firebase initialization: $e');
    }
  }
}