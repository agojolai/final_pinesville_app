import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../theme/app_constants.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/app_theme.dart'; // Import for CustomColors extension

/// Snackbar loader utility class for consistent messaging across the app
/// Uses native Flutter ScaffoldMessenger instead of GetX for better integration
class Loaders {
  Loaders._(); // Private constructor to prevent instantiation

  /// Hide currently displayed snackbar
  static void hideSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Show a custom toast-style snackbar
  static void customToast(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        content: Container(
          padding: EdgeInsets.all(AppConstants.spacingSM),
          margin: EdgeInsets.symmetric(horizontal: AppConstants.spacingXL),
          decoration: BoxDecoration(
            borderRadius: context.radiusXL,
            color: context.colorScheme.surface.withValues(alpha:0.9),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withValues(alpha:0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              message, 
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.onSurface,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show a success snackbar with green styling
  static void successSnackBar(
    BuildContext context, {
    required String title,
    String message = '',
    int duration = 3,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Iconsax.tick_circle,
              color: Colors.white, // White text on success background
              size: 20,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: Colors.white, // White text on success background
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Text(
                      message,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha:0.9), // White text on success background
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: context.colorScheme.success, // Using theme success color
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: duration),
        margin: EdgeInsets.all(AppConstants.spacingSM),
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusLG,
        ),
      ),
    );
  }

  /// Show a warning snackbar with amber styling
  static void warningSnackBar(
    BuildContext context, {
    required String title,
    String message = '',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Iconsax.warning_2,
              color: Colors.black, // Black text on warning (amber) background for better contrast
              size: 20,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: Colors.black, // Black text on warning (amber) background
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Text(
                      message,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.black.withValues(alpha:0.8), // Black text on warning (amber) background
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: context.colorScheme.warning, // Using theme warning color
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(AppConstants.spacingSM),
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusLG,
        ),
      ),
    );
  }

  /// Show an error snackbar with red styling
  static void errorSnackBar(
    BuildContext context, {
    required String title,
    String message = '',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Iconsax.warning_2,
              color: context.colorScheme.onError, // Using theme color for error background
              size: 20,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colorScheme.onError, // Using theme color
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Text(
                      message,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onError.withValues(alpha:0.9), // Using theme color
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: context.colorScheme.error, // Using theme error color
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(AppConstants.spacingSM),
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusLG,
        ),
      ),
    );
  }

  /// Show an info snackbar with blue styling
  static void infoSnackBar(
    BuildContext context, {
    required String title,
    String message = '',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Iconsax.info_circle,
              color: Colors.white, // White text on info (blue) background
              size: 20,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: Colors.white, // White text on info (blue) background
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Text(
                      message,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha:0.9), // White text on info (blue) background
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: context.colorScheme.info, // Using theme info color
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(AppConstants.spacingSM),
        shape: RoundedRectangleBorder(
          borderRadius: context.radiusLG,
        ),
      ),
    );
  }
}
