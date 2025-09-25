import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';

class StarRatingWidget extends StatefulWidget {
  final int initialRating;
  final int maxRating;
  final double starSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final Function(int rating) onRatingChanged;
  final bool isInteractive;

  const StarRatingWidget({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.starSize = 32.0,
    this.activeColor,
    this.inactiveColor,
    required this.onRatingChanged,
    this.isInteractive = true,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget>
    with TickerProviderStateMixin {
  late int _currentRating;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleStarTap(int rating) {
    if (!widget.isInteractive) return;

    HapticFeedback.lightImpact();
    setState(() {
      _currentRating = rating;
    });
    widget.onRatingChanged(rating);

    // Play animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.amber;
    final inactiveColor = widget.inactiveColor ?? 
        context.colorScheme.onSurface.withValues(alpha:0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starIndex = index + 1;
        final isActive = starIndex <= _currentRating;

        return GestureDetector(
          onTap: () => _handleStarTap(starIndex),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final scale = starIndex == _currentRating ? _scaleAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: EdgeInsets.all(AppConstants.spacingXS / 2),
                  child: Icon(
                    isActive ? Iconsax.star1 : Iconsax.star,
                    size: widget.starSize,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
