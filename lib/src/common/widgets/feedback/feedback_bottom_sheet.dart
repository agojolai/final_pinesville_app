import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'star_rating_widget.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';

class FeedbackBottomSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String submitButtonText;
  final String cancelButtonText;
  final int? initialRating;
  final String? initialComment;
  final Function(int rating, String comment) onSubmit;
  final VoidCallback? onCancel;

  const FeedbackBottomSheet({
    super.key,
    this.title = 'Rate Your Experience',
    this.subtitle = 'How satisfied are you with our service?',
    this.submitButtonText = 'Submit Feedback',
    this.cancelButtonText = 'Cancel',
    this.initialRating,
    this.initialComment,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  late int _rating;
  late TextEditingController _commentController;
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _commentController = TextEditingController(text: widget.initialComment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  Color _getRatingColor() {
    switch (_rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return context.colorScheme.onSurface.withOpacity(0.6);
    }
  }

  void _handleSubmit() {
    if (_rating == 0) {
      Loaders.errorSnackBar(
        context,
        title: 'Rating Required',
        message: 'Please select a rating before submitting',
      );
      return;
    }

    widget.onSubmit(_rating, _commentController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingLG,
        AppConstants.spacingMD,
        AppConstants.spacingLG,
        MediaQuery.of(context).viewInsets.bottom + AppConstants.spacingLG,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLG),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          SizedBox(height: AppConstants.spacingLG),
          
          // Header
          Row(
            children: [
              Icon(
                Iconsax.star1,
                color: context.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: Text(
                  widget.title,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Iconsax.close_circle,
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  widget.onCancel?.call();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.spacingMD),
          
          // Subtitle
          Text(
            widget.subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppConstants.spacingLG),
          
          // Star Rating
          StarRatingWidget(
            initialRating: _rating,
            starSize: 40,
            activeColor: _getRatingColor(),
            onRatingChanged: (rating) {
              setState(() {
                _rating = rating;
              });
            },
          ),
          
          SizedBox(height: AppConstants.spacingSM),
          
          // Rating Text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _getRatingText(),
              key: ValueKey(_rating),
              style: context.textTheme.bodyLarge?.copyWith(
                color: _getRatingColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          SizedBox(height: AppConstants.spacingLG),
          
          // Comment Field
          TextField(
            controller: _commentController,
            focusNode: _commentFocusNode,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Additional Comments (Optional)',
              hintText: 'Tell us more about your experience...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                borderSide: BorderSide(
                  color: context.colorScheme.primary,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Iconsax.message_text,
                color: context.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          
          SizedBox(height: AppConstants.spacingLG),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: AppConstants.spacingMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    ),
                  ),
                  child: Text(widget.cancelButtonText),
                ),
              ),
              
              SizedBox(width: AppConstants.spacingMD),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: context.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(
                      vertical: AppConstants.spacingMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    ),
                  ),
                  child: Text(widget.submitButtonText),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
