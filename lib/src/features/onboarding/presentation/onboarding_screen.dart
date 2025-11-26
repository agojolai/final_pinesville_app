import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../data/onboarding_repository.dart';
import '../../auth/presentation/login_screen.dart';

/// Onboarding screen data model
class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  final OnboardingRepository _onboardingRepository = OnboardingRepository();

  static const List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Iconsax.home_2,
      title: 'Welcome to Pinesville',
      description: 'Your digital home management solution. Manage your residence with ease and stay connected with your community.',
    ),
    OnboardingPage(
      icon: Iconsax.receipt,
      title: 'Easy Billing & Payments',
      description: 'View your monthly bills, make secure payments, and track your transaction history all in one place.',
    ),
    OnboardingPage(
      icon: Iconsax.message,
      title: 'Direct Admin Communication',
      description: 'Chat directly with building administrators for quick support, maintenance requests, and important updates.',
    ),
    OnboardingPage(
      icon: Iconsax.notification,
      title: 'Stay Updated',
      description: 'Receive important announcements, community news, and building notifications instantly.',
    ),
    OnboardingPage(
      icon: Iconsax.user,
      title: 'Manage Your Profile',
      description: 'Manage and keep your account information updated.',
    ),
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

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.durationNormal,
        curve: AppConstants.curveDefault,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    await _onboardingRepository.markOnboardingCompleted();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Skip Button
              _SkipButton(onTap: _skipOnboarding),
              
              // Page Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPageContent(page: _pages[index]);
                  },
                ),
              ),
              
              // Bottom Navigation
              _BottomNavigation(
                currentPage: _currentPage,
                totalPages: _pages.length,
                onNext: _nextPage,
                pageController: _pageController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: context.colorScheme.onSurface.withValues(alpha: 0.6),
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMD,
                vertical: AppConstants.spacingSM,
              ),
            ),
            child: Text(
              'Skip',
              style: context.textTheme.titleMedium?.copyWith(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageContent extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.paddingHorizontal(AppConstants.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: context.radiusXL,
              border: Border.all(
                color: context.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.iconColor ?? context.colorScheme.primary,
            ),
          ),
          
          SizedBox(height: AppConstants.spacingXL),
          
          // Title
          Text(
            page.title,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: context.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppConstants.spacingLG),
          
          // Description
          Text(
            page.description,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              fontFamily: 'Montserrat',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppConstants.spacingXXL),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final PageController pageController;

  const _BottomNavigation({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;
    
    return Padding(
      padding: EdgeInsets.all(AppConstants.spacingXL),
      child: Column(
        children: [
          // Page Indicator
          SmoothPageIndicator(
            controller: pageController,
            count: totalPages,
            effect: ExpandingDotsEffect(
              activeDotColor: context.colorScheme.primary,
              dotColor: context.colorScheme.primary.withValues(alpha: 0.3),
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
              spacing: 8,
            ),
          ),
          
          SizedBox(height: AppConstants.spacingXL),
          
          // Next/Get Started Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: context.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  vertical: AppConstants.spacingMD,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: context.radiusLG,
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? 'Get Started' : 'Next',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      color: context.colorScheme.onPrimary,
                    ),
                  ),
                  if (!isLastPage) ...[
                    SizedBox(width: AppConstants.spacingSM),
                    Icon(
                      Iconsax.arrow_right_3,
                      size: 20,
                      color: context.colorScheme.onPrimary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}