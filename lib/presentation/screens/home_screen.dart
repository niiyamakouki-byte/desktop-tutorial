import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/project_provider.dart';
import '../widgets/gantt/gantt_chart.dart';
import '../widgets/chat/communication_sidebar.dart';
import '../widgets/common/app_header.dart';

/// Main home screen with Gantt chart and communication sidebar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      duration: AppConstants.sidebarAnimationDuration,
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOut,
    );

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  void _toggleSidebar(bool isOpen) {
    if (isOpen) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          // Sync animation with provider state
          if (provider.isSidebarOpen && !_sidebarController.isCompleted) {
            _sidebarController.forward();
          } else if (!provider.isSidebarOpen && _sidebarController.value > 0) {
            _sidebarController.reverse();
          }

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // App Header
              const AppHeader(),
              // Main Content Area
              Expanded(
                child: Row(
                  children: [
                    // Gantt Chart Area (expands to fill available space)
                    Expanded(
                      child: GanttChart(
                        tasks: provider.tasks,
                        onTaskTap: (task) => provider.selectTask(task),
                        onTaskExpand: (taskId) =>
                            provider.toggleTaskExpansion(taskId),
                        onTaskUpdate: (task) => provider.updateTask(task),
                        projectStartDate: provider.projectStartDate,
                        projectEndDate: provider.projectEndDate,
                      ),
                    ),
                    // Communication Sidebar with animation
                    AnimatedBuilder(
                      animation: _sidebarAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: AppConstants.sidebarWidth *
                              _sidebarAnimation.value,
                          child: _sidebarAnimation.value > 0.1
                              ? ClipRect(
                                  child: OverflowBox(
                                    alignment: Alignment.centerLeft,
                                    maxWidth: AppConstants.sidebarWidth,
                                    child: const CommunicationSidebar(),
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // Floating action button to toggle sidebar
      floatingActionButton: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton(
            onPressed: () {
              provider.toggleSidebar();
              _toggleSidebar(!provider.isSidebarOpen);
            },
            backgroundColor: AppColors.primary,
            tooltip: provider.isSidebarOpen ? 'サイドバーを閉じる' : 'サイドバーを開く',
            child: AnimatedBuilder(
              animation: _sidebarAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _sidebarAnimation.value > 0.5
                          ? Icons.chevron_right
                          : Icons.chat_bubble_outline,
                      color: Colors.white,
                    ),
                    if (provider.unreadMessageCount > 0 &&
                        _sidebarAnimation.value < 0.5)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.chatUnread,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${provider.unreadMessageCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
