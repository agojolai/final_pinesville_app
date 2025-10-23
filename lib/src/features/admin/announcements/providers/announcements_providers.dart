import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/announcements_repository.dart';
import '../data/models/announcement_model.dart';
import '../data/models/template_model.dart';
import '../data/models/property_model.dart';

// ==================== REPOSITORY PROVIDER ====================

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository();
});

// ==================== ANNOUNCEMENTS PROVIDERS ====================

/// Stream provider for active announcements
final activeAnnouncementsStreamProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  return repository.getAnnouncementsStream(archived: false).map((snapshot) {
    return snapshot.docs
        .map((doc) => AnnouncementModel.fromFirestore(doc))
        .toList();
  });
});

/// Stream provider for archived announcements
final archivedAnnouncementsStreamProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  return repository.getAnnouncementsStream(archived: true).map((snapshot) {
    return snapshot.docs
        .map((doc) => AnnouncementModel.fromFirestore(doc))
        .toList();
  });
});

// ==================== TEMPLATES PROVIDERS ====================

/// Future provider for templates
final templatesProvider = FutureProvider<List<TemplateModel>>((ref) async {
  final repository = ref.watch(announcementsRepositoryProvider);
  return await repository.getTemplates();
});

/// Stream provider for templates
final templatesStreamProvider = StreamProvider<List<TemplateModel>>((ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  return repository.getTemplatesStream().map((snapshot) {
    return snapshot.docs
        .map((doc) => TemplateModel.fromFirestore(doc))
        .toList();
  });
});

// ==================== PROPERTIES PROVIDERS ====================

/// Future provider for properties
final propertiesProvider = FutureProvider<List<PropertyModel>>((ref) async {
  final repository = ref.watch(announcementsRepositoryProvider);
  return await repository.getProperties();
});

/// Stream provider for properties
final propertiesStreamProvider = StreamProvider<List<PropertyModel>>((ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  return repository.getPropertiesStream().map((snapshot) {
    return snapshot.docs
        .map((doc) => PropertyModel.fromFirestore(doc))
        .toList();
  });
});
