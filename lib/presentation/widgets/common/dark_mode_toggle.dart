import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';

/// Dark mode toggle button with smooth animation
class DarkModeToggle extends StatefulWidget {
  final double size;

  const DarkModeToggle({
    super.key,
    this.size = 40,
  });

  @override
  State<DarkModeToggle> createState() => _DarkModeToggleState();
}

class _DarkModeToggleState extends State<DarkModeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    // Update animation based on theme
    if (isDark && _controller.value == 0) {
      _controller.forward();
    } else if (!isDark && _controller.value == 1) {
      _controller.reverse();
    }

    return Tooltip(
      message: isDark ? 'ライトモードに切り替え' : 'ダークモードに切り替え',
      child: GestureDetector(
        onTap: () {
          if (isDark) {
            _controller.reverse();
          } else {
            _controller.forward();
          }
          themeProvider.toggleTheme();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  border: Border.all(
                    color: isDark
                        ? AppColors.glassBorderDark
                        : AppColors.glassBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.primaryDarkMode.withOpacity(0.2)
                          : AppColors.safetyYellow.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sun icon
                    Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159,
                      child: Opacity(
                        opacity: 1 - _rotationAnimation.value,
                        child: Icon(
                          Icons.wb_sunny_rounded,
                          size: widget.size * 0.5,
                          color: AppColors.safetyYellow,
                        ),
                      ),
                    ),
                    // Moon icon
                    Transform.rotate(
                      angle: (_rotationAnimation.value - 0.5) * 3.14159,
                      child: Opacity(
                        opacity: _rotationAnimation.value,
                        child: Icon(
                          Icons.nightlight_round,
                          size: widget.size * 0.5,
                          color: AppColors.primaryDarkMode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Compact dark mode toggle for toolbar
class CompactDarkModeToggle extends StatelessWidget {
  const CompactDarkModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return IconButton(
      onPressed: () => themeProvider.toggleTheme(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
          color: isDark ? AppColors.safetyYellow : AppColors.primary,
        ),
      ),
      tooltip: isDark ? 'ライトモードに切り替え' : 'ダークモードに切り替え',
    );
  }
}
