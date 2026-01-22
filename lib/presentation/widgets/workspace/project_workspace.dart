import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../state/workspace_state.dart';

/// プロジェクトワークスペース
///
/// 3カラムレイアウト（Desktop/Tablet）を管理
/// - 左: タスクナビゲーター
/// - 中央: ガントチャート
/// - 右: コンテキストパネル
class ProjectWorkspace extends StatefulWidget {
  final String projectId;
  final Project project;
  final List<Task> tasks;
  final List<Dependency> dependencies;
  final Permissions permissions;

  /// 左カラムビルダー
  final Widget Function(BuildContext context, ProjectWorkspaceController controller) leftBuilder;

  /// 中央カラムビルダー
  final Widget Function(BuildContext context, ProjectWorkspaceController controller) centerBuilder;

  /// 右カラムビルダー
  final Widget Function(BuildContext context, ProjectWorkspaceController controller) rightBuilder;

  const ProjectWorkspace({
    super.key,
    required this.projectId,
    required this.project,
    required this.tasks,
    required this.dependencies,
    this.permissions = Permissions.all,
    required this.leftBuilder,
    required this.centerBuilder,
    required this.rightBuilder,
  });

  @override
  State<ProjectWorkspace> createState() => _ProjectWorkspaceState();
}

class _ProjectWorkspaceState extends State<ProjectWorkspace> {
  late ProjectWorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProjectWorkspaceController(
      initialState: ProjectWorkspaceState(
        ganttView: GanttViewState(
          rangeStart: DateTime.now().subtract(const Duration(days: 7)),
          rangeEnd: DateTime.now().add(const Duration(days: 60)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;

        if (isMobile) {
          return _buildMobileLayout(context);
        }

        return _buildDesktopLayout(context, isTablet);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isTablet) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final leftWidth = isTablet ? 240.0 : 280.0;
        final rightWidth = state.isRightOpen ? (isTablet ? 320.0 : 360.0) : 0.0;

        return Row(
          children: [
            // 左カラム: タスクナビゲーター
            SizedBox(
              width: leftWidth,
              child: widget.leftBuilder(context, _controller),
            ),

            // 区切り線
            Container(
              width: 1,
              color: AppColors.border,
            ),

            // 中央: ガントチャート
            Expanded(
              child: widget.centerBuilder(context, _controller),
            ),

            // 区切り線
            if (state.isRightOpen)
              Container(
                width: 1,
                color: AppColors.border,
              ),

            // 右カラム: コンテキストパネル
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: rightWidth,
              child: state.isRightOpen
                  ? widget.rightBuilder(context, _controller)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return MobileProjectWorkspace(
          controller: _controller,
          leftBuilder: widget.leftBuilder,
          centerBuilder: widget.centerBuilder,
          rightBuilder: widget.rightBuilder,
        );
      },
    );
  }
}

/// モバイル用ワークスペース（タブ分割）
class MobileProjectWorkspace extends StatefulWidget {
  final ProjectWorkspaceController controller;
  final Widget Function(BuildContext, ProjectWorkspaceController) leftBuilder;
  final Widget Function(BuildContext, ProjectWorkspaceController) centerBuilder;
  final Widget Function(BuildContext, ProjectWorkspaceController) rightBuilder;

  const MobileProjectWorkspace({
    super.key,
    required this.controller,
    required this.leftBuilder,
    required this.centerBuilder,
    required this.rightBuilder,
  });

  @override
  State<MobileProjectWorkspace> createState() => _MobileProjectWorkspaceState();
}

class _MobileProjectWorkspaceState extends State<MobileProjectWorkspace>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _previousSelectedTaskHashCode = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // タスク選択時に詳細タブへ自動遷移
    final currentHash = widget.controller.state.selection.selectedTaskId?.hashCode ?? 0;
    if (currentHash != _previousSelectedTaskHashCode &&
        widget.controller.state.selection.hasSelection) {
      _tabController.animateTo(2); // 詳細タブへ
    }
    _previousSelectedTaskHashCode = currentHash;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // タブバー
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.list_alt), text: 'タスク'),
              Tab(icon: Icon(Icons.bar_chart), text: 'ガント'),
              Tab(icon: Icon(Icons.info_outline), text: '詳細'),
            ],
          ),
        ),

        // タブコンテンツ
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              widget.leftBuilder(context, widget.controller),
              widget.centerBuilder(context, widget.controller),
              widget.rightBuilder(context, widget.controller),
            ],
          ),
        ),
      ],
    );
  }
}

/// ワークスペース状態コントローラー
///
/// 左・中・右の状態を一元管理し、同期を保証
class ProjectWorkspaceController extends ChangeNotifier {
  ProjectWorkspaceState _state;

  ProjectWorkspaceController({
    required ProjectWorkspaceState initialState,
  }) : _state = initialState;

  ProjectWorkspaceState get state => _state;

  /// タスク選択（最重要：左・中・右の同期）
  void selectTask(String? taskId) {
    if (taskId == null) {
      _state = _state.copyWith(
        selection: const SelectionState(),
        rightMode: RightPanelMode.project,
      );
    } else {
      _state = _state.copyWith(
        selection: SelectionState(
          selectedTaskId: taskId,
          delayTraceEnabled: false,
        ),
        rightMode: RightPanelMode.task,
        isRightOpen: true,
      );
    }
    notifyListeners();
  }

  /// 遅延追跡モード切替
  void toggleDelayTrace(bool enabled) {
    if (!_state.selection.hasSelection) return;

    _state = _state.copyWith(
      selection: _state.selection.copyWith(delayTraceEnabled: enabled),
      rightMode: enabled ? RightPanelMode.delayTrace : RightPanelMode.task,
    );
    notifyListeners();
  }

  /// 右パネルの開閉
  void toggleRightPanel([bool? open]) {
    _state = _state.copyWith(
      isRightOpen: open ?? !_state.isRightOpen,
    );
    notifyListeners();
  }

  /// プロジェクトモードに戻る
  void backToProject() {
    _state = _state.copyWith(
      selection: const SelectionState(),
      rightMode: RightPanelMode.project,
    );
    notifyListeners();
  }

  /// 右パネルのピン留め
  void pinRightPanel(bool pinned) {
    _state = _state.copyWith(pinnedRightPanel: pinned);
    notifyListeners();
  }

  /// フィルター変更
  void updateFilters(TaskFilters Function(TaskFilters) updater) {
    _state = _state.copyWith(filters: updater(_state.filters));
    notifyListeners();
  }

  /// ソート変更
  void updateSort(TaskSort sort) {
    _state = _state.copyWith(sort: sort);
    notifyListeners();
  }

  /// ガント表示変更
  void updateGanttView(GanttViewState Function(GanttViewState) updater) {
    _state = _state.copyWith(ganttView: updater(_state.ganttView));
    notifyListeners();
  }

  /// 範囲変更
  void panRange(DateTime start, DateTime end) {
    _state = _state.copyWith(
      ganttView: _state.ganttView.copyWith(rangeStart: start, rangeEnd: end),
    );
    notifyListeners();
  }

  /// ズーム変更
  void setZoom(double zoom) {
    _state = _state.copyWith(
      ganttView: _state.ganttView.copyWith(zoom: zoom.clamp(0.5, 2.0)),
    );
    notifyListeners();
  }
}

/// タスクカウントを計算
TaskCounts calculateTaskCounts(
  List<Task> tasks, {
  String? currentUserId,
}) {
  int today = 0;
  int delayed = 0;
  int waiting = 0;
  int mine = 0;

  final now = DateTime.now();
  final todayDate = DateTime(now.year, now.month, now.day);

  for (final task in tasks) {
    // 今日のタスク
    if (task.startDate != null) {
      final startDate = DateTime(
        task.startDate!.year,
        task.startDate!.month,
        task.startDate!.day,
      );
      if (startDate == todayDate ||
          (startDate.isBefore(todayDate) &&
              (task.endDate?.isAfter(todayDate) ?? false))) {
        today++;
      }
    }

    // 遅延
    if (task.delayStatus == DelayStatus.overdue) {
      delayed++;
    }

    // 待ち
    if (task.delayStatus == DelayStatus.waiting) {
      waiting++;
    }

    // 自分のタスク
    if (currentUserId != null && task.assignees.contains(currentUserId)) {
      mine++;
    }
  }

  return TaskCounts(
    today: today,
    delayed: delayed,
    waiting: waiting,
    mine: mine,
    total: tasks.length,
  );
}
