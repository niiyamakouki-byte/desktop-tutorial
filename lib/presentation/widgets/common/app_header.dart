import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/services/project_provider.dart';
import '../modal/data_backup_dialog.dart';
import 'dark_mode_toggle.dart';

/// Application header with project info and navigation
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final project = provider.currentProject;

        return Container(
          height: 64,
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo / App Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.construction,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
              ),

              // Project Name
              if (project != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingL,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            project.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Project progress indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 100,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _calculateOverallProgress(provider.tasks),
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.success,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(_calculateOverallProgress(provider.tasks) * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingL,
                ),
                child: Row(
                  children: [
                    // Today button
                    _HeaderButton(
                      icon: Icons.today,
                      label: '今日',
                      onPressed: () {
                        // TODO: Scroll to today
                      },
                    ),
                    const SizedBox(width: 8),
                    // Zoom controls
                    _HeaderButton(
                      icon: Icons.zoom_in,
                      onPressed: () {
                        // TODO: Zoom in
                      },
                    ),
                    const SizedBox(width: 4),
                    _HeaderButton(
                      icon: Icons.zoom_out,
                      onPressed: () {
                        // TODO: Zoom out
                      },
                    ),
                    const SizedBox(width: 16),
                    // Backup button
                    _HeaderButton(
                      icon: Icons.backup_outlined,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const DataBackupDialog(),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Dark mode toggle
                    const CompactDarkModeToggle(),
                    const SizedBox(width: 8),
                    // Settings
                    _HeaderButton(
                      icon: Icons.settings_outlined,
                      onPressed: () {
                        // TODO: Open settings
                      },
                    ),
                    const SizedBox(width: 8),
                    // User profile
                    if (provider.currentUser != null)
                      _UserAvatar(user: provider.currentUser!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateOverallProgress(List tasks) {
    if (tasks.isEmpty) return 0.0;
    final rootTasks = tasks.where((t) => t.parentId == null).toList();
    if (rootTasks.isEmpty) return 0.0;
    final total = rootTasks.fold<double>(
      0.0,
      (sum, task) => sum + task.progress,
    );
    return total / rootTasks.length;
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;

  const _HeaderButton({
    required this.icon,
    this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white70,
                size: 20,
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final dynamic user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white30,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
