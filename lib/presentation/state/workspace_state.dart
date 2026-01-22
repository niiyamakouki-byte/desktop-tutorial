import 'package:flutter/foundation.dart';

/// 右パネルの表示モード
enum RightPanelMode {
  /// プロジェクト概要
  project,

  /// タスク詳細
  task,

  /// 遅延追跡
  delayTrace,
}

/// タスクのステータス
enum TaskStatusType {
  todo,
  doing,
  done,
  waiting,
  delayed;

  String get label {
    switch (this) {
      case TaskStatusType.todo:
        return '未着手';
      case TaskStatusType.doing:
        return '進行中';
      case TaskStatusType.done:
        return '完了';
      case TaskStatusType.waiting:
        return '待ち';
      case TaskStatusType.delayed:
        return '遅延';
    }
  }
}

/// 待ち/遅延の理由
enum BlockReason {
  weather('天候', 'weather'),
  material('材料待ち', 'material'),
  approval('承認待ち', 'approval'),
  dependency('前工程待ち', 'dependency'),
  client('施主', 'client'),
  other('その他', 'other');

  const BlockReason(this.label, this.code);
  final String label;
  final String code;

  static BlockReason? fromCode(String? code) {
    if (code == null) return null;
    return BlockReason.values.firstWhere(
      (e) => e.code == code,
      orElse: () => BlockReason.other,
    );
  }
}

/// 選択状態
@immutable
class SelectionState {
  final String? selectedTaskId;
  final bool delayTraceEnabled;

  const SelectionState({
    this.selectedTaskId,
    this.delayTraceEnabled = false,
  });

  SelectionState copyWith({
    String? selectedTaskId,
    bool? delayTraceEnabled,
    bool clearSelection = false,
  }) {
    return SelectionState(
      selectedTaskId: clearSelection ? null : (selectedTaskId ?? this.selectedTaskId),
      delayTraceEnabled: delayTraceEnabled ?? this.delayTraceEnabled,
    );
  }

  bool get hasSelection => selectedTaskId != null;
}

/// クイックフィルター
enum QuickFilter {
  all('すべて'),
  today('今日'),
  delayed('遅延'),
  waiting('待ち'),
  mine('自分');

  const QuickFilter(this.label);
  final String label;
}

/// タスクフィルター
@immutable
class TaskFilters {
  final QuickFilter quick;
  final String? trade;
  final String? floor;
  final String? assigneeCompany;
  final TaskStatusType? status;
  final String? searchText;

  const TaskFilters({
    this.quick = QuickFilter.all,
    this.trade,
    this.floor,
    this.assigneeCompany,
    this.status,
    this.searchText,
  });

  TaskFilters copyWith({
    QuickFilter? quick,
    String? trade,
    String? floor,
    String? assigneeCompany,
    TaskStatusType? status,
    String? searchText,
    bool clearTrade = false,
    bool clearFloor = false,
    bool clearCompany = false,
    bool clearStatus = false,
    bool clearSearch = false,
  }) {
    return TaskFilters(
      quick: quick ?? this.quick,
      trade: clearTrade ? null : (trade ?? this.trade),
      floor: clearFloor ? null : (floor ?? this.floor),
      assigneeCompany: clearCompany ? null : (assigneeCompany ?? this.assigneeCompany),
      status: clearStatus ? null : (status ?? this.status),
      searchText: clearSearch ? null : (searchText ?? this.searchText),
    );
  }

  bool get hasActiveFilters =>
      quick != QuickFilter.all ||
      trade != null ||
      floor != null ||
      assigneeCompany != null ||
      status != null ||
      (searchText != null && searchText!.isNotEmpty);
}

/// タスクソート
enum TaskSort {
  risk('リスク順'),
  due('期日順'),
  wbs('WBS順');

  const TaskSort(this.label);
  final String label;
}

/// ガント表示設定
enum GanttGranularity {
  day('日'),
  week('週'),
  month('月');

  const GanttGranularity(this.label);
  final String label;
}

@immutable
class GanttViewState {
  final GanttGranularity granularity;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double zoom;

  const GanttViewState({
    this.granularity = GanttGranularity.week,
    required this.rangeStart,
    required this.rangeEnd,
    this.zoom = 1.0,
  });

  GanttViewState copyWith({
    GanttGranularity? granularity,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    double? zoom,
  }) {
    return GanttViewState(
      granularity: granularity ?? this.granularity,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      zoom: zoom ?? this.zoom,
    );
  }
}

/// 権限
@immutable
class Permissions {
  final bool canEditDates;
  final bool canEditAssignee;
  final bool canChangeStatus;
  final bool canAddPhoto;
  final bool canLinkDocs;
  final bool canViewAudit;

  const Permissions({
    this.canEditDates = true,
    this.canEditAssignee = true,
    this.canChangeStatus = true,
    this.canAddPhoto = true,
    this.canLinkDocs = true,
    this.canViewAudit = true,
  });

  /// 全権限あり
  static const all = Permissions();

  /// 読み取り専用
  static const readOnly = Permissions(
    canEditDates: false,
    canEditAssignee: false,
    canChangeStatus: false,
    canAddPhoto: false,
    canLinkDocs: false,
    canViewAudit: true,
  );
}

/// ワークスペース全体の状態
@immutable
class ProjectWorkspaceState {
  final SelectionState selection;
  final RightPanelMode rightMode;
  final bool isRightOpen;
  final TaskFilters filters;
  final TaskSort sort;
  final GanttViewState ganttView;
  final bool pinnedRightPanel;

  const ProjectWorkspaceState({
    this.selection = const SelectionState(),
    this.rightMode = RightPanelMode.project,
    this.isRightOpen = true,
    this.filters = const TaskFilters(),
    this.sort = TaskSort.wbs,
    required this.ganttView,
    this.pinnedRightPanel = false,
  });

  ProjectWorkspaceState copyWith({
    SelectionState? selection,
    RightPanelMode? rightMode,
    bool? isRightOpen,
    TaskFilters? filters,
    TaskSort? sort,
    GanttViewState? ganttView,
    bool? pinnedRightPanel,
  }) {
    return ProjectWorkspaceState(
      selection: selection ?? this.selection,
      rightMode: rightMode ?? this.rightMode,
      isRightOpen: isRightOpen ?? this.isRightOpen,
      filters: filters ?? this.filters,
      sort: sort ?? this.sort,
      ganttView: ganttView ?? this.ganttView,
      pinnedRightPanel: pinnedRightPanel ?? this.pinnedRightPanel,
    );
  }
}

/// タスクカウンター（フィルターバッジ用）
@immutable
class TaskCounts {
  final int today;
  final int delayed;
  final int waiting;
  final int mine;
  final int total;

  const TaskCounts({
    this.today = 0,
    this.delayed = 0,
    this.waiting = 0,
    this.mine = 0,
    this.total = 0,
  });
}

/// タスクツリーノード
@immutable
class TaskTreeNode {
  final String id;
  final String taskId;
  final List<TaskTreeNode> children;
  final bool isExpanded;

  const TaskTreeNode({
    required this.id,
    required this.taskId,
    this.children = const [],
    this.isExpanded = true,
  });

  TaskTreeNode copyWith({
    String? id,
    String? taskId,
    List<TaskTreeNode>? children,
    bool? isExpanded,
  }) {
    return TaskTreeNode(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

/// クイックアクションの種類
enum QuickActionType {
  openDelayForm,
  addPhoto,
  openLatestDrawing,
  openThread,
}

/// クイックアクション引数
@immutable
class QuickActionArgs {
  final String taskId;
  final QuickActionType action;

  const QuickActionArgs({
    required this.taskId,
    required this.action,
  });
}

/// 日程編集引数
@immutable
class EditTaskDatesArgs {
  final String taskId;
  final DateTime newStart;
  final DateTime newEnd;
  final BlockReason? blockReason;
  final String? note;
  final String via; // 'drag' | 'form'

  const EditTaskDatesArgs({
    required this.taskId,
    required this.newStart,
    required this.newEnd,
    this.blockReason,
    this.note,
    required this.via,
  });
}

/// 遅延・待ち理由登録引数
@immutable
class SubmitBlockReasonArgs {
  final String taskId;
  final TaskStatusType status; // waiting or delayed
  final BlockReason blockReason;
  final String note;

  const SubmitBlockReasonArgs({
    required this.taskId,
    required this.status,
    required this.blockReason,
    required this.note,
  });
}
