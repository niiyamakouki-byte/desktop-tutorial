import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/attendance_event.dart';
import '../models/person.dart';
import '../models/company.dart';
import 'attendance_storage_service.dart';

/// 入退場管理サービス
///
/// ビジネスロジックを担当:
/// - IN/OUT記録と警告検出
/// - 17:30自動補正
/// - EDIT/VOID権限チェック
/// - 現在入場者の取得
class AttendanceService extends ChangeNotifier {
  final AttendanceStorageService _storage = AttendanceStorageService();
  Timer? _autoCorrectTimer;
  bool _isInitialized = false;

  // キャッシュ
  List<Person> _cachedPersons = [];
  List<Company> _cachedCompanies = [];
  List<CurrentAttendee> _currentAttendees = [];

  List<CurrentAttendee> get currentAttendees => _currentAttendees;
  bool get isInitialized => _isInitialized;

  /// 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _storage.initialize();
    await _refreshCache();
    _scheduleAutoCorrection();
    _isInitialized = true;
    notifyListeners();
  }

  /// キャッシュ更新
  Future<void> _refreshCache() async {
    _cachedPersons = await _storage.getAllPersons();
    _cachedCompanies = await _storage.getAllCompanies();
  }

  /// 破棄
  @override
  void dispose() {
    _autoCorrectTimer?.cancel();
    super.dispose();
  }

  // ==========================================
  // 入退場記録
  // ==========================================

  /// 入場記録（INボタン）
  Future<AttendanceResult> recordIn({
    required String projectId,
    required String personId,
    required String companyId,
    String createdByUserId = 'kiosk',
  }) async {
    final deviceId = await _storage.getDeviceId();
    final now = DateTime.now();

    // 警告チェック: 同日に既にINがある場合
    final todayEvents = await _storage.getTodayEvents(projectId);
    final personTodayEvents = todayEvents.where((e) => e.personId == personId).toList();

    bool hasWarning = false;
    String? warningMessage;

    // 最後のイベントがINの場合は警告
    if (personTodayEvents.isNotEmpty) {
      final lastEvent = personTodayEvents.first; // 時間降順でソート済み
      if (lastEvent.type == AttendanceEventType.inEvent) {
        hasWarning = true;
        warningMessage = '既に入場済みです。OUTを押さずに再度INを記録しています。';
      }
    }

    final event = AttendanceEvent(
      id: _generateEventId(),
      projectId: projectId,
      personId: personId,
      companyId: companyId,
      type: AttendanceEventType.inEvent,
      occurredAt: now,
      deviceId: deviceId,
      createdByUserId: createdByUserId,
      hasWarning: hasWarning,
      warningMessage: warningMessage,
    );

    await _storage.saveEvent(event);
    await _updateCurrentAttendees(projectId);
    notifyListeners();

    return AttendanceResult(
      success: true,
      event: event,
      hasWarning: hasWarning,
      warningMessage: warningMessage,
    );
  }

  /// 退場記録（OUTボタン）
  Future<AttendanceResult> recordOut({
    required String projectId,
    required String personId,
    required String companyId,
    String createdByUserId = 'kiosk',
  }) async {
    final deviceId = await _storage.getDeviceId();
    final now = DateTime.now();

    // 警告チェック: 同日にINがない場合
    final todayEvents = await _storage.getTodayEvents(projectId);
    final personTodayEvents = todayEvents.where((e) => e.personId == personId).toList();

    bool hasWarning = false;
    String? warningMessage;

    // INがない場合は警告
    final hasIn = personTodayEvents.any((e) => e.type == AttendanceEventType.inEvent);
    if (!hasIn) {
      hasWarning = true;
      warningMessage = '入場記録がありません。INを押さずにOUTを記録しています。';
    }

    // 最後のイベントがOUTの場合も警告
    if (personTodayEvents.isNotEmpty) {
      final lastEvent = personTodayEvents.first;
      if (lastEvent.type == AttendanceEventType.outEvent) {
        hasWarning = true;
        warningMessage = '既に退場済みです。INを押さずに再度OUTを記録しています。';
      }
    }

    final event = AttendanceEvent(
      id: _generateEventId(),
      projectId: projectId,
      personId: personId,
      companyId: companyId,
      type: AttendanceEventType.outEvent,
      occurredAt: now,
      deviceId: deviceId,
      createdByUserId: createdByUserId,
      hasWarning: hasWarning,
      warningMessage: warningMessage,
    );

    await _storage.saveEvent(event);
    await _updateCurrentAttendees(projectId);
    notifyListeners();

    return AttendanceResult(
      success: true,
      event: event,
      hasWarning: hasWarning,
      warningMessage: warningMessage,
    );
  }

  /// 編集記録（管理者のみ）
  Future<AttendanceResult> recordEdit({
    required String projectId,
    required String personId,
    required String companyId,
    required String targetEventId,
    required String editedBy,
    String? reason,
  }) async {
    final deviceId = await _storage.getDeviceId();
    final now = DateTime.now();

    final event = AttendanceEvent(
      id: _generateEventId(),
      projectId: projectId,
      personId: personId,
      companyId: companyId,
      type: AttendanceEventType.edit,
      occurredAt: now,
      deviceId: deviceId,
      createdByUserId: editedBy,
      editTargetEventId: targetEventId,
      editNote: reason,
    );

    await _storage.saveEvent(event);
    notifyListeners();

    return AttendanceResult(
      success: true,
      event: event,
    );
  }

  /// 無効化記録（管理者のみ）
  Future<AttendanceResult> recordVoid({
    required String projectId,
    required String personId,
    required String companyId,
    required String targetEventId,
    required String voidedBy,
    String? reason,
  }) async {
    final deviceId = await _storage.getDeviceId();
    final now = DateTime.now();

    final event = AttendanceEvent(
      id: _generateEventId(),
      projectId: projectId,
      personId: personId,
      companyId: companyId,
      type: AttendanceEventType.void_,
      occurredAt: now,
      deviceId: deviceId,
      createdByUserId: voidedBy,
      editTargetEventId: targetEventId,
      editNote: reason,
    );

    await _storage.saveEvent(event);
    notifyListeners();

    return AttendanceResult(
      success: true,
      event: event,
    );
  }

  // ==========================================
  // 現在入場者取得
  // ==========================================

  /// 現在入場中の職人リストを更新
  Future<void> _updateCurrentAttendees(String projectId) async {
    _currentAttendees = await getCurrentAttendees(projectId);
  }

  /// 現在入場中の職人リストを取得
  Future<List<CurrentAttendee>> getCurrentAttendees(String projectId) async {
    final todayEvents = await _storage.getTodayEvents(projectId);
    final persons = await _storage.getPersonsByProject(projectId);
    final companies = await _storage.getAllCompanies();

    final personMap = {for (var p in persons) p.id: p};
    final companyMap = {for (var c in companies) c.id: c};

    // 人ごとに最後のイベントを取得
    final Map<String, AttendanceEvent> lastEventByPerson = {};
    for (final event in todayEvents) {
      if (event.type == AttendanceEventType.inEvent ||
          event.type == AttendanceEventType.outEvent) {
        if (!lastEventByPerson.containsKey(event.personId)) {
          lastEventByPerson[event.personId] = event;
        }
      }
    }

    // INが最後のイベントの人を抽出
    final attendees = <CurrentAttendee>[];
    for (final entry in lastEventByPerson.entries) {
      if (entry.value.type == AttendanceEventType.inEvent) {
        final person = personMap[entry.key];
        final company = companyMap[entry.value.companyId];
        if (person != null) {
          attendees.add(CurrentAttendee(
            person: person,
            company: company,
            inTime: entry.value.occurredAt,
            hasWarning: entry.value.hasWarning,
          ));
        }
      }
    }

    // 入場時刻順でソート
    attendees.sort((a, b) => a.inTime.compareTo(b.inTime));
    return attendees;
  }

  /// 会社別の現在入場者を取得
  Future<Map<String, List<CurrentAttendee>>> getCurrentAttendeesByCompany(
    String projectId,
  ) async {
    final attendees = await getCurrentAttendees(projectId);
    final result = <String, List<CurrentAttendee>>{};

    for (final attendee in attendees) {
      final companyId = attendee.company?.id ?? 'unknown';
      result.putIfAbsent(companyId, () => []).add(attendee);
    }

    return result;
  }

  /// 入場者数を取得
  Future<int> getCurrentAttendeeCount(String projectId) async {
    final attendees = await getCurrentAttendees(projectId);
    return attendees.length;
  }

  // ==========================================
  // 日次サマリー
  // ==========================================

  /// 日次サマリーを取得
  Future<List<DailyAttendanceSummary>> getDailySummary(
    String projectId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final events = await _storage.getEventsByDateRange(projectId, startOfDay, endOfDay);
    final persons = await _storage.getPersonsByProject(projectId);
    final companies = await _storage.getAllCompanies();

    final personMap = {for (var p in persons) p.id: p};
    final companyMap = {for (var c in companies) c.id: c};

    // 人ごとにイベントをグループ化
    final Map<String, List<AttendanceEvent>> eventsByPerson = {};
    for (final event in events) {
      eventsByPerson.putIfAbsent(event.personId, () => []).add(event);
    }

    final summaries = <DailyAttendanceSummary>[];
    for (final entry in eventsByPerson.entries) {
      final person = personMap[entry.key];
      if (person == null) continue;

      final company = companyMap[person.companyId];
      final personEvents = entry.value
        ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

      // IN/OUTを抽出
      DateTime? firstIn;
      DateTime? lastOut;
      bool hasAutoCorrection = false;

      for (final event in personEvents) {
        if (event.type == AttendanceEventType.inEvent && firstIn == null) {
          firstIn = event.occurredAt;
        }
        if (event.type == AttendanceEventType.outEvent) {
          lastOut = event.occurredAt;
          if (event.warningMessage?.contains('17:30自動補正') == true) {
            hasAutoCorrection = true;
          }
        }
      }

      // 勤務時間を計算
      Duration? workingHours;
      if (firstIn != null && lastOut != null) {
        workingHours = lastOut.difference(firstIn);
      }

      if (firstIn != null) {
        summaries.add(DailyAttendanceSummary(
          date: date,
          personId: person.id,
          personName: person.name,
          companyId: person.companyId,
          companyName: company?.name ?? '不明',
          firstIn: firstIn,
          lastOut: lastOut,
          workingHours: workingHours,
          hasAutoCorrection: hasAutoCorrection,
          events: personEvents,
        ));
      }
    }

    // 会社名、名前順でソート
    summaries.sort((a, b) {
      final companyCompare = a.companyName.compareTo(b.companyName);
      if (companyCompare != 0) return companyCompare;
      return a.personName.compareTo(b.personName);
    });

    return summaries;
  }

  // ==========================================
  // 17:30自動補正
  // ==========================================

  /// 自動補正をスケジュール
  void _scheduleAutoCorrection() {
    _autoCorrectTimer?.cancel();

    final now = DateTime.now();
    final correctionTime = DateTime(now.year, now.month, now.day, 17, 30);

    Duration delay;
    if (now.isBefore(correctionTime)) {
      delay = correctionTime.difference(now);
    } else {
      // 翌日の17:30
      delay = correctionTime.add(const Duration(days: 1)).difference(now);
    }

    _autoCorrectTimer = Timer(delay, () async {
      await performAutoCorrection();
      _scheduleAutoCorrection(); // 次の日もスケジュール
    });
  }

  /// 自動補正を実行
  Future<int> performAutoCorrection() async {
    // 全プロジェクトの今日のイベントを取得
    final allEvents = await _storage.getAllEvents();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayEvents = allEvents.where((e) =>
      e.occurredAt.isAfter(startOfDay) && e.occurredAt.isBefore(endOfDay)
    ).toList();

    // プロジェクトごとにグループ化
    final Map<String, List<AttendanceEvent>> eventsByProject = {};
    for (final event in todayEvents) {
      eventsByProject.putIfAbsent(event.projectId, () => []).add(event);
    }

    int correctionCount = 0;

    for (final projectEntry in eventsByProject.entries) {
      final projectId = projectEntry.key;
      final projectEvents = projectEntry.value;

      // 人ごとに最後のイベントを取得
      final Map<String, AttendanceEvent> lastEventByPerson = {};
      for (final event in projectEvents) {
        if (event.type == AttendanceEventType.inEvent ||
            event.type == AttendanceEventType.outEvent) {
          final existing = lastEventByPerson[event.personId];
          if (existing == null || event.occurredAt.isAfter(existing.occurredAt)) {
            lastEventByPerson[event.personId] = event;
          }
        }
      }

      // INが最後のイベントの人に自動OUT
      for (final entry in lastEventByPerson.entries) {
        if (entry.value.type == AttendanceEventType.inEvent) {
          await _recordAutoOut(
            projectId: projectId,
            personId: entry.key,
            companyId: entry.value.companyId,
          );
          correctionCount++;
        }
      }
    }

    notifyListeners();
    return correctionCount;
  }

  /// 自動OUT記録
  Future<void> _recordAutoOut({
    required String projectId,
    required String personId,
    required String companyId,
  }) async {
    final deviceId = await _storage.getDeviceId();
    final correctionTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      17, 30,
    );

    final event = AttendanceEvent(
      id: _generateEventId(),
      projectId: projectId,
      personId: personId,
      companyId: companyId,
      type: AttendanceEventType.outEvent,
      occurredAt: correctionTime,
      deviceId: deviceId,
      createdByUserId: 'system_auto_correction',
      hasWarning: true,
      warningMessage: '17:30自動補正: OUT記録がなかったため自動で退場を記録しました',
    );

    await _storage.saveEvent(event);
  }

  // ==========================================
  // QRコード処理
  // ==========================================

  /// QRコードから職人を検索してIN/OUT
  Future<AttendanceResult> processQrCode({
    required String projectId,
    required String qrCode,
    required bool isIn,
  }) async {
    final person = await _storage.getPersonByQrCode(qrCode);

    if (person == null) {
      return AttendanceResult(
        success: false,
        errorMessage: 'QRコードに該当する職人が見つかりません',
      );
    }

    if (person.projectId != projectId) {
      return AttendanceResult(
        success: false,
        errorMessage: 'この現場に登録されていない職人です',
      );
    }

    if (isIn) {
      return recordIn(
        projectId: projectId,
        personId: person.id,
        companyId: person.companyId,
      );
    } else {
      return recordOut(
        projectId: projectId,
        personId: person.id,
        companyId: person.companyId,
      );
    }
  }

  // ==========================================
  // 職人・会社管理
  // ==========================================

  /// 職人を取得
  Future<Person?> getPersonById(String personId) async {
    return _storage.getPersonById(personId);
  }

  /// プロジェクトの職人一覧を取得
  Future<List<Person>> getPersonsByProject(String projectId) async {
    return _storage.getPersonsByProject(projectId);
  }

  /// 会社別職人を取得
  Future<List<Person>> getPersonsByCompany(String companyId) async {
    return _storage.getPersonsByCompany(companyId);
  }

  /// 職人を保存
  Future<void> savePerson(Person person) async {
    await _storage.savePerson(person);
    await _refreshCache();
    notifyListeners();
  }

  /// 会社を取得
  Future<Company?> getCompanyById(String companyId) async {
    return _storage.getCompanyById(companyId);
  }

  /// 全会社を取得
  Future<List<Company>> getAllCompanies() async {
    return _storage.getAllCompanies();
  }

  /// 会社を保存
  Future<void> saveCompany(Company company) async {
    await _storage.saveCompany(company);
    await _refreshCache();
    notifyListeners();
  }

  // ==========================================
  // ユーティリティ
  // ==========================================

  /// イベントID生成
  String _generateEventId() {
    final now = DateTime.now();
    return 'evt_${now.millisecondsSinceEpoch}_${now.hashCode.abs()}';
  }

  /// CSVエクスポート
  Future<String> exportToCsv(
    String projectId,
    DateTime start,
    DateTime end,
  ) async {
    return _storage.exportToCsv(projectId, start, end);
  }

  /// サンプルデータ生成
  Future<void> generateSampleData(String projectId) async {
    await _storage.generateSampleData(projectId);
    await _refreshCache();
    notifyListeners();
  }

  /// 全データクリア（デバッグ用）
  Future<void> clearAll() async {
    await _storage.clearAll();
    _currentAttendees = [];
    _cachedPersons = [];
    _cachedCompanies = [];
    notifyListeners();
  }
}

/// 入退場記録結果
class AttendanceResult {
  final bool success;
  final AttendanceEvent? event;
  final bool hasWarning;
  final String? warningMessage;
  final String? errorMessage;

  AttendanceResult({
    required this.success,
    this.event,
    this.hasWarning = false,
    this.warningMessage,
    this.errorMessage,
  });
}

/// 現在入場者
class CurrentAttendee {
  final Person person;
  final Company? company;
  final DateTime inTime;
  final bool hasWarning;

  CurrentAttendee({
    required this.person,
    this.company,
    required this.inTime,
    this.hasWarning = false,
  });

  /// 滞在時間を取得
  Duration get stayDuration => DateTime.now().difference(inTime);

  /// 滞在時間を文字列で取得
  String get stayDurationString {
    final duration = stayDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}時間${minutes}分';
  }
}
