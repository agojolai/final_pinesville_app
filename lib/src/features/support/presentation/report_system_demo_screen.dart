import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../data/repositories/report_repository.dart';

/// Development utility screen to showcase system capabilities
class ReportSystemDemoScreen extends StatefulWidget {
  const ReportSystemDemoScreen({super.key});

  @override
  State<ReportSystemDemoScreen> createState() => _ReportSystemDemoScreenState();
}

class _ReportSystemDemoScreenState extends State<ReportSystemDemoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reports System Demo',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              title: 'System Overview',
              content: 'Complete reports & tickets system with Firestore integration, '
                      'file upload support, real-time updates, and feedback management.',
              icon: Iconsax.info_circle,
              color: Colors.blue,
            ),
            SizedBox(height: AppConstants.spacingLG),
            _InfoCard(
              title: 'Key Features',
              content: '• Real-time report tracking\n'
                      '• Photo/video attachments\n'
                      '• Status updates & messaging\n'
                      '• Tenant feedback system\n'
                      '• Admin management tools',
              icon: Iconsax.tick_square,
              color: Colors.green,
            ),
            SizedBox(height: AppConstants.spacingLG),
            _InfoCard(
              title: 'Data Models',
              content: 'ReportModel, TenantInfo, ReportUpdate, ReportFeedback\n'
                      'All with JSON serialization for Firestore compatibility.',
              icon: Iconsax.code,
              color: Colors.purple,
            ),
            SizedBox(height: AppConstants.spacingLG),
            _InfoCard(
              title: 'Repository Pattern',
              content: 'ReportRepository handles all CRUD operations, file uploads, '
                      'and provides both async and stream-based data access.',
              icon: Iconsax.database,
              color: Colors.orange,
            ),
            SizedBox(height: AppConstants.spacingXL),
            Center(
              child: Column(
                children: [
                  Text(
                    'Implementation Complete ✅',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  SizedBox(height: AppConstants.spacingSM),
                  Text(
                    'See REPORTS_IMPLEMENTATION.md for full documentation',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _InfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: AppConstants.spacingSM),
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            content,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.8),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}