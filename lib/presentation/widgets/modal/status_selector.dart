import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Status item data class
class StatusItem {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const StatusItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Status dropdown selector widget for task status
/// Displays a dropdown with colored status options
class StatusSelector extends StatefulWidget {
  /// Currently selected status value
  final String selectedStatus;

  /// Callback when status changes
  final ValueChanged<String> onChanged;

  /// Whether the selector is enabled
  final bool enabled;

  /// Optional label text
  final String? label;

  const StatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
    this.enabled = true,
    this.label,
  });

  @override
  State<StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends State<StatusSelector>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  /// Available status options
  static const List<StatusItem> _statusItems = [
    StatusItem(
      value: AppConstants.statusNotStarted,
      label: '未着手',
      color: AppColors.taskNotStarted,
      icon: Icons.circle_outlined,
    ),
    StatusItem(
      value: AppConstants.statusInProgress,
      label: '進行中',
      color: AppColors.taskInProgress,
      icon: Icons.play_circle_outline,
    ),
    StatusItem(
      value: AppConstants.statusCompleted,
      label: '完了',
      color: AppColors.taskCompleted,
      icon: Icons.check_circle_outline,
    ),
    StatusItem(
      value: AppConstants.statusDelayed,
      label: '遅延',
      color: AppColors.taskDelayed,
      icon: Icons.warning_amber_outlined,
    ),
    StatusItem(
      value: AppConstants.statusOnHold,
      label: '保留',
      color: AppColors.taskOnHold,
      icon: Icons.pause_circle_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<double>(begin: -10.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  StatusItem _getSelectedItem() {
    return _statusItems.firstWhere(
      (item) => item.value == widget.selectedStatus,
      orElse: () => _statusItems.first,
    );
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;

    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _animationController.reverse().then((_) {
      _removeOverlay();
    });
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectStatus(String status) {
    widget.onChanged(status);
    _closeDropdown();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop to close dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown menu
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  shadowColor: AppColors.shadow,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _statusItems.map((item) {
                        final isSelected = item.value == widget.selectedStatus;
                        return _StatusOptionTile(
                          item: item,
                          isSelected: isSelected,
                          onTap: () => _selectStatus(item.value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = _getSelectedItem();

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
          const SizedBox(height: AppConstants.paddingS),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingM,
              ),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? AppColors.inputBackground
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: _isOpen ? AppColors.primary : AppColors.border,
                  width: _isOpen ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selectedItem.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: Icon(
                      selectedItem.icon,
                      color: selectedItem.color,
                      size: AppConstants.iconSizeM,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),

                  // Status label
                  Expanded(
                    child: Text(
                      selectedItem.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: widget.enabled
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),

                  // Dropdown arrow
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: AppConstants.animationFast,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: widget.enabled
                          ? AppColors.iconDefault
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual status option tile in dropdown
class _StatusOptionTile extends StatefulWidget {
  final StatusItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOptionTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StatusOptionTile> createState() => _StatusOptionTileState();
}

class _StatusOptionTileState extends State<_StatusOptionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingM,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.item.color.withOpacity(0.1)
                : _isHovered
                    ? AppColors.surfaceVariant
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.item.color,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),

              // Status label
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isSelected
                        ? widget.item.color
                        : AppColors.textPrimary,
                  ),
                ),
              ),

              // Selected checkmark
              if (widget.isSelected)
                Icon(
                  Icons.check,
                  color: widget.item.color,
                  size: AppConstants.iconSizeM,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated builder helper widget for status selector
