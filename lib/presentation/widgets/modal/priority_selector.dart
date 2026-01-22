import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Priority item data class
class PriorityItem {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const PriorityItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Priority chip selector widget for task priority
/// Displays selectable priority chips with icons and colors
class PrioritySelector extends StatefulWidget {
  /// Currently selected priority value
  final String selectedPriority;

  /// Callback when priority changes
  final ValueChanged<String> onChanged;

  /// Whether the selector is enabled
  final bool enabled;

  /// Optional label text
  final String? label;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onChanged,
    this.enabled = true,
    this.label,
  });

  @override
  State<PrioritySelector> createState() => _PrioritySelectorState();
}

class _PrioritySelectorState extends State<PrioritySelector> {
  /// Available priority options
  static const List<PriorityItem> _priorityItems = [
    PriorityItem(
      value: AppConstants.priorityLow,
      label: '低',
      color: AppColors.priorityLow,
      icon: Icons.arrow_downward,
    ),
    PriorityItem(
      value: AppConstants.priorityMedium,
      label: '中',
      color: AppColors.priorityMedium,
      icon: Icons.remove,
    ),
    PriorityItem(
      value: AppConstants.priorityHigh,
      label: '高',
      color: AppColors.priorityHigh,
      icon: Icons.arrow_upward,
    ),
    PriorityItem(
      value: AppConstants.priorityCritical,
      label: '緊急',
      color: AppColors.priorityCritical,
      icon: Icons.priority_high,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],
        Wrap(
          spacing: AppConstants.paddingS,
          runSpacing: AppConstants.paddingS,
          children: _priorityItems.map((item) {
            final isSelected = item.value == widget.selectedPriority;
            return _PriorityChip(
              item: item,
              isSelected: isSelected,
              enabled: widget.enabled,
              onTap: () {
                if (widget.enabled) {
                  widget.onChanged(item.value);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Individual priority chip widget
class _PriorityChip extends StatefulWidget {
  final PriorityItem item;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.item,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PriorityChip> createState() => _PriorityChipState();
}

class _PriorityChipState extends State<_PriorityChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.item.color;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : widget.enabled
                    ? AppColors.surface
                    : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Priority icon
              AnimatedContainer(
                duration: AppConstants.animationFast,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.item.icon,
                  size: 14,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(width: AppConstants.paddingS),

              // Priority label
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? color
                      : widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                ),
              ),

              // Selected indicator
              if (isSelected) ...[
                const SizedBox(width: AppConstants.paddingXS),
                Icon(
                  Icons.check,
                  size: 16,
                  color: color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact priority indicator for display only
class PriorityIndicator extends StatelessWidget {
  final String priority;
  final bool showLabel;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getTaskPriorityColor(priority);
    final label = AppConstants.priorityLabels[priority] ?? priority;
    IconData icon;

    switch (priority) {
      case AppConstants.priorityLow:
        icon = Icons.arrow_downward;
        break;
      case AppConstants.priorityMedium:
        icon = Icons.remove;
        break;
      case AppConstants.priorityHigh:
        icon = Icons.arrow_upward;
        break;
      case AppConstants.priorityCritical:
        icon = Icons.priority_high;
        break;
      default:
        icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingS,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          if (showLabel) ...[
            const SizedBox(width: AppConstants.paddingXS),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated builder helper widget
