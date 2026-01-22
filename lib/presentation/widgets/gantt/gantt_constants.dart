import 'package:flutter/material.dart';

/// Constants specific to the Gantt chart widget system
class GanttConstants {
  GanttConstants._();

  // ============== Dimensions ==============
  /// Height of each task row in the Gantt chart
  static const double rowHeight = 44.0;

  /// Height of the timeline header (month + day rows)
  static const double headerHeight = 60.0;

  /// Height of the month row in header
  static const double monthRowHeight = 28.0;

  /// Height of the day row in header
  static const double dayRowHeight = 32.0;

  /// Width of each day cell in the timeline
  static const double dayWidth = 40.0;

  /// Width of the task list panel
  static const double taskListWidth = 350.0;

  /// Indentation for each level in the task tree
  static const double treeIndent = 24.0;

  /// Minimum width for a task bar
  static const double minTaskBarWidth = 8.0;

  /// Height of the task bar within a row
  static const double taskBarHeight = 24.0;

  /// Border radius for task bars
  static const double taskBarRadius = 4.0;

  /// Size of the expand/collapse icon
  static const double expandIconSize = 18.0;

  /// Width of the divider between panels
  static const double dividerWidth = 1.0;

  /// Padding inside task list cells
  static const double cellPadding = 8.0;

  /// Width of dependency arrow stroke
  static const double dependencyStrokeWidth = 1.5;

  /// Size of dependency arrow head
  static const double dependencyArrowSize = 6.0;

  /// Vertical offset for dependency connection point
  static const double dependencyVerticalOffset = 12.0;

  /// Horizontal gap for dependency routing
  static const double dependencyHorizontalGap = 8.0;

  /// Width of the today line
  static const double todayLineWidth = 2.0;

  /// Width of the progress indicator within task bar
  static const double progressBarHeight = 4.0;

  /// Size of milestone diamond
  static const double milestoneSize = 12.0;

  /// Width of resizer handle
  static const double resizerWidth = 8.0;

  /// Size of dependency connector dots
  static const double connectorSize = 14.0;

  /// Connector hover expansion factor
  static const double connectorHoverScale = 1.5;

  // ============== Z-Index Layers ==============
  static const int gridLayer = 0;
  static const int weekendLayer = 1;
  static const int taskBarLayer = 2;
  static const int dependencyLayer = 3;
  static const int todayLineLayer = 4;
  static const int hoverLayer = 5;

  // ============== Animation ==============
  /// Duration for expand/collapse animation
  static const Duration expandDuration = Duration(milliseconds: 200);

  /// Duration for hover effects
  static const Duration hoverDuration = Duration(milliseconds: 150);

  /// Duration for scroll sync debounce
  static const Duration scrollSyncDebounce = Duration(milliseconds: 16);

  /// Curve for expand/collapse animation
  static const Curve expandCurve = Curves.easeInOut;

  // ============== View Settings ==============
  /// Number of days to show before project start
  static const int bufferDaysBefore = 7;

  /// Number of days to show after project end
  static const int bufferDaysAfter = 14;

  /// Default zoom level (1.0 = normal)
  static const double defaultZoom = 1.0;

  /// Minimum zoom level
  static const double minZoom = 0.5;

  /// Maximum zoom level
  static const double maxZoom = 2.0;

  /// Zoom step increment
  static const double zoomStep = 0.1;

  // ============== Task Bar Styles ==============
  /// Opacity for task bar background
  static const double taskBarOpacity = 0.9;

  /// Opacity for task bar progress overlay
  static const double progressOpacity = 0.3;

  /// Opacity for weekend column highlighting
  static const double weekendOpacity = 0.5;

  /// Opacity for hover effect
  static const double hoverOpacity = 0.1;

  /// Opacity for selected row
  static const double selectedOpacity = 0.15;

  // ============== Scroll Settings ==============
  /// Physics for the scroll views
  static const ScrollPhysics scrollPhysics = ClampingScrollPhysics();

  /// Threshold for initiating auto-scroll
  static const double autoScrollThreshold = 50.0;

  /// Speed of auto-scroll (pixels per frame)
  static const double autoScrollSpeed = 10.0;

  // ============== Date Formatting ==============
  /// Japanese weekday abbreviations
  static const List<String> weekDaysJP = ['日', '月', '火', '水', '木', '金', '土'];

  /// Format for month display in header
  static String formatMonth(DateTime date) {
    return '${date.year}年${date.month}月';
  }

  /// Format for day display in header
  static String formatDay(DateTime date) {
    return '${date.day}';
  }

  /// Format for full date display
  static String formatFullDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  /// Format for date range display
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${start.month}/${start.day} - ${end.day}';
    } else if (start.year == end.year) {
      return '${start.month}/${start.day} - ${end.month}/${end.day}';
    }
    return '${start.year}/${start.month}/${start.day} - ${end.year}/${end.month}/${end.day}';
  }

  /// Get weekday name in Japanese
  static String getWeekdayJP(DateTime date) {
    return weekDaysJP[date.weekday % 7];
  }

  /// Check if date is weekend (Saturday or Sunday)
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get the start of the day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get the end of the day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}

/// Enum for Gantt chart view modes
enum GanttViewMode {
  day,
  week,
  month,
}

/// Extension for GanttViewMode
extension GanttViewModeExtension on GanttViewMode {
  String get label {
    switch (this) {
      case GanttViewMode.day:
        return '日';
      case GanttViewMode.week:
        return '週';
      case GanttViewMode.month:
        return '月';
    }
  }

  double get dayWidth {
    switch (this) {
      case GanttViewMode.day:
        return 40.0;
      case GanttViewMode.week:
        return 20.0;
      case GanttViewMode.month:
        return 8.0;
    }
  }
}
