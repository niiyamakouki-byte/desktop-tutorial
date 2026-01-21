import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import 'user_avatar.dart';

/// Sidebar header displaying project name and team members
/// Shows project title, member avatars, and online status count
class SidebarHeader extends StatelessWidget {
  final Project project;
  final VoidCallback? onClose;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onMembersTap;

  const SidebarHeader({
    super.key,
    required this.project,
    this.onClose,
    this.onSettingsTap,
    this.onMembersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.sidebarGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            _buildProjectInfo(),
            _buildMembersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingS,
        vertical: AppConstants.paddingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close,
              color: AppColors.textOnPrimary,
            ),
            iconSize: AppConstants.iconSizeL,
            tooltip: '閉じる',
          ),
          Row(
            children: [
              IconButton(
                onPressed: onSettingsTap,
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.textOnPrimary,
                ),
                iconSize: AppConstants.iconSizeM,
                tooltip: '設定',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(project.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  _getStatusLabel(project.status),
                  style: TextStyle(
                    color: _getStatusColor(project.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            project.name,
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.textTertiary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  project.location,
                  style: TextStyle(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    final onlineCount = project.members.where((m) => m.isOnline).length;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onMembersTap,
              child: Row(
                children: [
                  StackedAvatars(
                    users: project.members,
                    avatarSize: AppConstants.avatarSizeS,
                    maxVisible: 5,
                    overlap: 10,
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${project.members.length}名のメンバー',
                        style: TextStyle(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.chatOnline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$onlineCount名がオンライン',
                            style: TextStyle(
                              color: AppColors.textOnPrimary.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onMembersTap,
            icon: const Icon(
              Icons.chevron_right,
              color: AppColors.textOnPrimary,
            ),
            tooltip: 'メンバー一覧',
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case ProjectStatus.planning:
        return AppColors.info;
      case ProjectStatus.inProgress:
        return AppColors.success;
      case ProjectStatus.onHold:
        return AppColors.warning;
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  String _getStatusLabel(String status) {
    return ProjectStatus.getLabel(status);
  }
}

/// Compact version of the sidebar header for collapsed states
class CompactSidebarHeader extends StatelessWidget {
  final Project project;
  final VoidCallback? onExpand;

  const CompactSidebarHeader({
    super.key,
    required this.project,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onExpand,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: const BoxDecoration(
          gradient: AppColors.sidebarGradient,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StackedAvatars(
                        users: project.members,
                        avatarSize: 20,
                        maxVisible: 3,
                        overlap: 8,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${project.members.length}名',
                        style: TextStyle(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textOnPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
