import 'package:cloud_firestore/cloud_firestore.dart';

/// Priority levels for announcements
enum AnnouncementPriority {
  low,
  normal,
  high,
  urgent;

  /// Convert enum to string for Firestore
  String get value => name;

  /// Parse string to enum
  static AnnouncementPriority fromString(String? value) {
    switch (value) {
      case 'low':
        return AnnouncementPriority.low;
      case 'high':
        return AnnouncementPriority.high;
      case 'urgent':
        return AnnouncementPriority.urgent;
      case 'normal':
      default:
        return AnnouncementPriority.normal;
    }
  }
}

/// Announcement type for categorization
enum AnnouncementType {
  general,
  maintenance,
  billing,
  event,
  emergency;

  /// Convert enum to string for Firestore
  String get value => name;

  /// Parse string to enum
  static AnnouncementType fromString(String? value) {
    switch (value) {
      case 'maintenance':
        return AnnouncementType.maintenance;
      case 'billing':
        return AnnouncementType.billing;
      case 'event':
        return AnnouncementType.event;
      case 'emergency':
        return AnnouncementType.emergency;
      case 'general':
      default:
        return AnnouncementType.general;
    }
  }
}

/// Announcement model for property-wide announcements
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final AnnouncementType type;
  final AnnouncementPriority priority;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isActive;
  final String createdBy;
  final List<String> attachments;
  final Map<String, bool> readBy; // userId -> read status

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.scheduledFor,
    required this.isActive,
    required this.createdBy,
    this.attachments = const [],
    this.readBy = const {},
  });

  /// Check if announcement is urgent or high priority
  bool get isImportant => priority == AnnouncementPriority.urgent || 
                         priority == AnnouncementPriority.high;

  /// Check if announcement is scheduled for future
  bool get isScheduled => scheduledFor != null && 
                         scheduledFor!.isAfter(DateTime.now());

  /// Get read percentage
  double getReadPercentage(int totalTenants) {
    if (totalTenants == 0) return 0.0;
    return (readBy.values.where((read) => read).length / totalTenants) * 100;
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.value,
      'priority': priority.value,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'isActive': isActive,
      'createdBy': createdBy,
      'attachments': attachments,
      'readBy': readBy,
    };
  }

  /// Create from Firestore document
  factory AnnouncementModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return AnnouncementModel.fromJson(data);
  }

  /// Create from JSON
  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: AnnouncementType.fromString(json['type']),
      priority: AnnouncementPriority.fromString(json['priority']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      scheduledFor: _parseDateTime(json['scheduledFor']),
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      readBy: Map<String, bool>.from(json['readBy'] ?? {}),
    );
  }

  /// Helper function to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    
    if (dateTime is String && dateTime.isNotEmpty) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return null;
      }
    }
    
    if (dateTime is Timestamp) {
      return dateTime.toDate();
    }
    
    return null;
  }

  /// Create empty announcement
  static AnnouncementModel empty() => AnnouncementModel(
        id: '',
        title: '',
        content: '',
        type: AnnouncementType.general,
        priority: AnnouncementPriority.normal,
        createdAt: DateTime.now(),
        isActive: true,
        createdBy: '',
      );

  /// Copy with method for updates
  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    AnnouncementType? type,
    AnnouncementPriority? priority,
    DateTime? createdAt,
    DateTime? scheduledFor,
    bool? isActive,
    String? createdBy,
    List<String>? attachments,
    Map<String, bool>? readBy,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      attachments: attachments ?? this.attachments,
      readBy: readBy ?? this.readBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AnnouncementModel{id: $id, title: $title, type: $type, priority: $priority, isActive: $isActive}';
  }
}