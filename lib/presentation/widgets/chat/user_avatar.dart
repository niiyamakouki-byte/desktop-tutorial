import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';

/// User avatar component with online status indicator
/// Displays user's avatar image or initials with optional online/offline badge
class UserAvatar extends StatelessWidget {
  final User user;
  final double size;
  final bool showOnlineIndicator;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = AppConstants.avatarSizeM,
    this.showOnlineIndicator = true,
    this.onTap,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildAvatar(),
          if (showOnlineIndicator) _buildOnlineIndicator(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
            ? Image.network(
                user.avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildInitialsAvatar();
                },
              )
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        user.initials,
        style: TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    final indicatorSize = size * 0.3;
    final indicatorOffset = size * 0.05;

    return Positioned(
      right: indicatorOffset,
      bottom: indicatorOffset,
      child: Container(
        width: indicatorSize,
        height: indicatorSize,
        decoration: BoxDecoration(
          color: user.isOnline ? AppColors.chatOnline : AppColors.chatOffline,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.surface,
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Stacked avatars widget for displaying multiple team members
class StackedAvatars extends StatelessWidget {
  final List<User> users;
  final double avatarSize;
  final double overlap;
  final int maxVisible;
  final VoidCallback? onTap;

  const StackedAvatars({
    super.key,
    required this.users,
    this.avatarSize = AppConstants.avatarSizeS,
    this.overlap = 8.0,
    this.maxVisible = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.take(maxVisible).toList();
    final remainingCount = users.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: avatarSize,
        width: _calculateWidth(visibleUsers.length, remainingCount > 0),
        child: Stack(
          children: [
            ...visibleUsers.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              return Positioned(
                left: index * (avatarSize - overlap),
                child: UserAvatar(
                  user: user,
                  size: avatarSize,
                  showOnlineIndicator: false,
                  borderColor: AppColors.surface,
                  borderWidth: 2,
                ),
              );
            }),
            if (remainingCount > 0)
              Positioned(
                left: visibleUsers.length * (avatarSize - overlap),
                child: _buildRemainingCounter(remainingCount),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateWidth(int count, bool hasRemaining) {
    final itemCount = hasRemaining ? count + 1 : count;
    if (itemCount == 0) return 0;
    return avatarSize + (itemCount - 1) * (avatarSize - overlap);
  }

  Widget _buildRemainingCounter(int count) {
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.surface,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: avatarSize * 0.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
