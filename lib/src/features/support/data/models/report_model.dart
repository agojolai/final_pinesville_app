import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { pending, inProgress, resolved, closed }

class ReportModel {
  final String? id; // Firestore doc ID
  final String unitNumber;
  final String category;
  final String subCategory;
  final String description;
  final ReportStatus status;
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final ReportTenant tenant;
  final List<String> attachments;
  final List<ReportUpdate> updates;
  final ReportFeedback? feedback;

  const ReportModel({
    this.id,
    required this.unitNumber,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.status,
    required this.submittedAt,
    this.resolvedAt,
    required this.tenant,
    this.attachments = const [],
    this.updates = const [],
    this.feedback,
  });

  // Static function to create an empty report model
  static ReportModel empty() => ReportModel(
        id: "",
        unitNumber: "",
        category: "",
        subCategory: "",
        description: "",
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
        tenant: ReportTenant.empty(),
        attachments: [],
        updates: [],
      );

  // Convert model to JSON (Firestore format)
  Map<String, dynamic> toJson() {
    return {
      "unitNumber": unitNumber,
      "category": category,
      "subCategory": subCategory,
      "description": description,
      "status": status.name,
      "submittedAt": submittedAt.toIso8601String(),
      "resolvedAt": resolvedAt?.toIso8601String(),
      "tenant": tenant.toJson(),
      "attachments": attachments,
      "updates": updates.map((update) => update.toJson()).toList(),
      "feedback": feedback?.toJson(),
    };
  }

  // Helper function to safely parse date strings
  static DateTime? _parseDate(dynamic date) {
    if (date is String && date.isNotEmpty) {
      return DateTime.tryParse(date);
    }
    if (date is Timestamp) {
      return date.toDate();
    }
    return null;
  }

  // Helper function to parse ReportStatus from string
  static ReportStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
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

  // Factory method to create a ReportModel from a Firestore snapshot
  factory ReportModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return ReportModel.empty();

    return ReportModel(
      id: document.id,
      unitNumber: data['unitNumber'] ?? "",
      category: data['category'] ?? "",
      subCategory: data['subCategory'] ?? "",
      description: data['description'] ?? "",
      status: _parseStatus(data['status']),
      submittedAt: _parseDate(data['submittedAt']) ?? DateTime.now(),
      resolvedAt: _parseDate(data['resolvedAt']),
      tenant: ReportTenant.fromJson(data['tenant'] ?? {}),
      attachments: List<String>.from(data['attachments'] ?? []),
      updates: (data['updates'] as List<dynamic>? ?? [])
          .map((update) => ReportUpdate.fromJson(update))
          .toList(),
      feedback: data['feedback'] != null 
          ? ReportFeedback.fromJson(data['feedback']) 
          : null,
    );
  }

  // Copy with method for updating reports
  ReportModel copyWith({
    String? id,
    String? unitNumber,
    String? category,
    String? subCategory,
    String? description,
    ReportStatus? status,
    DateTime? submittedAt,
    DateTime? resolvedAt,
    ReportTenant? tenant,
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
      tenant: tenant ?? this.tenant,
      attachments: attachments ?? this.attachments,
      updates: updates ?? this.updates,
      feedback: feedback ?? this.feedback,
    );
  }
}

class ReportTenant {
  final String userId;
  final String name;

  const ReportTenant({
    required this.userId,
    required this.name,
  });

  static ReportTenant empty() => const ReportTenant(
        userId: "",
        name: "",
      );

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "name": name,
    };
  }

  factory ReportTenant.fromJson(Map<String, dynamic> json) {
    return ReportTenant(
      userId: json['userId'] ?? "",
      name: json['name'] ?? "",
    );
  }
}

class ReportUpdate {
  final String message;
  final DateTime timestamp;
  final bool isAdmin;

  const ReportUpdate({
    required this.message,
    required this.timestamp,
    required this.isAdmin,
  });

  Map<String, dynamic> toJson() {
    return {
      "message": message,
      "timestamp": timestamp.toIso8601String(),
      "isAdmin": isAdmin,
    };
  }

  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    return ReportUpdate(
      message: json['message'] ?? "",
      timestamp: ReportModel._parseDate(json['timestamp']) ?? DateTime.now(),
      isAdmin: json['isAdmin'] ?? false,
    );
  }
}

class ReportFeedback {
  final int rating;
  final String comment;

  const ReportFeedback({
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      "rating": rating,
      "comment": comment,
    };
  }

  factory ReportFeedback.fromJson(Map<String, dynamic> json) {
    return ReportFeedback(
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? "",
    );
  }
}