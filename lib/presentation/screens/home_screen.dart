import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/services/project_provider.dart';
import '../../data/services/order_service.dart';
import '../../data/services/batch_notification_service.dart';
import '../../data/models/material_model.dart';
import '../widgets/gantt/gantt_chart.dart';
import '../widgets/chat/communication_sidebar.dart';
import '../widgets/common/dark_mode_toggle.dart';
import '../widgets/modal/task_edit_modal.dart';
import '../widgets/modal/team_member_management_dialog.dart';
import '../widgets/modal/notification_center_dialog.dart';
import '../widgets/templates/template_panel.dart';
import '../widgets/order/order_dashboard.dart';
import 'cockpit_dashboard.dart';
import 'project_report_screen.dart';

/// View mode enum for main screen
enum HomeViewMode { gantt, cockpit }

/// Main home screen with Gantt chart and communication sidebar
class HomeScreen extends StatefulWidget {
  final String? projectId;
  final String? projectName;
  final VoidCallback? onBackToProjects;

  const HomeScreen({
    super.key,
    this.projectId,
    this.projectName,
    this.onBackToProjects,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  HomeViewMode _viewMode = HomeViewMode.gantt;
  late OrderService _orderService;
  late BatchNotificationService _notificationService;

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

    // Initialize OrderService
    _orderService = OrderService();
    _orderService.initialize();
    _notificationService = BatchNotificationService();
    _notificationService.initialize();

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().initialize();
      // Start with sidebar open
      _sidebarController.forward();
    });
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _orderService.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  void _setViewMode(HomeViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  void _handleNavigation(String view) {
    switch (view) {
      case 'gantt':
        _setViewMode(HomeViewMode.gantt);
        break;
      case 'cockpit':
        _setViewMode(HomeViewMode.cockpit);
        break;
      case 'orders':
        _showOrdersDialog();
        break;
      case 'templates':
        _showTemplatesDialog();
        break;
    }
  }

  void _showOrdersDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '発注管理',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: OrderDashboard(
                  alerts: _orderService.alerts,
                  pendingMaterials: _orderService.taskConstructionMaterials
                      .where((m) => m.orderStatus == OrderStatus.notOrdered)
                      .toList(),
                  recentOrders: _orderService.purchaseOrders,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplatesDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'テンプレート・プロンプト',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: TemplatePanel(
                  onApplyProjectTemplate: (templateId) async {
                    final provider = context.read<ProjectProvider>();
                    final success = await provider.applyProjectTemplate(
                      templateId,
                      startDate: provider.projectStartDate,
                      replaceExisting: false,
                    );
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('工程テンプレートを適用しました'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSidebar(bool isOpen) {
    if (isOpen) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  void _showTaskEditModal(BuildContext context, task) {
    final provider = context.read<ProjectProvider>();
    TaskEditModal.show(
      context: context,
      task: task,
      projectId: provider.currentProject?.id ?? 'default',
      availableUsers: provider.users,
    ).then((updatedTask) {
      if (updatedTask != null) {
        provider.updateTask(updatedTask);
      }
    });
  }

  void _openProjectReport() {
    final provider = context.read<ProjectProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectReportScreen(
          projectName: widget.projectName ?? provider.currentProject?.name ?? 'プロジェクト',
          tasks: provider.tasks,
        ),
      ),
    );
  }

  void _openTeamMemberManagement() {
    final provider = context.read<ProjectProvider>();
    TeamMemberManagementDialog.show(
      context: context,
      provider: provider,
    );
  }

  void _openNotificationCenter() {
    final provider = context.read<ProjectProvider>();
    final projectId = provider.currentProject?.id ?? widget.projectId ?? 'default';
    final recipients = provider.users
        .map(
          (user) => NotificationRecipient(
            id: user.id,
            name: user.name,
            lineUid: user.id,
            phoneNumber: user.phone,
          ),
        )
        .toList();
    NotificationCenterDialog.show(
      context: context,
      service: _notificationService,
      projectId: projectId,
      recipients: recipients,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          final isMobile = MediaQuery.of(context).size.width < 960;
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 8),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                // App Header with back button
                _buildAppHeader(),
                // View Mode Tabs
                _buildViewTabs(),
                // Main Content Area
                Expanded(
                  child: Row(
                    children: [
                      // Main content based on view mode
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _viewMode == HomeViewMode.gantt
                              ? GanttChart(
                                  key: const ValueKey('gantt-view'),
                                  tasks: provider.tasks,
                                  selectedTaskId: provider.selectedTask?.id,
                                  onTaskSelected: (task) => provider.selectTask(task),
                                  onTaskDoubleTap: (task) => _showTaskEditModal(context, task),
                                  onTaskExpandToggle: (task, isExpanded) =>
                                      provider.toggleTaskExpansion(task.id),
                                  timelineStartDate: provider.projectStartDate,
                                  timelineEndDate: provider.projectEndDate,
                                  dependencies: provider.dependencies,
                                  dependencyService: provider.dependencyService,
                                  criticalPathIds: provider.criticalPathIds,
                                  showCriticalPath: provider.showCriticalPath,
                                  largeProjectMode: provider.largeProjectMode,
                                  onDependencyCreated: (fromId, toId, type, lag) {
                                    provider.addDependency(
                                      fromTaskId: fromId,
                                      toTaskId: toId,
                                      type: type,
                                      lagDays: lag,
                                    );
                                  },
                                  onDependencyDeleted: (depId) {
                                    provider.removeDependency(depId);
                                  },
                                  onRainCancel: (result) {
                                    provider.applyRainCancellation(result);
                                  },
                                )
                              : CockpitDashboard(
                                  key: const ValueKey('cockpit-view'),
                                  orderService: _orderService,
                                  tasks: provider.tasks,
                                  onNavigate: _handleNavigation,
                                  dependencyService: provider.dependencyService,
                                  dependencies: provider.dependencies,
                                ),
                        ),
                      ),
                      // Communication Sidebar with animation
                      if (!isMobile)
                        AnimatedBuilder(
                          animation: _sidebarAnimation,
                          builder: (context, child) {
                            final sidebarWidth =
                                AppConstants.sidebarWidth * _sidebarAnimation.value;
                            if (sidebarWidth < 1) return const SizedBox.shrink();

                            return SizedBox(
                              width: sidebarWidth,
                              child: ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment.centerLeft,
                                  maxWidth: AppConstants.sidebarWidth,
                                  child: provider.currentProject != null &&
                                          provider.currentUser != null
                                      ? CommunicationSidebar(
                                          isOpen: provider.isSidebarOpen,
                                          project: provider.currentProject!,
                                          currentUser: provider.currentUser!,
                                          messages: provider.messages,
                                          documents: provider.pinnedAttachments,
                                          onClose: () {
                                            provider.toggleSidebar();
                                            _toggleSidebar(false);
                                          },
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Floating action button to toggle sidebar
      floatingActionButton: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          final isMobile = MediaQuery.of(context).size.width < 960;
          return FloatingActionButton(
            onPressed: () {
              if (isMobile) {
                if (provider.currentProject == null || provider.currentUser == null) {
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.88,
                    child: CommunicationSidebar(
                      isOpen: true,
                      project: provider.currentProject!,
                      currentUser: provider.currentUser!,
                      messages: provider.messages,
                      documents: provider.pinnedAttachments,
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                );
              } else {
                provider.toggleSidebar();
                _toggleSidebar(!provider.isSidebarOpen);
              }
            },
            backgroundColor: theme.colorScheme.primary,
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

  Widget _buildAppHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final iconColor = colorScheme.onSurface.withOpacity(0.72);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.45)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          if (widget.onBackToProjects != null)
            IconButton(
              onPressed: widget.onBackToProjects,
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              tooltip: 'プロジェクト一覧に戻る',
            ),
          if (widget.onBackToProjects != null)
            const SizedBox(width: 8),
          // Project info
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.industrialGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.construction, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectName ?? '建設プロジェクト管理',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.projectId != null)
                  Text(
                    'ID: ${widget.projectId}',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Actions
          IconButton(
            onPressed: _openProjectReport,
            icon: Icon(Icons.summarize_outlined, color: iconColor),
            tooltip: '進捗レポート',
          ),
          IconButton(
            onPressed: _openNotificationCenter,
            icon: Icon(Icons.notifications_outlined, color: iconColor),
            tooltip: '通知',
          ),
          IconButton(
            onPressed: _openTeamMemberManagement,
            icon: Icon(Icons.groups_outlined, color: iconColor),
            tooltip: 'メンバー管理',
          ),
          const CompactDarkModeToggle(),
          IconButton(
            onPressed: () {},
            icon: Icon(
              isDark ? Icons.settings_suggest_outlined : Icons.settings_outlined,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTabs() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
        children: [
          _ViewTab(
            icon: Icons.view_timeline_outlined,
            label: '工程表',
            isSelected: _viewMode == HomeViewMode.gantt,
            onTap: () => _setViewMode(HomeViewMode.gantt),
          ),
          const SizedBox(width: 4),
          _ViewTab(
            icon: Icons.dashboard_outlined,
            label: 'コックピット',
            isSelected: _viewMode == HomeViewMode.cockpit,
            onTap: () => _setViewMode(HomeViewMode.cockpit),
            badge: _orderService.criticalAlerts.isNotEmpty
                ? _orderService.criticalAlerts.length
                : null,
          ),
        ],
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;

  const _ViewTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: activeColor.withOpacity(0.35))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.constructionRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
