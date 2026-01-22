import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Custom progress slider widget for task completion percentage
/// Displays a slider with percentage label and visual feedback
class ProgressSlider extends StatefulWidget {
  /// Current progress value (0.0 - 1.0)
  final double value;

  /// Callback when progress changes
  final ValueChanged<double> onChanged;

  /// Whether the slider is enabled
  final bool enabled;

  /// Optional label text
  final String? label;

  const ProgressSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.label,
  });

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart() {
    if (!widget.enabled) return;
    setState(() => _isDragging = true);
    _animationController.forward();
  }

  void _handleDragEnd() {
    setState(() => _isDragging = false);
    _animationController.reverse();
  }

  Color _getProgressColor(double value) {
    if (value >= 1.0) {
      return AppColors.success;
    } else if (value >= 0.7) {
      return AppColors.primaryLight;
    } else if (value >= 0.3) {
      return AppColors.primary;
    } else {
      return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (widget.value * 100).round();
    final progressColor = _getProgressColor(widget.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label row with modern percentage display
        if (widget.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      progressPercent >= 100
                          ? Icons.check_circle_rounded
                          : Icons.trending_up_rounded,
                      color: progressColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingM,
                    vertical: AppConstants.paddingS,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        progressColor.withOpacity(0.15),
                        progressColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(
                      color: progressColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$progressPercent',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        '%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: progressColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],

        // Slider track
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onHorizontalDragStart: (_) => _handleDragStart(),
              onHorizontalDragEnd: (_) => _handleDragEnd(),
              onHorizontalDragCancel: _handleDragEnd,
              onTapDown: widget.enabled
                  ? (details) {
                      final newValue = (details.localPosition.dx /
                              constraints.maxWidth)
                          .clamp(0.0, 1.0);
                      widget.onChanged(newValue);
                    }
                  : null,
              onHorizontalDragUpdate: widget.enabled
                  ? (details) {
                      final newValue = (details.localPosition.dx /
                              constraints.maxWidth)
                          .clamp(0.0, 1.0);
                      widget.onChanged(newValue);
                    }
                  : null,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      clipBehavior: Clip.none,
                      children: [
                        // Background track
                        Container(
                          height: _isDragging ? 10 : 8,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusRound,
                            ),
                          ),
                        ),

                        // Progress track
                        AnimatedContainer(
                          duration: AppConstants.animationFast,
                          height: _isDragging ? 10 : 8,
                          width: constraints.maxWidth * widget.value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                progressColor.withOpacity(0.8),
                                progressColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusRound,
                            ),
                            boxShadow: _isDragging
                                ? [
                                    BoxShadow(
                                      color: progressColor.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),

                        // Thumb
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 50),
                          left: (constraints.maxWidth * widget.value) - 12,
                          child: AnimatedContainer(
                            duration: AppConstants.animationFast,
                            width: _isDragging ? 28 : 24,
                            height: _isDragging ? 28 : 24,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: progressColor,
                                width: _isDragging ? 4 : 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: _isDragging ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: widget.enabled
                                ? null
                                : Icon(
                                    Icons.lock_outline,
                                    size: 12,
                                    color: AppColors.textTertiary,
                                  ),
                          ),
                        ),

                        // Percentage tooltip (shown while dragging)
                        if (_isDragging)
                          Positioned(
                            left:
                                (constraints.maxWidth * widget.value) - 24,
                            top: -36,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingS,
                                vertical: AppConstants.paddingXS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tooltipBackground,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusS,
                                ),
                              ),
                              child: Text(
                                '$progressPercent%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),

        // Modern progress milestones with icons
        const SizedBox(height: AppConstants.paddingM),
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMilestone(0, progressPercent, '開始', Icons.play_arrow_rounded),
              _buildMilestone(25, progressPercent, '25%', Icons.looks_one_rounded),
              _buildMilestone(50, progressPercent, '半分', Icons.hourglass_top_rounded),
              _buildMilestone(75, progressPercent, '75%', Icons.looks_3_rounded),
              _buildMilestone(100, progressPercent, '完了', Icons.flag_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestone(int value, int currentProgress, String label, IconData icon) {
    final isActive = currentProgress >= value;
    final isPassed = currentProgress > value;
    final progressColor = _getProgressColor(widget.value);

    return GestureDetector(
      onTap: widget.enabled ? () => widget.onChanged(value / 100.0) : null,
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppConstants.animationFast,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? progressColor.withOpacity(isPassed ? 1.0 : 0.15)
                  : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? progressColor : AppColors.border,
                width: isActive && isPassed ? 0 : 2,
              ),
              boxShadow: isPassed
                  ? [
                      BoxShadow(
                        color: progressColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isPassed
                  ? Colors.white
                  : isActive
                      ? progressColor
                      : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isActive ? progressColor : AppColors.textTertiary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated builder helper widget
