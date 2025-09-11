/// 🎨 App Design System Constants
/// 
/// This file contains all the design tokens used throughout your Flutter app.
/// Generated with Flutter Theme Generator for consistency and maintainability.
/// 
/// Usage examples:
/// - Spacing: SizedBox(height: AppConstants.spacingMD)
/// - Border Radius: BorderRadius.circular(AppConstants.radiusLG)
/// - Animation: AnimationController(duration: AppConstants.durationNormal)

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════
  // 📏 SPACING SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════
  // Consistent spacing creates visual rhythm and hierarchy
  
  /// Extra small spacing (4px) - For tight layouts, borders
  static double get spacingXS => 4.w;
  
  /// Small spacing (8px) - For compact elements, form fields
  static double get spacingSM => 8.w;
  
  /// Medium spacing (16px) - For cards, buttons, general content
  static double get spacingMD => 16.w;
  
  /// Large spacing (24px) - For sections, major components
  static double get spacingLG => 24.w;
  
  /// Extra large spacing (32px) - For screen sections, headers
  static double get spacingXL => 32.w;
  
  /// Double extra large spacing (48px) - For major layout breaks
  static double get spacingXXL => 48.w;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔄 BORDER RADIUS SYSTEM  
  // ═══════════════════════════════════════════════════════════════════════════
  // Consistent corner rounding for modern, cohesive design
  
  /// Extra small radius (4px) - For subtle rounding, checkboxes
  static double get radiusXS => 4.w;
  
  /// Small radius (8px) - For buttons, chips, form fields
  static double get radiusSM => 8.w;
  
  /// Medium radius (12px) - For cards, containers
  static double get radiusMD => 12.w;
  
  /// Large radius (16px) - For prominent elements, dialogs
  static double get radiusLG => 16.w;
  
  /// Extra large radius (24px) - For hero elements, bottom sheets
  static double get radiusXL => 24.w;
  
  /// Full radius (9999px) - For circular elements, pills
  static double get radiusFull => 9999.w;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔲 BORDER WIDTH SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════
  // Consistent border widths for outlines and dividers
  
  /// Thin border (1px) - For subtle outlines, dividers
  static double get borderWidthThin => 1.0.w;
  
  /// Medium border (2px) - For form fields, buttons
  static double get borderWidthMedium => 2.0.w;
  
  /// Thick border (4px) - For emphasis, focus states
  static double get borderWidthThick => 4.0.w;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏔️ ELEVATION SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════
  // Material Design elevation levels for depth hierarchy
  
  /// No elevation (0dp) - For flat elements on background
  static const double elevationLevel0 = 0;
  
  /// Level 1 elevation (1dp) - For cards, buttons at rest
  static const double elevationLevel1 = 1;
  
  /// Level 2 elevation (3dp) - For raised buttons, switches
  static const double elevationLevel2 = 3;
  
  /// Level 3 elevation (6dp) - For floating action buttons
  static const double elevationLevel3 = 6;
  
  /// Level 4 elevation (8dp) - For navigation drawer, modal bottom sheets
  static const double elevationLevel4 = 8;
  
  /// Level 5 elevation (12dp) - For app bar, dialogs
  static const double elevationLevel5 = 12;

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚡ ANIMATION SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════
  // Consistent timing for smooth, professional animations
  
  /// Fast animation (150ms) - For micro-interactions, hover states
  static const Duration durationFast = Duration(milliseconds: 150);
  
  /// Normal animation (300ms) - For standard transitions, page changes
  static const Duration durationNormal = Duration(milliseconds: 300);
  
  /// Slow animation (500ms) - For complex animations, loading states
  static const Duration durationSlow = Duration(milliseconds: 500);

  // ═══════════════════════════════════════════════════════════════════════════
  // 📈 ANIMATION CURVES
  // ═══════════════════════════════════════════════════════════════════════════
  // Predefined curves for natural motion
  
  /// Default curve - Standard ease in/out for most animations
  static const Curve curveDefault = Curves.easeInOut;
  
  /// Emphasized curve - More dramatic easing for important transitions
  static const Curve curveEmphasized = Curves.easeInOutCubicEmphasized;
  
  /// Bounce curve - Playful bouncing effect for delightful interactions
  static const Curve curveBounce = Curves.bounceOut;
  
  /// Linear curve - Constant speed for loading indicators
  static const Curve curveLinear = Curves.linear;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 COMMON MEASUREMENTS
  // ═══════════════════════════════════════════════════════════════════════════
  // Frequently used measurements for consistent implementation
  
  /// Standard button height (48px) - Meets accessibility guidelines
  static double get buttonHeight => 48.h;
  
  /// Large button height (56px) - For prominent actions
  static double get buttonHeightLarge => 56.h;
  
  /// Small button height (40px) - For compact layouts
  static double get buttonHeightSmall => 40.h;
  
  /// Text field height (56px) - Standard Material Design height
  static double get textFieldHeight => 56.h;
  
  /// App bar height (56px) - Standard Material Design app bar
  static double get appBarHeight => 56.h;
  
  /// Tab bar height (48px) - Standard Material Design tab bar
  static double get tabBarHeight => 48.h;
  
  /// Bottom navigation height (80px) - With padding and content
  static double get bottomNavHeight => 80.h;
  
  /// FAB size (56px) - Standard floating action button
  static double get fabSize => 56.w;
  
  /// Large FAB size (64px) - Extended floating action button
  static double get fabSizeLarge => 64.w;
  
  /// Avatar size (40px) - Standard user avatar
  static double get avatarSize => 40.w;
  
  /// Large avatar size (64px) - Profile or prominent display
  static double get avatarSizeLarge => 64.w;

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 RESPONSIVE BREAKPOINTS
  // ═══════════════════════════════════════════════════════════════════════════
  // Screen size breakpoints for responsive design
  
  /// Mobile breakpoint (600px) - Phone screens
  static double get breakpointMobile => 600.w;
  
  /// Tablet breakpoint (900px) - Tablet screens
  static double get breakpointTablet => 900.w;
  
  /// Desktop breakpoint (1200px) - Desktop screens
  static double get breakpointDesktop => 1200.w;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔤 TYPOGRAPHY SCALE
  // ═══════════════════════════════════════════════════════════════════════════
  // Font sizes following Material Design 3 type scale
  
  /// Display Large (57px) - Hero text, major headlines
  static double get fontSizeDisplayLarge => 57.sp;
  
  /// Display Medium (45px) - Large headers
  static double get fontSizeDisplayMedium => 45.sp;
  
  /// Display Small (36px) - Section headers
  static double get fontSizeDisplaySmall => 36.sp;
  
  /// Headline Large (32px) - Page titles
  static double get fontSizeHeadlineLarge => 32.sp;
  
  /// Headline Medium (28px) - Card titles
  static double get fontSizeHeadlineMedium => 28.sp;
  
  /// Headline Small (24px) - List headers
  static double get fontSizeHeadlineSmall => 24.sp;
  
  /// Title Large (22px) - App bar titles
  static double get fontSizeTitleLarge => 22.sp;
  
  /// Title Medium (16px) - Button text, tab labels
  static double get fontSizeTitleMedium => 16.sp;
  
  /// Title Small (14px) - List item titles
  static double get fontSizeTitleSmall => 14.sp;
  
  /// Body Large (16px) - Prominent body text
  static double get fontSizeBodyLarge => 16.sp;
  
  /// Body Medium (14px) - Standard body text
  static double get fontSizeBodyMedium => 14.sp;
  
  /// Body Small (12px) - Supporting text
  static double get fontSizeBodySmall => 12.sp;
  
  /// Label Large (14px) - Form labels
  static double get fontSizeLabelLarge => 14.sp;
  
  /// Label Medium (12px) - Caption text
  static double get fontSizeLabelMedium => 12.sp;
  
  /// Label Small (11px) - Small annotations
  static double get fontSizeLabelSmall => 11.sp;

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (screenWidth >= breakpointDesktop) {
      return EdgeInsets.all(spacingXXL);
    } else if (screenWidth >= breakpointTablet) {
      return EdgeInsets.all(spacingXL);
    } else {
      return EdgeInsets.all(spacingMD);
    }
  }
  
  /// Get responsive text size multiplier
  static double getTextSizeMultiplier(double screenWidth) {
    if (screenWidth >= breakpointDesktop) {
      return 1.1; // 10% larger on desktop
    } else if (screenWidth >= breakpointTablet) {
      return 1.05; // 5% larger on tablet
    } else {
      return 1.0; // Standard size on mobile
    }
  }
  
  /// Check if screen is mobile size
  static bool isMobile(double screenWidth) => screenWidth < breakpointMobile;
  
  /// Check if screen is tablet size
  static bool isTablet(double screenWidth) => 
      screenWidth >= breakpointMobile && screenWidth < breakpointDesktop;
  
  /// Check if screen is desktop size
  static bool isDesktop(double screenWidth) => screenWidth >= breakpointDesktop;
}
