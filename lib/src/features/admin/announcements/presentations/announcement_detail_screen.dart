import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

import '../data/models/announcement_model.dart';
import '../providers/announcements_providers.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../../../../core/snackbars/loaders.dart';
import '../../../../core/utils/app_logger.dart';

class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final AnnouncementModel announcement;
  final bool isArchived;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
    this.isArchived = false,
  });

  @override
  ConsumerState<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends ConsumerState<AnnouncementDetailScreen> {
  late AnnouncementModel _announcement;

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
    AppLogger.info('Viewing announcement: ${_announcement.id}');
  }

  String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: context.colorScheme.onSurface),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Announcement Details',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          if (!widget.isArchived)
            IconButton(
              icon: Icon(Iconsax.edit, color: context.colorScheme.primary),
              tooltip: 'Edit',
              onPressed: _editAnnouncement,
            ),
          if (!widget.isArchived)
            IconButton(
              icon: Icon(Iconsax.archive_add, color: context.colorScheme.tertiary),
              tooltip: 'Archive',
              onPressed: _confirmArchive,
            ),
          IconButton(
            icon: Icon(Iconsax.trash, color: context.colorScheme.error),
            tooltip: 'Delete',
            onPressed: _confirmDelete,
          ),
          SizedBox(width: AppConstants.spacingSM),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              _announcement.title,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),

            SizedBox(height: AppConstants.spacingSM),

            // Timestamp
            Row(
              children: [
                Icon(
                  Iconsax.clock,
                  size: 16,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppConstants.spacingXS),
                Text(
                  '${timeAgo(_announcement.timestamp)}  ${DateFormat('MMM d, y  h:mm a').format(_announcement.timestamp)}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacingMD),

            Divider(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),

            SizedBox(height: AppConstants.spacingLG),

            // Recipients
            Container(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: context.radiusSM,
                border: Border.all(
                  color: context.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.people,
                    size: 20,
                    color: context.colorScheme.primary,
                  ),
                  SizedBox(width: AppConstants.spacingSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recipients',
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                            color: context.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: AppConstants.spacingXS),
                        Text(
                          _announcement.recipients.isEmpty
                              ? 'No recipients'
                              : _announcement.recipients.join(', '),
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppConstants.spacingLG),

            // Message Label
            Text(
              'Message',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),

            SizedBox(height: AppConstants.spacingSM),

            // Message Content
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppConstants.spacingMD),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainer.withValues(alpha: 0.5),
                borderRadius: context.radiusSM,
                border: Border.all(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _announcement.message,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Montserrat',
                  height: 1.6,
                ),
              ),
            ),

            SizedBox(height: AppConstants.spacingXL),

            // Status Badge
            if (widget.isArchived)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMD,
                  vertical: AppConstants.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.tertiaryContainer,
                  borderRadius: context.radiusSM,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.archive,
                      size: 16,
                      color: context.colorScheme.onTertiaryContainer,
                    ),
                    SizedBox(width: AppConstants.spacingXS),
                    Text(
                      'Archived',
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                        color: context.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAnnouncement() async {
    // TODO: Implement edit dialog
    AppLogger.info('Edit announcement: ${_announcement.id}');
    if (!mounted) return;
    Loaders.infoSnackBar(
      context,
      title: 'Coming Soon',
      message: 'Edit functionality will be implemented',
    );
  }

  Future<void> _confirmArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Archive Announcement',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive this announcement?',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.tertiary,
            ),
            child: Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _archiveAnnouncement();
    }
  }

  Future<void> _archiveAnnouncement() async {
    try {
      final repository = ref.read(announcementsRepositoryProvider);
      await repository.archiveAnnouncement(_announcement.id);

      AppLogger.info('Announcement archived: ${_announcement.id}');
      
      if (!mounted) return;
      
      Loaders.successSnackBar(
        context,
        title: 'Success',
        message: 'Announcement archived successfully',
      );
      
      // Navigate back
      Navigator.of(context).pop(true); // Return true to indicate change
    } catch (e) {
      AppLogger.error('Error archiving announcement: $e');
      if (!mounted) return;
      Loaders.errorSnackBar(
        context,
        title: 'Archive Failed',
        message: 'Error archiving announcement: $e',
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Announcement',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete this announcement? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.error,
              foregroundColor: context.colorScheme.onError,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAnnouncement();
    }
  }

  Future<void> _deleteAnnouncement() async {
    try {
      final repository = ref.read(announcementsRepositoryProvider);
      await repository.deleteAnnouncement(_announcement.id, archived: widget.isArchived);

      AppLogger.info('Announcement deleted: ${_announcement.id}');
      
      if (!mounted) return;
      
      Loaders.successSnackBar(
        context,
        title: 'Success',
        message: 'Announcement deleted successfully',
      );
      
      // Navigate back
      Navigator.of(context).pop(true); // Return true to indicate change
    } catch (e) {
      AppLogger.error('Error deleting announcement: $e');
      if (!mounted) return;
      Loaders.errorSnackBar(
        context,
        title: 'Delete Failed',
        message: 'Error deleting announcement: $e',
      );
    }
  }
}
