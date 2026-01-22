import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Context menu item definition
class ContextMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final bool isDanger;
  final bool isDisabled;
  final List<ContextMenuItem>? submenu;

  const ContextMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.isDanger = false,
    this.isDisabled = false,
    this.submenu,
  });
}

/// Context menu widget for right-click actions
class ContextMenu extends StatelessWidget {
  final List<ContextMenuItem> items;
  final VoidCallback onDismiss;

  const ContextMenu({
    super.key,
    required this.items,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0 && items[i - 1].submenu == null)
                  const Divider(height: 1, indent: 12, endIndent: 12),
                _ContextMenuItemWidget(
                  item: items[i],
                  onTap: () {
                    onDismiss();
                    items[i].onTap();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextMenuItemWidget extends StatefulWidget {
  final ContextMenuItem item;
  final VoidCallback onTap;

  const _ContextMenuItemWidget({
    required this.item,
    required this.onTap,
  });

  @override
  State<_ContextMenuItemWidget> createState() => _ContextMenuItemWidgetState();
}

class _ContextMenuItemWidgetState extends State<_ContextMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final itemColor = widget.item.isDanger
        ? AppColors.error
        : (widget.item.color ?? AppColors.textPrimary);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.item.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: _isHovered && !widget.item.isDisabled
              ? (widget.item.isDanger
                  ? AppColors.errorLight
                  : AppColors.ganttRowHover)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 18,
                color: widget.item.isDisabled
                    ? AppColors.textTertiary
                    : itemColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.item.isDisabled
                        ? AppColors.textTertiary
                        : itemColor,
                  ),
                ),
              ),
              if (widget.item.submenu != null)
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show context menu at position
void showContextMenu({
  required BuildContext context,
  required Offset position,
  required List<ContextMenuItem> items,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Background dismiss area
        Positioned.fill(
          child: GestureDetector(
            onTap: () => overlayEntry.remove(),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu
        Positioned(
          left: position.dx,
          top: position.dy,
          child: ContextMenu(
            items: items,
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ],
    ),
  );

  overlay.insert(overlayEntry);
}

/// Color picker menu for task color change
class ColorPickerMenu extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final VoidCallback onDismiss;

  const ColorPickerMenu({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    required this.onDismiss,
  });

  static const List<Color> _colors = [
    AppColors.categoryFoundation,
    AppColors.categoryStructure,
    AppColors.categoryElectrical,
    AppColors.categoryPlumbing,
    AppColors.categoryFinishing,
    AppColors.categoryInspection,
    AppColors.industrialOrange,
    AppColors.safetyYellow,
    AppColors.constructionGreen,
    AppColors.constructionRed,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '色を選択',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              final isSelected = color.value == selectedColor.value;
              return GestureDetector(
                onTap: () {
                  onColorSelected(color);
                  onDismiss();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
