/// Gantt Chart Widget Library
///
/// A complete Gantt chart implementation for Flutter construction project management.
///
/// Features:
/// - Hierarchical task tree with expand/collapse
/// - Timeline grid with task bars and progress indicators
/// - Synchronized scrolling between task list and timeline
/// - Dependency arrows between tasks
/// - Today line indicator
/// - Weekend highlighting
/// - Japanese date formatting
/// - Smooth animations and hover effects
///
/// Usage:
/// ```dart
/// import 'package:your_app/presentation/widgets/gantt/gantt.dart';
///
/// GanttChart(
///   tasks: tasks,
///   selectedTaskId: selectedId,
///   onTaskSelected: (task) => setState(() => selectedId = task?.id),
///   onTaskDoubleTap: (task) => _showTaskEditor(task),
///   onTaskExpandToggle: (task, expanded) => _updateTaskExpanded(task, expanded),
///   showDependencies: true,
///   showTodayLine: true,
///   showWeekends: true,
/// )
/// ```

library gantt;

export 'gantt_constants.dart';
export 'gantt_chart.dart';
export 'task_list_panel.dart';
export 'timeline_panel.dart';
export 'task_row.dart';
export 'timeline_header.dart';
export 'dependency_painter.dart';
