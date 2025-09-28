/// Data models for the reports and tickets feature
enum ReportStatus { pending, inProgress, resolved, closed }

class Report {
  final String id;
  final String unitNumber;
  final String category;
  final String subCategory;
  final String description;
  final ReportStatus status;
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final String tenantName;
  final List<String> attachments;
  final List<ReportUpdate> updates;

  Report({
    required this.id,
    required this.unitNumber,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.status,
    required this.submittedAt,
    this.resolvedAt,
    required this.tenantName,
    this.attachments = const [],
    this.updates = const [],
  });

  Report copyWith({
    String? id,
    String? unitNumber,
    String? category,
    String? subCategory,
    String? description,
    ReportStatus? status,
    DateTime? submittedAt,
    DateTime? resolvedAt,
    String? tenantName,
    List<String>? attachments,
    List<ReportUpdate>? updates,
  }) {
    return Report(
      id: id ?? this.id,
      unitNumber: unitNumber ?? this.unitNumber,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      description: description ?? this.description,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      tenantName: tenantName ?? this.tenantName,
      attachments: attachments ?? this.attachments,
      updates: updates ?? this.updates,
    );
  }

  /// Convert Report to JSON for Firestore
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
      'tenantName': tenantName,
      'attachments': attachments,
      'updates': updates.map((update) => update.toJson()).toList(),
    };
  }

  /// Create Report from JSON (Firestore)
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      unitNumber: json['unitNumber'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'] ?? '',
      description: json['description'] ?? '',
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      submittedAt: DateTime.parse(json['submittedAt']),
      resolvedAt: json['resolvedAt'] != null 
          ? DateTime.parse(json['resolvedAt']) 
          : null,
      tenantName: json['tenantName'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      updates: (json['updates'] as List<dynamic>?)
          ?.map((update) => ReportUpdate.fromJson(update))
          .toList() ?? [],
    );
  }
}

class ReportUpdate {
  final String message;
  final DateTime timestamp;
  final bool isAdmin;

  ReportUpdate({
    required this.message,
    required this.timestamp,
    required this.isAdmin,
  });

  /// Convert ReportUpdate to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isAdmin': isAdmin,
    };
  }

  /// Create ReportUpdate from JSON (Firestore)
  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    return ReportUpdate(
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isAdmin: json['isAdmin'] ?? false,
    );
  }
}