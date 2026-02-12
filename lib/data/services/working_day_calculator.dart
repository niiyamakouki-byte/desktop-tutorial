import '../models/calendar_settings_model.dart';

/// 営業日計算サービス
/// 土日祝日を考慮した日程計算を行う
class WorkingDayCalculator {
  /// 日本の祝日（2026-2030年）
  /// 参考: https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html
  static final Map<int, List<DateTime>> _japaneseHolidays = {
    2026: [
      DateTime(2026, 1, 1), // 元日
      DateTime(2026, 1, 12), // 成人の日
      DateTime(2026, 2, 11), // 建国記念の日
      DateTime(2026, 2, 23), // 天皇誕生日
      DateTime(2026, 3, 20), // 春分の日
      DateTime(2026, 4, 29), // 昭和の日
      DateTime(2026, 5, 3), // 憲法記念日
      DateTime(2026, 5, 4), // みどりの日
      DateTime(2026, 5, 5), // こどもの日
      DateTime(2026, 5, 6), // 振替休日
      DateTime(2026, 7, 20), // 海の日
      DateTime(2026, 8, 11), // 山の日
      DateTime(2026, 9, 21), // 敬老の日
      DateTime(2026, 9, 22), // 秋分の日
      DateTime(2026, 10, 12), // スポーツの日
      DateTime(2026, 11, 3), // 文化の日
      DateTime(2026, 11, 23), // 勤労感謝の日
    ],
    2027: [
      DateTime(2027, 1, 1), // 元日
      DateTime(2027, 1, 11), // 成人の日
      DateTime(2027, 2, 11), // 建国記念の日
      DateTime(2027, 2, 23), // 天皇誕生日
      DateTime(2027, 3, 21), // 春分の日
      DateTime(2027, 4, 29), // 昭和の日
      DateTime(2027, 5, 3), // 憲法記念日
      DateTime(2027, 5, 4), // みどりの日
      DateTime(2027, 5, 5), // こどもの日
      DateTime(2027, 7, 19), // 海の日
      DateTime(2027, 8, 11), // 山の日
      DateTime(2027, 9, 20), // 敬老の日
      DateTime(2027, 9, 23), // 秋分の日
      DateTime(2027, 10, 11), // スポーツの日
      DateTime(2027, 11, 3), // 文化の日
      DateTime(2027, 11, 23), // 勤労感謝の日
    ],
    2028: [
      DateTime(2028, 1, 1), // 元日
      DateTime(2028, 1, 10), // 成人の日
      DateTime(2028, 2, 11), // 建国記念の日
      DateTime(2028, 2, 23), // 天皇誕生日
      DateTime(2028, 3, 20), // 春分の日
      DateTime(2028, 4, 29), // 昭和の日
      DateTime(2028, 5, 3), // 憲法記念日
      DateTime(2028, 5, 4), // みどりの日
      DateTime(2028, 5, 5), // こどもの日
      DateTime(2028, 7, 17), // 海の日
      DateTime(2028, 8, 11), // 山の日
      DateTime(2028, 9, 18), // 敬老の日
      DateTime(2028, 9, 22), // 秋分の日
      DateTime(2028, 10, 9), // スポーツの日
      DateTime(2028, 11, 3), // 文化の日
      DateTime(2028, 11, 23), // 勤労感謝の日
    ],
    2029: [
      DateTime(2029, 1, 1), // 元日
      DateTime(2029, 1, 8), // 成人の日
      DateTime(2029, 2, 11), // 建国記念の日
      DateTime(2029, 2, 23), // 天皇誕生日
      DateTime(2029, 3, 20), // 春分の日
      DateTime(2029, 4, 29), // 昭和の日
      DateTime(2029, 4, 30), // 振替休日
      DateTime(2029, 5, 3), // 憲法記念日
      DateTime(2029, 5, 4), // みどりの日
      DateTime(2029, 5, 5), // こどもの日
      DateTime(2029, 7, 16), // 海の日
      DateTime(2029, 8, 11), // 山の日
      DateTime(2029, 9, 17), // 敬老の日
      DateTime(2029, 9, 23), // 秋分の日
      DateTime(2029, 9, 24), // 振替休日
      DateTime(2029, 10, 8), // スポーツの日
      DateTime(2029, 11, 3), // 文化の日
      DateTime(2029, 11, 23), // 勤労感謝の日
    ],
    2030: [
      DateTime(2030, 1, 1), // 元日
      DateTime(2030, 1, 14), // 成人の日
      DateTime(2030, 2, 11), // 建国記念の日
      DateTime(2030, 2, 23), // 天皇誕生日
      DateTime(2030, 3, 20), // 春分の日
      DateTime(2030, 4, 29), // 昭和の日
      DateTime(2030, 5, 3), // 憲法記念日
      DateTime(2030, 5, 4), // みどりの日
      DateTime(2030, 5, 5), // こどもの日
      DateTime(2030, 5, 6), // 振替休日
      DateTime(2030, 7, 15), // 海の日
      DateTime(2030, 8, 11), // 山の日
      DateTime(2030, 8, 12), // 振替休日
      DateTime(2030, 9, 16), // 敬老の日
      DateTime(2030, 9, 23), // 秋分の日
      DateTime(2030, 10, 14), // スポーツの日
      DateTime(2030, 11, 3), // 文化の日
      DateTime(2030, 11, 4), // 振替休日
      DateTime(2030, 11, 23), // 勤労感謝の日
    ],
  };

  /// 指定した日付が営業日かどうかを判定
  static bool isWorkingDay(
    DateTime date,
    CalendarSettings settings,
  ) {
    // 土日チェック
    if (settings.excludeWeekends) {
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        return false;
      }
    }

    // 祝日チェック
    if (settings.excludeHolidays) {
      if (isJapaneseHoliday(date)) {
        return false;
      }
    }

    // カスタム休日チェック
    for (final holiday in settings.customHolidays) {
      if (_isSameDay(date, holiday)) {
        return false;
      }
    }

    return true;
  }

  /// 日本の祝日かどうか判定
  static bool isJapaneseHoliday(DateTime date) {
    final holidays = _japaneseHolidays[date.year];
    if (holidays == null) return false;

    return holidays.any((holiday) => _isSameDay(date, holiday));
  }

  /// 2つの日付が同じ日かどうか判定
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 開始日から終了日までの営業日数を計算
  /// 開始日と終了日を含む
  static int calculateWorkingDays(
    DateTime startDate,
    DateTime endDate,
    CalendarSettings settings,
  ) {
    if (startDate.isAfter(endDate)) {
      return 0;
    }

    int workingDays = 0;
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(end)) {
      if (isWorkingDay(current, settings)) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return workingDays;
  }

  /// 開始日から指定営業日数後の日付を計算
  /// 例: 2026/2/10 (月) + 5営業日 → 2026/2/16 (月)（途中の土日を除外）
  static DateTime addWorkingDays(
    DateTime startDate,
    int workingDays,
    CalendarSettings settings,
  ) {
    if (workingDays == 0) return startDate;

    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    int daysAdded = 0;

    // 正の営業日追加
    if (workingDays > 0) {
      while (daysAdded < workingDays) {
        current = current.add(const Duration(days: 1));
        if (isWorkingDay(current, settings)) {
          daysAdded++;
        }
      }
    } else {
      // 負の営業日追加（過去に戻る）
      while (daysAdded > workingDays) {
        current = current.subtract(const Duration(days: 1));
        if (isWorkingDay(current, settings)) {
          daysAdded--;
        }
      }
    }

    return current;
  }

  /// 開始日から指定カレンダー日数後の日付を計算し、
  /// それに相当する営業日数を返す
  /// 例: 10カレンダー日（土日含む）→ 何営業日に相当するか
  static int calendarDaysToWorkingDays(
    DateTime startDate,
    int calendarDays,
    CalendarSettings settings,
  ) {
    final endDate = startDate.add(Duration(days: calendarDays));
    return calculateWorkingDays(startDate, endDate, settings);
  }

  /// 営業日数を考慮した終了日を計算
  /// 開始日を含んで数える
  /// 例: 開始日2026/2/10 (月)、期間3営業日 → 終了日2026/2/12 (水)
  static DateTime calculateEndDate(
    DateTime startDate,
    int workingDays,
    CalendarSettings settings,
  ) {
    if (workingDays <= 0) return startDate;

    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    int daysCount = 0;

    // 開始日が営業日なら1日目としてカウント
    if (isWorkingDay(current, settings)) {
      daysCount = 1;
    }

    // 指定営業日数になるまで日付を進める
    while (daysCount < workingDays) {
      current = current.add(const Duration(days: 1));
      if (isWorkingDay(current, settings)) {
        daysCount++;
      }
    }

    return current;
  }

  /// 祝日リストを取得（デバッグ用）
  static List<DateTime> getHolidays(int year) {
    return _japaneseHolidays[year] ?? [];
  }

  /// サポートされている年の範囲を取得
  static List<int> getSupportedYears() {
    return _japaneseHolidays.keys.toList()..sort();
  }
}
