import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/announcements_providers.dart';
import '../../../../core/snackbars/loaders.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';

// Template dialog using Riverpod
Future<void> showTemplateDialog(
  BuildContext context,
  WidgetRef ref,
  void Function(String subject, String message, List<String> recipients)
      onTemplateSelected,
  void Function(String subject, String message) onTemplateCreated,
) async {
  await showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final templatesAsync = ref.watch(templatesStreamProvider);

          return Dialog(
            backgroundColor: context.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: context.radiusMD,
            ),
            child: Container(
              width: 400,
              constraints: const BoxConstraints(maxHeight: 500),
              padding: EdgeInsets.all(AppConstants.spacingLG),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Template',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Iconsax.close_circle, color: context.colorScheme.onSurface),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacingMD),
                  Expanded(
                    child: templatesAsync.when(
                      data: (templates) {
                        if (templates.isEmpty) {
                          return Center(
                            child: Text(
                              'No templates yet.\nCreate one using "Save Template" button.',
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: templates.length,
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            return ListTile(
                              title: Text(
                                template.subject,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template.message.length > 40
                                        ? '${template.message.substring(0, 40)}...'
                                        : template.message,
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  if (template.recipients.isNotEmpty)
                                    Text(
                                      'Recipients: ${template.recipients.join(", ")}',
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: context.colorScheme.primary,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Iconsax.trash,
                                  color: context.colorScheme.error,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  try {
                                    final repository = ref
                                        .read(announcementsRepositoryProvider);
                                    await repository
                                        .deleteTemplate(template.id);
                                    AppLogger.info('🗑️ Template deleted: ${template.id}');
                                    Navigator.of(context).pop();
                                    if (context.mounted) {
                                      Loaders.successSnackBar(
                                        context,
                                        title: 'Success',
                                        message: 'Template deleted',
                                      );
                                    }
                                  } catch (e) {
                                    AppLogger.error('❌ Error deleting template: $e');
                                    if (context.mounted) {
                                      Loaders.errorSnackBar(
                                        context,
                                        title: 'Error',
                                        message: 'Error deleting template: $e',
                                      );
                                    }
                                  }
                                },
                              ),
                              onTap: () {
                                onTemplateSelected(template.subject,
                                    template.message, template.recipients);
                                Navigator.of(context).pop();
                              },
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
                        child: Text(
                          'Error loading templates: $error',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.error,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showComposeAnnouncementDialog(
    BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  List<String> selectedRecipients = [];

  return showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final propertiesAsync = ref.watch(propertiesStreamProvider);

          return Dialog(
            backgroundColor: context.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: context.radiusMD,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width > 650
                  ? 650
                  : MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Form(
                key: formKey,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return propertiesAsync.when(
                      loading: () => SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: context.colorScheme.primary,
                          ),
                        ),
                      ),
                      error: (error, stack) => SizedBox(
                        height: 300,
                        child: Center(
                          child: Text(
                            'Error loading properties: $error',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.error,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ),
                      data: (properties) {
                        // Build recipients list
                        final recipients = <String>['all'];
                        for (var property in properties) {
                          recipients.add(property.name);
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Container(
                              padding: EdgeInsets.all(AppConstants.spacingLG),
                              decoration: BoxDecoration(
                                color: context.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.vertical(
                                  top: context.radiusMD.topLeft,
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Iconsax.message_text,
                                    color: context.colorScheme.primary,
                                  ),
                                  SizedBox(width: AppConstants.spacingSM),
                                  Expanded(
                                    child: Text(
                                      'Create a new Announcement',
                                      style: context.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Iconsax.close_circle,
                                      size: 20,
                                      color: context.colorScheme.onSurface,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            // Form content
                            Flexible(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(AppConstants.spacingLG),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Recipients section
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppConstants.spacingSM,
                                        vertical: AppConstants.spacingXS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.surfaceContainer,
                                        borderRadius: context.radiusSM,
                                        border: Border.all(
                                          color: context.colorScheme.outline.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Send to',
                                            style: context.textTheme.bodyMedium?.copyWith(
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: AppConstants.spacingXS),
                                          Icon(
                                            Iconsax.arrow_down_1,
                                            size: 20,
                                            color: context.colorScheme.onSurface,
                                          ),
                                          SizedBox(width: AppConstants.spacingMD),
                                          Expanded(
                                            child: selectedRecipients.isEmpty
                                                ? Text(
                                                    'Select recipients...',
                                                    style: context.textTheme.bodyMedium?.copyWith(
                                                      color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                                                      fontFamily: 'Montserrat',
                                                    ),
                                                  )
                                                : SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children:
                                                          selectedRecipients
                                                              .map((recipient) {
                                                        return Container(
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: AppConstants.spacingSM,
                                                            vertical: AppConstants.spacingXS,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: context.colorScheme.primaryContainer,
                                                            borderRadius: context.radiusSM,
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              ConstrainedBox(
                                                                constraints: const BoxConstraints(
                                                                  maxWidth: 150,
                                                                ),
                                                                child: Text(
                                                                  recipient,
                                                                  style: context.textTheme.bodySmall?.copyWith(
                                                                    fontFamily: 'Montserrat',
                                                                    fontWeight: FontWeight.w500,
                                                                    color: context.colorScheme.onPrimaryContainer,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                              SizedBox(width: AppConstants.spacingXS),
                                                              InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    selectedRecipients.remove(recipient);
                                                                  });
                                                                },
                                                                child: Icon(
                                                                  Iconsax.close_circle,
                                                                  size: 16,
                                                                  color: context.colorScheme.onPrimaryContainer,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Iconsax.add_circle,
                                              size: 20,
                                              color: context.colorScheme.primary,
                                            ),
                                            onSelected: (value) {
                                              if (!selectedRecipients
                                                  .contains(value)) {
                                                setState(() {
                                                  selectedRecipients.add(value);
                                                });
                                              }
                                            },
                                            itemBuilder: (context) {
                                              return recipients
                                                  .map((recipient) {
                                                return PopupMenuItem<String>(
                                                  value: recipient,
                                                  child: Text(recipient),
                                                );
                                              }).toList();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Subject field
                                    TextFormField(
                                      controller: subjectController,
                                      style: context.textTheme.bodyLarge?.copyWith(
                                        fontFamily: 'Montserrat',
                                        color: context.colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Subject',
                                        labelStyle: context.textTheme.bodyMedium?.copyWith(
                                          fontFamily: 'Montserrat',
                                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: context.colorScheme.primary.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: context.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: context.colorScheme.error,
                                          ),
                                        ),
                                        focusedErrorBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: context.colorScheme.error,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter a subject';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: AppConstants.spacingLG),
                                    // Message field
                                    TextFormField(
                                      controller: messageController,
                                      style: context.textTheme.bodyLarge?.copyWith(
                                        fontFamily: 'Montserrat',
                                        color: context.colorScheme.onSurface,
                                      ),
                                      maxLines: 6,
                                      decoration: InputDecoration(
                                        hintText: 'What do you want to write?',
                                        hintStyle: context.textTheme.bodyMedium?.copyWith(
                                          fontFamily: 'Montserrat',
                                          color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                                        ),
                                        filled: true,
                                        fillColor: context.colorScheme.surfaceContainerHighest,
                                        border: OutlineInputBorder(
                                          borderRadius: context.radiusMD,
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: context.radiusMD,
                                          borderSide: BorderSide(
                                            color: context.colorScheme.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: context.radiusMD,
                                          borderSide: BorderSide(
                                            color: context.colorScheme.error,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: context.radiusMD,
                                          borderSide: BorderSide(
                                            color: context.colorScheme.error,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter a message';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                            // Footer buttons
                            Container(
                              padding: EdgeInsets.all(AppConstants.spacingLG),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: context.colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Row(
                                    children: [
                                      // Left side - Template icon buttons
                                      IconButton(
                                        onPressed: () async {
                                          await showTemplateDialog(
                                            context,
                                            ref,
                                            (subject, message, recipients) {
                                              setState(() {
                                                subjectController.text =
                                                    subject;
                                                messageController.text =
                                                    message;
                                                selectedRecipients =
                                                    List<String>.from(
                                                        recipients);
                                              });
                                            },
                                            (subject, message) {
                                              setState(() {
                                                subjectController.text =
                                                    subject;
                                                messageController.text =
                                                    message;
                                              });
                                            },
                                          );
                                        },
                                        icon: Icon(
                                          Iconsax.folder_open,
                                          color: context.colorScheme.primary,
                                        ),
                                        tooltip: 'Use Template',
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          if (subjectController.text
                                                  .trim()
                                                  .isEmpty ||
                                              messageController.text
                                                  .trim()
                                                  .isEmpty) {
                                            if (context.mounted) {
                                              Loaders.warningSnackBar(
                                                context,
                                                title: 'Incomplete',
                                                message: 'Please enter subject and message to save as template',
                                              );
                                            }
                                            return;
                                          }
                                          try {
                                            final repository = ref.read(
                                                announcementsRepositoryProvider);
                                            await repository.createTemplate(
                                              subject: subjectController.text
                                                  .trim(),
                                              message: messageController.text
                                                  .trim(),
                                              recipients: selectedRecipients,
                                            );
                                            AppLogger.info('💾 Template saved successfully');
                                            if (context.mounted) {
                                              Loaders.successSnackBar(
                                                context,
                                                title: 'Success',
                                                message: 'Template saved successfully!',
                                              );
                                            }
                                          } catch (e) {
                                            AppLogger.error('❌ Error saving template: $e');
                                            if (context.mounted) {
                                              Loaders.errorSnackBar(
                                                context,
                                                title: 'Error',
                                                message: 'Error saving template: $e',
                                              );
                                            }
                                          }
                                        },
                                        icon: Icon(
                                          Iconsax.save_2,
                                          color: context.colorScheme.primary,
                                        ),
                                        tooltip: 'Save Template',
                                      ),
                                      Spacer(),
                                      // Right side - Send button
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.colorScheme.primary,
                                          foregroundColor: context.colorScheme.onPrimary,
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: context.radiusMD,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppConstants.spacingMD,
                                            vertical: AppConstants.spacingSM,
                                          ),
                                        ),
                                        onPressed: () async {
                                          if (formKey.currentState!
                                              .validate()) {
                                            if (selectedRecipients.isEmpty) {
                                              if (context.mounted) {
                                                Loaders.warningSnackBar(
                                                  context,
                                                  title: 'No Recipients',
                                                  message: 'Please select at least one recipient',
                                                );
                                              }
                                              return;
                                            }
                                            try {
                                              final repository = ref.read(
                                                  announcementsRepositoryProvider);
                                              await repository
                                                  .createAnnouncement(
                                                title: subjectController.text
                                                    .trim(),
                                                message: messageController
                                                    .text
                                                    .trim(),
                                                recipients:
                                                    selectedRecipients,
                                              );
                                              AppLogger.info('📢 Announcement sent successfully');
                                              Navigator.of(context).pop();
                                              if (context.mounted) {
                                                Loaders.successSnackBar(
                                                  context,
                                                  title: 'Success',
                                                  message: 'Announcement sent successfully!',
                                                );
                                              }
                                            } catch (e) {
                                              AppLogger.error('❌ Error sending announcement: $e');
                                              if (context.mounted) {
                                                Loaders.errorSnackBar(
                                                  context,
                                                  title: 'Error',
                                                  message: 'Error sending announcement: $e',
                                                );
                                              }
                                            }
                                          }
                                        },
                                        icon: Icon(Iconsax.send_2, size: 20),
                                        label: Text(
                                          'Send',
                                          style: context.textTheme.bodyMedium?.copyWith(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
