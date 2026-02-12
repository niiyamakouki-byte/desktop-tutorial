/// カレンダー設定モデル
/// 営業日計算に使用される設定（土日祝日の除外など）
class CalendarSettings {
  /// 土日を除外するか
  final bool excludeWeekends;

  /// 祝日を除外するか
  final bool excludeHolidays;

  /// カスタム休日（プロジェクト固有の休み）
  final List<DateTime> customHolidays;

  const CalendarSettings({
    this.excludeWeekends = true,
    this.excludeHolidays = true,
    this.customHolidays = const [],
  });

  CalendarSettings copyWith({
    bool? excludeWeekends,
    bool? excludeHolidays,
    List<DateTime>? customHolidays,
  }) {
    return CalendarSettings(
      excludeWeekends: excludeWeekends ?? this.excludeWeekends,
      excludeHolidays: excludeHolidays ?? this.excludeHolidays,
      customHolidays: customHolidays ?? this.customHolidays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'excludeWeekends': excludeWeekends,
      'excludeHolidays': excludeHolidays,
      'customHolidays': customHolidays
          .map((date) => date.toIso8601String())
          .toList(),
    };
  }

  factory CalendarSettings.fromJson(Map<String, dynamic> json) {
    return CalendarSettings(
      excludeWeekends: json['excludeWeekends'] as bool? ?? true,
      excludeHolidays: json['excludeHolidays'] as bool? ?? true,
      customHolidays: (json['customHolidays'] as List<dynamic>?)
              ?.map((dateStr) => DateTime.parse(dateStr as String))
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarSettings &&
          runtimeType == other.runtimeType &&
          excludeWeekends == other.excludeWeekends &&
          excludeHolidays == other.excludeHolidays &&
          _listEquals(customHolidays, other.customHolidays);

  @override
  int get hashCode =>
      excludeWeekends.hashCode ^
      excludeHolidays.hashCode ^
      customHolidays.hashCode;

  bool _listEquals(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_dateEquals(a[i], b[i])) return false;
    }
    return true;
  }

  bool _dateEquals(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
