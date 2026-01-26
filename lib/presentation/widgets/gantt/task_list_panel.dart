import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/phase_model.dart';
import 'gantt_constants.dart';
import 'task_row.dart';

/// クイックフィルターの種類
enum QuickFilterType {
  /// 今日のタスク
  today('today', '今日', Icons.today),

  /// 遅延タスク
  delayed('delayed', '遅延', Icons.warning_amber),

  /// 待ち状態タスク
  blocked('blocked', '待ち', Icons.hourglass_empty),

  /// 自分のタスク（担当）
  mine('mine', '自分', Icons.person);

  final String value;
  final String label;
  final IconData icon;

  const QuickFilterType(this.value, this.label, this.icon);
}

/// クイックフィルターバー
class QuickFilterBar extends StatelessWidget {
  final Set<QuickFilterType> activeFilters;
  final Function(QuickFilterType filter) onFilterToggle;
  final VoidCallback? onClearAll;

  /// フィルター対象のタスク数情報
  final int todayCount;
  final int delayedCount;
  final int blockedCount;
  final int mineCount;

  const QuickFilterBar({
    super.key,
    required this.activeFilters,
    required this.onFilterToggle,
    this.onClearAll,
    this.todayCount = 0,
    this.delayedCount = 0,
    this.blockedCount = 0,
    this.mineCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildFilterChip(
            QuickFilterType.today,
            todayCount,
            AppColors.primary,
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            QuickFilterType.delayed,
            delayedCount,
            AppColors.error,
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            QuickFilterType.blocked,
            blockedCount,
            AppColors.warning,
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            QuickFilterType.mine,
            mineCount,
            AppColors.success,
          ),
          if (activeFilters.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildClearButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(QuickFilterType filter, int count, Color color) {
    final isActive = activeFilters.contains(filter);

    return GestureDetector(
      onTap: () => onFilterToggle(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              size: 12,
              color: isActive ? color : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              filter.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? color : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? color : AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: onClearAll,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.textTertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.close,
          size: 14,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// タスクフィルタリングユーティリティ
class TaskFilterUtils {
  TaskFilterUtils._();

  /// フィルタを適用してタスクをフィルタリング
  static List<Task> applyFilters(
    List<Task> tasks,
    Set<QuickFilterType> activeFilters, {
    String? currentUserId,
  }) {
    if (activeFilters.isEmpty) return tasks;

    return tasks.where((task) {
      // OR条件: いずれかのフィルタに一致すればOK
      for (final filter in activeFilters) {
        if (_matchesFilter(task, filter, currentUserId: currentUserId)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  static bool _matchesFilter(
    Task task,
    QuickFilterType filter, {
    String? currentUserId,
  }) {
    switch (filter) {
      case QuickFilterType.today:
        return task.isToday;
      case QuickFilterType.delayed:
        return task.delayStatus == DelayStatus.overdue ||
               task.delayStatus == DelayStatus.atRisk;
      case QuickFilterType.blocked:
        return task.delayStatus == DelayStatus.blocked;
      case QuickFilterType.mine:
        if (currentUserId != null) {
          return task.assignees.any((a) => a.id == currentUserId);
        }
        // currentUserIdがない場合は担当者が設定されているタスクを表示
        return task.assignees.isNotEmpty ||
               task.assigneeName != null;
    }
  }

  /// 各フィルタに一致するタスク数を計算
  static Map<QuickFilterType, int> calculateFilterCounts(
    List<Task> tasks, {
    String? currentUserId,
  }) {
    final counts = <QuickFilterType, int>{};
    for (final filter in QuickFilterType.values) {
      counts[filter] = tasks.where((task) =>
        _matchesFilter(task, filter, currentUserId: currentUserId)
      ).length;
    }
    return counts;
  }
}

/// Left panel showing the hierarchical task tree
class TaskListPanel extends StatelessWidget {
  final List<Task> tasks;
  final List<Task> allTasks;
  final String? selectedTaskId;
  final ScrollController scrollController;
  final double width;
  final Function(Task task)? onTaskTap;
  final Function(Task task)? onTaskDoubleTap;
  final Function(Task task)? onExpandToggle;

  /// Map of phaseId -> Phase for displaying phase badges
  final Map<String, Phase> phaseMap;

  const TaskListPanel({
    super.key,
    required this.tasks,
    required this.allTasks,
    this.selectedTaskId,
    required this.scrollController,
    this.width = GanttConstants.taskListWidth,
    this.onTaskTap,
    this.onTaskDoubleTap,
    this.onExpandToggle,
    this.phaseMap = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.ganttBackground,
        border: Border(
          right: BorderSide(
            color: AppColors.border,
            width: GanttConstants.dividerWidth,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Task list
          Expanded(
            child: _buildTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: GanttConstants.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: GanttConstants.cellPadding),
      decoration: BoxDecoration(
        color: AppColors.ganttHeaderBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'タスク名',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ganttHeaderText,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '進捗',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ganttHeaderText.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      controller: scrollController,
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final hasChildren = allTasks.hasChildren(task.id);

        return TaskRow(
          task: task,
          hasChildren: hasChildren,
          isSelected: task.id == selectedTaskId,
          width: width,
          onTap: () => onTaskTap?.call(task),
          onDoubleTap: () => onTaskDoubleTap?.call(task),
          onExpandToggle: () => onExpandToggle?.call(task),
          phase: task.phaseId != null ? phaseMap[task.phaseId] : null,
        );
      },
    );
  }
}

/// Header for the task list panel with column titles and actions
class TaskListHeader extends StatelessWidget {
  final double width;
  final VoidCallback? onExpandAll;
  final VoidCallback? onCollapseAll;

  const TaskListHeader({
    super.key,
    this.width = GanttConstants.taskListWidth,
    this.onExpandAll,
    this.onCollapseAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: GanttConstants.headerHeight,
      decoration: BoxDecoration(
        color: AppColors.ganttHeaderBg,
        border: Border(
          right: BorderSide(
            color: AppColors.ganttHeaderBg,
            width: GanttConstants.dividerWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: GanttConstants.cellPadding),
          // Expand/Collapse buttons
          _buildHeaderButton(
            icon: Icons.unfold_more,
            tooltip: '全て展開',
            onPressed: onExpandAll,
          ),
          _buildHeaderButton(
            icon: Icons.unfold_less,
            tooltip: '全て折りたたむ',
            onPressed: onCollapseAll,
          ),
          const SizedBox(width: 8),
          // Column title
          const Expanded(
            child: Text(
              'タスク名',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ganttHeaderText,
              ),
            ),
          ),
          // Progress column
          SizedBox(
            width: 60,
            child: Text(
              '進捗',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ganttHeaderText.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: GanttConstants.cellPadding),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.ganttHeaderText.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

/// Resizable divider between task list and timeline panels
class PanelDivider extends StatefulWidget {
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  final Function(double newWidth)? onWidthChanged;

  const PanelDivider({
    super.key,
    this.initialWidth = GanttConstants.taskListWidth,
    this.minWidth = 200,
    this.maxWidth = 500,
    this.onWidthChanged,
  });

  @override
  State<PanelDivider> createState() => _PanelDividerState();
}

class _PanelDividerState extends State<PanelDivider> {
  bool _isDragging = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        onHorizontalDragUpdate: (details) {
          final newWidth = (widget.initialWidth + details.delta.dx)
              .clamp(widget.minWidth, widget.maxWidth);
          widget.onWidthChanged?.call(newWidth);
        },
        child: AnimatedContainer(
          duration: GanttConstants.hoverDuration,
          width: GanttConstants.resizerWidth,
          color: _isDragging || _isHovered
              ? AppColors.primary.withOpacity(0.3)
              : Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: GanttConstants.hoverDuration,
              width: 2,
              height: _isDragging || _isHovered ? 40 : 24,
              decoration: BoxDecoration(
                color: _isDragging
                    ? AppColors.primary
                    : (_isHovered
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.border),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state widget for when there are no tasks
class EmptyTaskList extends StatelessWidget {
  final VoidCallback? onAddTask;

  const EmptyTaskList({
    super.key,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'タスクがありません',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'プロジェクトにタスクを追加してください',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
          if (onAddTask != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('タスクを追加'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Summary row showing total progress
class TaskListSummary extends StatelessWidget {
  final List<Task> tasks;
  final double width;

  const TaskListSummary({
    super.key,
    required this.tasks,
    this.width = GanttConstants.taskListWidth,
  });

  @override
  Widget build(BuildContext context) {
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.status == 'completed').length;
    final averageProgress = tasks.isEmpty
        ? 0.0
        : tasks.map((t) => t.progress).reduce((a, b) => a + b) / tasks.length;

    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: GanttConstants.cellPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
          right: BorderSide(
            color: AppColors.border,
            width: GanttConstants.dividerWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.summarize_outlined,
            size: 16,
            color: AppColors.iconDefault,
          ),
          const SizedBox(width: 8),
          Text(
            '合計: $totalTasks タスク',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '完了: $completedTasks',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(averageProgress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
