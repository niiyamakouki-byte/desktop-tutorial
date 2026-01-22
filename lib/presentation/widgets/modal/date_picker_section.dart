import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Date picker section with calendar UI for start/end dates
/// Shows Japanese day and month names
class DatePickerSection extends StatefulWidget {
  /// Start date
  final DateTime startDate;

  /// End date
  final DateTime endDate;

  /// Callback when start date changes
  final ValueChanged<DateTime> onStartDateChanged;

  /// Callback when end date changes
  final ValueChanged<DateTime> onEndDateChanged;

  /// Whether the picker is enabled
  final bool enabled;

  /// Optional label text
  final String? label;

  const DatePickerSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.enabled = true,
    this.label,
  });

  @override
  State<DatePickerSection> createState() => _DatePickerSectionState();
}

class _DatePickerSectionState extends State<DatePickerSection> {
  bool _showStartCalendar = false;
  bool _showEndCalendar = false;

  void _toggleStartCalendar() {
    if (!widget.enabled) return;
    setState(() {
      _showStartCalendar = !_showStartCalendar;
      _showEndCalendar = false;
    });
  }

  void _toggleEndCalendar() {
    if (!widget.enabled) return;
    setState(() {
      _showEndCalendar = !_showEndCalendar;
      _showStartCalendar = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  int get _durationDays {
    return widget.endDate.difference(widget.startDate).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],

        // Date range display
        Row(
          children: [
            // Start date
            Expanded(
              child: _DateField(
                label: '開始日',
                date: widget.startDate,
                isActive: _showStartCalendar,
                enabled: widget.enabled,
                onTap: _toggleStartCalendar,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),

            // Duration indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppConstants.paddingXS),
                  Text(
                    '$_durationDays日間',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),

            // End date
            Expanded(
              child: _DateField(
                label: '終了日',
                date: widget.endDate,
                isActive: _showEndCalendar,
                enabled: widget.enabled,
                onTap: _toggleEndCalendar,
              ),
            ),
          ],
        ),

        // Calendar
        AnimatedSize(
          duration: AppConstants.animationNormal,
          curve: Curves.easeInOut,
          child: _showStartCalendar || _showEndCalendar
              ? Padding(
                  padding: const EdgeInsets.only(top: AppConstants.paddingM),
                  child: _CalendarView(
                    selectedDate:
                        _showStartCalendar ? widget.startDate : widget.endDate,
                    startDate: widget.startDate,
                    endDate: widget.endDate,
                    isSelectingStart: _showStartCalendar,
                    onDateSelected: (date) {
                      if (_showStartCalendar) {
                        // Ensure start date is not after end date
                        if (date.isAfter(widget.endDate)) {
                          widget.onStartDateChanged(date);
                          widget.onEndDateChanged(date);
                        } else {
                          widget.onStartDateChanged(date);
                        }
                      } else {
                        // Ensure end date is not before start date
                        if (date.isBefore(widget.startDate)) {
                          widget.onStartDateChanged(date);
                          widget.onEndDateChanged(date);
                        } else {
                          widget.onEndDateChanged(date);
                        }
                      }
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Date field button widget with modern calendar card design
class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.isActive,
    required this.enabled,
    required this.onTap,
  });

  static const _weekDays = ['日', '月', '火', '水', '木', '金', '土'];

  @override
  Widget build(BuildContext context) {
    final weekDay = _weekDays[date.weekday % 7];
    final isWeekend = date.weekday == DateTime.sunday || date.weekday == DateTime.saturday;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Top label bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusL - 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    label == '開始日' ? Icons.play_arrow_rounded : Icons.stop_rounded,
                    size: 14,
                    color: isActive ? Colors.white : AppColors.iconDefault,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Calendar date display
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                children: [
                  // Month
                  Text(
                    '${date.year}年${date.month}月',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Day number
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  // Weekday
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isWeekend
                          ? (date.weekday == DateTime.sunday
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1))
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '($weekDay)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isWeekend
                            ? (date.weekday == DateTime.sunday
                                ? AppColors.error
                                : AppColors.primary)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendar view widget with Japanese labels
class _CalendarView extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime startDate;
  final DateTime endDate;
  final bool isSelectingStart;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarView({
    required this.selectedDate,
    required this.startDate,
    required this.endDate,
    required this.isSelectingStart,
    required this.onDateSelected,
  });

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  List<DateTime?> _getDaysInMonth() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);

    final days = <DateTime?>[];

    // Add empty spaces for days before the first day
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    for (var i = 0; i < firstWeekday; i++) {
      days.add(null);
    }

    // Add all days of the month
    for (var day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(_displayedMonth.year, _displayedMonth.month, day));
    }

    return days;
  }

  bool _isInRange(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      widget.startDate.year,
      widget.startDate.month,
      widget.startDate.day,
    );
    final normalizedEnd = DateTime(
      widget.endDate.year,
      widget.endDate.month,
      widget.endDate.day,
    );

    return !normalizedDate.isBefore(normalizedStart) &&
        !normalizedDate.isAfter(normalizedEnd);
  }

  bool _isSelected(DateTime date) {
    final selectedDate = widget.selectedDate;
    return date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
  }

  bool _isStartDate(DateTime date) {
    return date.year == widget.startDate.year &&
        date.month == widget.startDate.month &&
        date.day == widget.startDate.day;
  }

  bool _isEndDate(DateTime date) {
    return date.year == widget.endDate.year &&
        date.month == widget.endDate.month &&
        date.day == widget.endDate.day;
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.iconDefault,
                iconSize: 24,
              ),
              Text(
                '${_displayedMonth.year}年${AppConstants.monthsJP[_displayedMonth.month - 1]}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.iconDefault,
                iconSize: 24,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingS),

          // Weekday headers (Japanese)
          Row(
            children: AppConstants.weekDaysJP.map((day) {
              final isWeekend = day == '日' || day == '土';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isWeekend
                          ? (day == '日' ? AppColors.error : AppColors.primary)
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.paddingS),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) {
                return const SizedBox.shrink();
              }
              return _CalendarDay(
                date: date,
                isSelected: _isSelected(date),
                isInRange: _isInRange(date),
                isStartDate: _isStartDate(date),
                isEndDate: _isEndDate(date),
                isToday: _isToday(date),
                onTap: () => widget.onDateSelected(date),
              );
            },
          ),

          // Today button
          const SizedBox(height: AppConstants.paddingM),
          GestureDetector(
            onTap: () => widget.onDateSelected(DateTime.now()),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.today,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppConstants.paddingXS),
                  Text(
                    '今日',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual calendar day cell
class _CalendarDay extends StatefulWidget {
  final DateTime date;
  final bool isSelected;
  final bool isInRange;
  final bool isStartDate;
  final bool isEndDate;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarDay({
    required this.date,
    required this.isSelected,
    required this.isInRange,
    required this.isStartDate,
    required this.isEndDate,
    required this.isToday,
    required this.onTap,
  });

  @override
  State<_CalendarDay> createState() => _CalendarDayState();
}

class _CalendarDayState extends State<_CalendarDay> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isWeekend =
        widget.date.weekday == DateTime.sunday ||
        widget.date.weekday == DateTime.saturday;

    Color backgroundColor;
    Color textColor;
    BoxDecoration decoration;

    if (widget.isSelected) {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
      decoration = BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else if (widget.isStartDate || widget.isEndDate) {
      backgroundColor = AppColors.primary.withOpacity(0.8);
      textColor = Colors.white;
      decoration = BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.horizontal(
          left: widget.isStartDate
              ? const Radius.circular(20)
              : Radius.zero,
          right: widget.isEndDate
              ? const Radius.circular(20)
              : Radius.zero,
        ),
      );
    } else if (widget.isInRange) {
      backgroundColor = AppColors.primary.withOpacity(0.15);
      textColor = AppColors.primary;
      decoration = BoxDecoration(
        color: backgroundColor,
      );
    } else if (widget.isToday) {
      backgroundColor = Colors.transparent;
      textColor = AppColors.primary;
      decoration = BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 2),
        shape: BoxShape.circle,
      );
    } else {
      backgroundColor = _isHovered ? AppColors.surfaceVariant : Colors.transparent;
      textColor = isWeekend
          ? (widget.date.weekday == DateTime.sunday
              ? AppColors.error
              : AppColors.primary)
          : AppColors.textPrimary;
      decoration = BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          decoration: decoration,
          child: Center(
            child: Text(
              '${widget.date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: widget.isSelected || widget.isToday
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact date range display widget for use outside the picker
class DateRangeDisplay extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onTap;

  const DateRangeDisplay({
    super.key,
    required this.startDate,
    required this.endDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = endDate.difference(startDate).inDays + 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.date_range,
              size: 16,
              color: AppColors.iconDefault,
            ),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              '${startDate.month}/${startDate.day} - ${endDate.month}/${endDate.day}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppConstants.paddingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingXS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                '$duration日',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
