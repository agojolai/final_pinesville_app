import 'package:flutter/material.dart';
import 'feedback_dialog.dart';
import 'feedback_bottom_sheet.dart';

/// Utility class for showing feedback widgets
class FeedbackUtils {
  /// Show feedback as a dialog
  static Future<void> showFeedbackDialog(
    BuildContext context, {
    String? title,
    String? subtitle,
    String? submitButtonText,
    String? cancelButtonText,
    int? initialRating,
    String? initialComment,
    required Function(int rating, String comment) onSubmit,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FeedbackDialog(
        title: title ?? 'Rate Your Experience',
        subtitle: subtitle ?? 'How satisfied are you with our service?',
        submitButtonText: submitButtonText ?? 'Submit Feedback',
        cancelButtonText: cancelButtonText ?? 'Cancel',
        initialRating: initialRating,
        initialComment: initialComment,
        onSubmit: onSubmit,
        onCancel: onCancel,
      ),
    );
  }

  /// Show feedback as a bottom sheet
  static Future<void> showFeedbackBottomSheet(
    BuildContext context, {
    String? title,
    String? subtitle,
    String? submitButtonText,
    String? cancelButtonText,
    int? initialRating,
    String? initialComment,
    required Function(int rating, String comment) onSubmit,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedbackBottomSheet(
        title: title ?? 'Rate Your Experience',
        subtitle: subtitle ?? 'How satisfied are you with our service?',
        submitButtonText: submitButtonText ?? 'Submit Feedback',
        cancelButtonText: cancelButtonText ?? 'Cancel',
        initialRating: initialRating,
        initialComment: initialComment,
        onSubmit: onSubmit,
        onCancel: onCancel,
      ),
    );
  }

  /// Show feedback with automatic format selection based on screen size
  static Future<void> showFeedback(
    BuildContext context, {
    String? title,
    String? subtitle,
    String? submitButtonText,
    String? cancelButtonText,
    int? initialRating,
    String? initialComment,
    required Function(int rating, String comment) onSubmit,
    VoidCallback? onCancel,
    bool? forceDialog,
    bool? forceBottomSheet,
  }) {
    // Force specific format if requested
    if (forceDialog == true) {
      return showFeedbackDialog(
        context,
        title: title,
        subtitle: subtitle,
        submitButtonText: submitButtonText,
        cancelButtonText: cancelButtonText,
        initialRating: initialRating,
        initialComment: initialComment,
        onSubmit: onSubmit,
        onCancel: onCancel,
      );
    }

    if (forceBottomSheet == true) {
      return showFeedbackBottomSheet(
        context,
        title: title,
        subtitle: subtitle,
        submitButtonText: submitButtonText,
        cancelButtonText: cancelButtonText,
        initialRating: initialRating,
        initialComment: initialComment,
        onSubmit: onSubmit,
        onCancel: onCancel,
      );
    }

    // Auto-select based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final useBottomSheet = screenHeight < 700; // Use bottom sheet on smaller screens

    if (useBottomSheet) {
      return showFeedbackBottomSheet(
        context,
        title: title,
        subtitle: subtitle,
        submitButtonText: submitButtonText,
        cancelButtonText: cancelButtonText,
        initialRating: initialRating,
        initialComment: initialComment,
        onSubmit: onSubmit,
        onCancel: onCancel,
      );
    } else {
      return showFeedbackDialog(
        context,
        title: title,
        subtitle: subtitle,
        submitButtonText: submitButtonText,
        cancelButtonText: cancelButtonText,
        initialRating: initialRating,
        initialComment: initialComment,
        onSubmit: onSubmit,
        onCancel: onCancel,
      );
    }
  }
}

/// Model class for feedback data
class FeedbackData {
  final int rating;
  final String comment;
  final DateTime timestamp;

  const FeedbackData({
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory FeedbackData.fromJson(Map<String, dynamic> json) {
    return FeedbackData(
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'FeedbackData(rating: $rating, comment: "$comment", timestamp: $timestamp)';
  }
}
