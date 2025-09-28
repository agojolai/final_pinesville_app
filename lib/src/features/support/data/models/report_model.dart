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
}