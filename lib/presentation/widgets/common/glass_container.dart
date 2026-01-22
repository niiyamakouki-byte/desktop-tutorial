import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Glassmorphism container with backdrop blur effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurAmount;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool isDarkMode;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blurAmount = 20,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ??
                  (isDarkMode ? AppColors.glassDark : AppColors.glassWhite),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ??
                    (isDarkMode
                        ? AppColors.glassBorderDark
                        : AppColors.glassBorderLight),
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism button with hover effects
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isDarkMode;
  final bool isWarning;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.isDarkMode = false,
    this.isWarning = false,
    this.isPrimary = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.isPrimary) {
      return widget.isDarkMode
          ? AppColors.primaryDarkMode.withOpacity(0.3)
          : AppColors.primary.withOpacity(0.15);
    }
    if (widget.isWarning) {
      return AppColors.industrialOrange.withOpacity(0.2);
    }
    return widget.isDarkMode ? AppColors.glassDark : AppColors.glassWhite;
  }

  Color _getBorderColor() {
    if (widget.isPrimary) {
      return widget.isDarkMode
          ? AppColors.primaryDarkMode.withOpacity(0.5)
          : AppColors.primary.withOpacity(0.3);
    }
    if (widget.isWarning) {
      return AppColors.industrialOrange.withOpacity(0.5);
    }
    return _isHovered
        ? AppColors.glassBorderLight
        : (widget.isDarkMode
            ? AppColors.glassBorderDark
            : AppColors.glassBorder);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: _getBorderColor(),
                    width: _isHovered ? 1.5 : 1,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: (widget.isWarning
                                    ? AppColors.industrialOrange
                                    : AppColors.primary)
                                .withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Monospace number text widget for instrument-like display
class MonospaceNumber extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;

  const MonospaceNumber({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.color,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
        letterSpacing: 0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Industrial style alert banner
class IndustrialAlert extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final AlertType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const IndustrialAlert({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.type = AlertType.warning,
    this.onDismiss,
    this.onAction,
    this.actionText,
  });

  Color get _backgroundColor {
    switch (type) {
      case AlertType.warning:
        return AppColors.safetyYellowLight;
      case AlertType.danger:
        return AppColors.industrialOrangeLight;
      case AlertType.critical:
        return AppColors.errorLight;
      case AlertType.info:
        return AppColors.infoLight;
      case AlertType.success:
        return AppColors.successLight;
    }
  }

  Color get _accentColor {
    switch (type) {
      case AlertType.warning:
        return AppColors.safetyYellow;
      case AlertType.danger:
        return AppColors.industrialOrange;
      case AlertType.critical:
        return AppColors.constructionRed;
      case AlertType.info:
        return AppColors.info;
      case AlertType.success:
        return AppColors.constructionGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              height: 72,
              color: _accentColor,
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: _accentColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            if (onAction != null) ...[
              GlassButton(
                onTap: onAction,
                isWarning: type == AlertType.warning || type == AlertType.danger,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  actionText ?? '対応',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, size: 18, color: _accentColor),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

enum AlertType { warning, danger, critical, info, success }
