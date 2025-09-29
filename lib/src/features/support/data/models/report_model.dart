import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to parse DateTime from various formats (String or Timestamp)
DateTime? parseDateTime(dynamic dateTime) {
  if (dateTime == null) return null;
  
  if (dateTime is String) {
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

/// Report status enum
enum ReportStatus { pending, inProgress, resolved, closed }

/// Report model that matches the Firestore structure
class ReportModel {
  final String id;
  final String unitNumber;
  final String category;
  final String subCategory;
  final String description;
  final ReportStatus status;
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final TenantInfo tenant;
  final List<String> attachments;
  final List<ReportUpdate> updates;
  final ReportFeedback? feedback;

  ReportModel({
    required this.id,
    required this.unitNumber,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.status,
    required this.submittedAt,
    this.resolvedAt,
    this.closedAt,
    required this.tenant,
    this.attachments = const [],
    this.updates = const [],
    this.feedback,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitNumber': unitNumber,
      'category': category,
      'subCategory': subCategory,
      'description': description,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'tenant': tenant.toJson(),
      'attachments': attachments,
      'updates': updates.map((update) => update.toJson()).toList(),
      'feedback': feedback?.toJson(),
    };
  }

  /// Create from Firestore document
  factory ReportModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ReportModel.fromJson(data);
  }

  /// Create from JSON
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      unitNumber: json['unitNumber'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'] ?? '',
      description: json['description'] ?? '',
      status: _parseStatus(json['status']),
      submittedAt: parseDateTime(json['submittedAt'])!,
      resolvedAt: parseDateTime(json['resolvedAt']),
      closedAt: parseDateTime(json['closedAt']),
      tenant: TenantInfo.fromJson(json['tenant'] ?? {}),
      attachments: List<String>.from(json['attachments'] ?? []),
      updates: (json['updates'] as List<dynamic>? ?? [])
          .map((update) => ReportUpdate.fromJson(update))
          .toList(),
      feedback: json['feedback'] != null ? ReportFeedback.fromJson(json['feedback']) : null,
    );
  }

  static ReportStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status) {
        case 'pending':
          return ReportStatus.pending;
        case 'inProgress':
          return ReportStatus.inProgress;
        case 'resolved':
          return ReportStatus.resolved;
        case 'closed':
          return ReportStatus.closed;
        default:
          return ReportStatus.pending;
      }
    }
    return ReportStatus.pending;
  }

  /// Create empty report
  static ReportModel empty() => ReportModel(
        id: '',
        unitNumber: '',
        category: '',
        subCategory: '',
        description: '',
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenant: TenantInfo.empty(),
      );

  /// Copy with method for updates
  ReportModel copyWith({
    String? id,
    String? unitNumber,
    String? category,
    String? subCategory,
    String? description,
    ReportStatus? status,
    DateTime? submittedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
    TenantInfo? tenant,
    List<String>? attachments,
    List<ReportUpdate>? updates,
    ReportFeedback? feedback,
  }) {
    return ReportModel(
      id: id ?? this.id,
      unitNumber: unitNumber ?? this.unitNumber,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      description: description ?? this.description,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      tenant: tenant ?? this.tenant,
      attachments: attachments ?? this.attachments,
      updates: updates ?? this.updates,
      feedback: feedback ?? this.feedback,
    );
  }
}

/// Tenant information
class TenantInfo {
  final String userId;
  final String name;

  TenantInfo({
    required this.userId,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
    };
  }

  factory TenantInfo.fromJson(Map<String, dynamic> json) {
    return TenantInfo(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
    );
  }

  static TenantInfo empty() => TenantInfo(userId: '', name: '');
}

/// Report update/message
class ReportUpdate {
  final String message;
  final DateTime timestamp;
  final bool isAdmin;

  ReportUpdate({
    required this.message,
    required this.timestamp,
    required this.isAdmin,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isAdmin': isAdmin,
    };
  }

  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    return ReportUpdate(
      message: json['message'] ?? '',
      timestamp: parseDateTime(json['timestamp']) ?? DateTime.now(),
      isAdmin: json['isAdmin'] ?? false,
    );
  }
}

/// Report feedback from tenant
class ReportFeedback {
  final int rating;
  final String comment;

  ReportFeedback({
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
    };
  }

  factory ReportFeedback.fromJson(Map<String, dynamic> json) {
    return ReportFeedback(
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
    );
  }
}