import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/announcements_repository.dart';
import '../data/models/announcement_model.dart';
import '../data/models/template_model.dart';
import '../data/models/property_model.dart';

// ==================== REPOSITORY PROVIDER ====================

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository();
});

// ==================== TENANT ANNOUNCEMENTS (7-day filter for efficiency) ====================

/// Stream provider for tenant announcements (7-day filter)
final tenantAnnouncementsStreamProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  return repository.getAnnouncementsStream(archived: false).map((snapshot) {
    return snapshot.docs
        .map((doc) => AnnouncementModel.fromFirestore(doc))
        .toList();
  });
});

// ==================== ADMIN ANNOUNCEMENTS (Pagination) ====================

/// State for paginated announcements
class PaginatedAnnouncementsState {
  final List<AnnouncementModel> announcements;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String? error;

  PaginatedAnnouncementsState({
    this.announcements = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
    this.error,
  });

  PaginatedAnnouncementsState copyWith({
    List<AnnouncementModel>? announcements,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    String? error,
  }) {
    return PaginatedAnnouncementsState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier for admin announcements pagination
class AdminAnnouncementsPaginationNotifier extends StateNotifier<PaginatedAnnouncementsState> {
  final AnnouncementsRepository _repository;
  final bool _archived;

  AdminAnnouncementsPaginationNotifier(this._repository, this._archived)
      : super(PaginatedAnnouncementsState());

  /// Load initial page or refresh
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final snapshot = await _repository.getPaginatedAnnouncements(
        archived: _archived,
        limit: 10,
      );
      
      final announcements = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .toList();
      
      state = PaginatedAnnouncementsState(
        announcements: announcements,
        isLoading: false,
        hasMore: snapshot.docs.length == 10,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load next page
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final snapshot = await _repository.getPaginatedAnnouncements(
        archived: _archived,
        limit: 10,
        startAfterDoc: state.lastDocument,
      );
      
      final newAnnouncements = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .toList();
      
      state = state.copyWith(
        announcements: [...state.announcements, ...newAnnouncements],
        isLoading: false,
        hasMore: snapshot.docs.length == 10,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : state.lastDocument,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh (reload from beginning)
  Future<void> refresh() async {
    state = PaginatedAnnouncementsState();
    await loadInitial();
  }
}

/// Provider for active announcements pagination (admin use)
final adminActiveAnnouncementsProvider = StateNotifierProvider<AdminAnnouncementsPaginationNotifier, PaginatedAnnouncementsState>((ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  final notifier = AdminAnnouncementsPaginationNotifier(repository, false);
  notifier.loadInitial(); // Auto-load first page
  return notifier;
});

/// Provider for archived announcements pagination (admin use)
final adminArchivedAnnouncementsProvider = StateNotifierProvider<AdminAnnouncementsPaginationNotifier, PaginatedAnnouncementsState>((ref) {
  final repository = ref.watch(announcementsRepositoryProvider);
  final notifier = AdminAnnouncementsPaginationNotifier(repository, true);
  notifier.loadInitial(); // Auto-load first page
  return notifier;
});

// ==================== LEGACY PROVIDERS (Deprecated - use tenant or admin versions) ====================

/// @deprecated Use tenantAnnouncementsStreamProvider for tenant side
final activeAnnouncementsStreamProvider = tenantAnnouncementsStreamProvider;

/// @deprecated Use adminArchivedAnnouncementsProvider for admin side
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
