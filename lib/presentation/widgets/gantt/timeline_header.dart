import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'gantt_constants.dart';

/// Timeline header component showing month and day rows
class TimelineHeader extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final double dayWidth;
  final ScrollController scrollController;
  final GanttViewMode viewMode;

  const TimelineHeader({
    super.key,
    required this.startDate,
    required this.endDate,
    this.dayWidth = GanttConstants.dayWidth,
    required this.scrollController,
    this.viewMode = GanttViewMode.day,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GanttConstants.headerHeight,
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
      child: Column(
        children: [
          // Month row
          SizedBox(
            height: GanttConstants.monthRowHeight,
            child: _buildMonthRow(),
          ),
          // Divider
          Container(
            height: 1,
            color: AppColors.ganttHeaderBg.withOpacity(0.5),
          ),
          // Day row
          Expanded(
            child: _buildDayRow(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthRow() {
    final months = _getMonthRanges();

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: months.map((monthRange) {
          final width = monthRange.dayCount * dayWidth;
          return Container(
            width: width,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppColors.ganttHeaderText.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Text(
                GanttConstants.formatMonth(monthRange.date),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ganttHeaderText,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayRow() {
    final days = _getDays();

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: days.map((date) {
          final isWeekend = GanttConstants.isWeekend(date);
          final isToday = GanttConstants.isToday(date);

          return Container(
            width: dayWidth,
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary.withOpacity(0.3)
                  : (isWeekend
                      ? AppColors.ganttHeaderBg.withOpacity(0.7)
                      : null),
              border: Border(
                right: BorderSide(
                  color: AppColors.ganttHeaderText.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  GanttConstants.formatDay(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isToday
                        ? Colors.white
                        : (isWeekend
                            ? AppColors.ganttHeaderText.withOpacity(0.6)
                            : AppColors.ganttHeaderText),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  GanttConstants.getWeekdayJP(date),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: isWeekend
                        ? (date.weekday == DateTime.sunday
                            ? Colors.red.shade300
                            : Colors.blue.shade300)
                        : AppColors.ganttHeaderText.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<_MonthRange> _getMonthRanges() {
    final months = <_MonthRange>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
           (currentDate.year == endDate.year && currentDate.month == endDate.month)) {
      final monthStart = DateTime(currentDate.year, currentDate.month, 1);
      final monthEnd = DateTime(currentDate.year, currentDate.month + 1, 0);

      // Calculate visible days in this month
      final visibleStart = currentDate.isAfter(monthStart) ? currentDate : monthStart;
      final visibleEnd = monthEnd.isBefore(endDate) ? monthEnd : endDate;
      final dayCount = visibleEnd.difference(visibleStart).inDays + 1;

      months.add(_MonthRange(
        date: monthStart,
        dayCount: dayCount,
      ));

      // Move to next month
      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
    }

    return months;
  }

  List<DateTime> _getDays() {
    final days = <DateTime>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
           currentDate.isAtSameMomentAs(endDate)) {
      days.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return days;
  }
}

class _MonthRange {
  final DateTime date;
  final int dayCount;

  _MonthRange({
    required this.date,
    required this.dayCount,
  });
}

/// Week header for week view mode
class WeekHeader extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final double weekWidth;
  final ScrollController scrollController;

  const WeekHeader({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.weekWidth,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = _getWeeks();

    return Container(
      height: GanttConstants.headerHeight,
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
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: weeks.map((week) {
            return Container(
              width: weekWidth,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: AppColors.ganttHeaderText.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${week.month}月 第${_getWeekOfMonth(week)}週',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ganttHeaderText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${week.month}/${week.day}~',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.ganttHeaderText.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<DateTime> _getWeeks() {
    final weeks = <DateTime>[];
    var currentDate = startDate;

    // Adjust to start of week (Monday)
    while (currentDate.weekday != DateTime.monday) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    while (currentDate.isBefore(endDate)) {
      weeks.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 7));
    }

    return weeks;
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final daysDiff = date.difference(firstDayOfMonth).inDays;
    return (daysDiff / 7).floor() + 1;
  }
}

/// Compact day header showing only essential info
class CompactDayHeader extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final double dayWidth;
  final ScrollController scrollController;

  const CompactDayHeader({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.dayWidth,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final days = _getDays();

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.ganttHeaderBg,
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: days.map((date) {
            final isWeekend = GanttConstants.isWeekend(date);
            final isToday = GanttConstants.isToday(date);
            final isFirstOfMonth = date.day == 1;

            return Container(
              width: dayWidth,
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.primary.withOpacity(0.3)
                    : null,
                border: Border(
                  left: isFirstOfMonth
                      ? BorderSide(
                          color: AppColors.ganttHeaderText.withOpacity(0.4),
                          width: 1,
                        )
                      : BorderSide.none,
                ),
              ),
              child: Center(
                child: Text(
                  isFirstOfMonth ? '${date.month}/${date.day}' : '${date.day}',
                  style: TextStyle(
                    fontSize: isFirstOfMonth ? 10 : 9,
                    fontWeight: isFirstOfMonth || isToday
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isWeekend
                        ? (date.weekday == DateTime.sunday
                            ? Colors.red.shade300
                            : Colors.blue.shade300)
                        : AppColors.ganttHeaderText.withOpacity(0.8),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<DateTime> _getDays() {
    final days = <DateTime>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
           currentDate.isAtSameMomentAs(endDate)) {
      days.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return days;
  }
}
