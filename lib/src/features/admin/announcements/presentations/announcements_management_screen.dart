import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

import '../data/models/announcement_model.dart';
import '../providers/announcements_providers.dart';
import 'announcement_detail_screen.dart';
import 'compose_screen.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../../../../core/snackbars/loaders.dart';
import '../../../../core/utils/app_logger.dart';

class AnnouncementsManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback onMenuTap;
  
  const AnnouncementsManagementScreen({
    super.key,
    required this.onMenuTap,
  });

  @override
  ConsumerState<AnnouncementsManagementScreen> createState() => _AnnouncementsManagementScreenState();
}

class _AnnouncementsManagementScreenState extends ConsumerState<AnnouncementsManagementScreen> {
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Announcements Management Screen initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.menu, color: context.colorScheme.onSurface),
          onPressed: widget.onMenuTap,
        ),
        title: Text(
          'Announcements',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showArchived ? Iconsax.archive_minus : Iconsax.archive_add,
              color: context.colorScheme.onSurface,
            ),
            tooltip: _showArchived ? 'Show Active' : 'Show Archived',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showArchived = !_showArchived;
              });
            },
          ),
          SizedBox(width: AppConstants.spacingSM),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppConstants.spacingMD),
        child: Consumer(
          builder: (context, ref, child) {
            final announcementsAsync = _showArchived
                ? ref.watch(archivedAnnouncementsStreamProvider)
                : ref.watch(activeAnnouncementsStreamProvider);

            return announcementsAsync.when(
              data: (announcements) {
                if (announcements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showArchived ? Iconsax.archive : Iconsax.document_text,
                          size: 64,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        SizedBox(height: AppConstants.spacingMD),
                        Text(
                          _showArchived
                              ? 'No archived announcements'
                              : 'No announcements yet',
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        SizedBox(height: AppConstants.spacingMD),
                        if (!_showArchived)
                          ElevatedButton.icon(
                            onPressed: _composeAnnouncement,
                            icon: Icon(Iconsax.add_circle),
                            label: Text('Create Announcement'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colorScheme.primary,
                              foregroundColor: context.colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingLG,
                                vertical: AppConstants.spacingMD,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: AppConstants.spacingMD),
                      child: ListTile(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AnnouncementDetailScreen(
                                announcement: announcement,
                                isArchived: _showArchived,
                              ),
                            ),
                          );
                          // Refresh if announcement was modified
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                        title: Text(
                          announcement.title,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: AppConstants.spacingXS),
                            Text(
                              announcement.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            SizedBox(height: AppConstants.spacingXS),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.people,
                                  size: 16,
                                  color: context.colorScheme.primary,
                                ),
                                SizedBox(width: AppConstants.spacingXS),
                                Expanded(
                                  child: Text(
                                    announcement.recipients.isEmpty
                                        ? 'No recipients'
                                        : announcement.recipients.join(', '),
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colorScheme.primary,
                                      fontFamily: 'Montserrat',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, y').format(announcement.timestamp),
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Iconsax.more),
                          onSelected: (value) {
                            if (value == 'archive' && !_showArchived) {
                              _archiveAnnouncement(announcement);
                            } else if (value == 'delete') {
                              _deleteAnnouncement(announcement);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!_showArchived)
                              PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(Iconsax.archive_add),
                                    SizedBox(width: AppConstants.spacingSM),
                                    Text('Archive'),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Iconsax.trash, color: context.colorScheme.error),
                                  SizedBox(width: AppConstants.spacingSM),
                                  Text('Delete', style: TextStyle(color: context.colorScheme.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: context.colorScheme.primary,
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.danger,
                      size: 48,
                      color: context.colorScheme.error,
                    ),
                    SizedBox(height: AppConstants.spacingMD),
                    Text(
                      'Error loading announcements',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colorScheme.error,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: !_showArchived
          ? FloatingActionButton.extended(
              heroTag: 'compose_announcement_fab',
              onPressed: _composeAnnouncement,
              icon: Icon(Iconsax.add),
              label: Text('Compose'),
              backgroundColor: context.colorScheme.primary,
              foregroundColor: context.colorScheme.onPrimary,
            )
          : null,
    );
  }

  Future<void> _composeAnnouncement() async {
    HapticFeedback.lightImpact();
    await showComposeAnnouncementDialog(context, ref);
    // Refresh list after composing
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _archiveAnnouncement(AnnouncementModel announcement) async {
    try {
      final repository = ref.read(announcementsRepositoryProvider);
      await repository.archiveAnnouncement(announcement.id);

      if (!mounted) return;
      Loaders.successSnackBar(
        context,
        title: 'Success',
        message: 'Announcement archived successfully',
      );
      AppLogger.info('Announcement archived');
    } catch (e) {
      AppLogger.error('Error archiving announcement');
      if (!mounted) return;
      Loaders.errorSnackBar(
        context,
        title: 'Archive Failed',
        message: 'Error archiving announcement',
      );
    }
  }

  Future<void> _deleteAnnouncement(AnnouncementModel announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Announcement',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this announcement?',
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
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(announcementsRepositoryProvider);
        await repository.deleteAnnouncement(announcement.id, archived: _showArchived);

        if (!mounted) return;
        Loaders.successSnackBar(
          context,
          title: 'Success',
          message: 'Announcement deleted successfully',
        );
        AppLogger.info('Announcement deleted');
      } catch (e) {
        AppLogger.error('Error deleting announcement');
        if (!mounted) return;
        Loaders.errorSnackBar(
          context,
          title: 'Delete Failed',
          message: 'Error deleting announcement',
        );
      }
    }
  }
}