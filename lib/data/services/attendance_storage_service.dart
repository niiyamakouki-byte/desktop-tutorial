import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_event.dart';
import '../models/person.dart';
import '../models/company.dart';

export '../models/attendance_event.dart';
export '../models/person.dart';
export '../models/company.dart';

/// ローカルストレージサービス
///
/// オフライン対応のためのローカルデータ永続化を担当
/// SharedPreferencesを使用（Web対応）
class AttendanceStorageService {
  static const String _eventsKey = 'attendance_events';
  static const String _personsKey = 'attendance_persons';
  static const String _companiesKey = 'attendance_companies';
  static const String _deviceIdKey = 'device_id';
  static const String _lastSyncKey = 'last_sync_at';

  SharedPreferences? _prefs;

  /// 初期化
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// SharedPreferencesインスタンスを取得
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==========================================
  // イベント管理
  // ==========================================

  /// 全イベントを取得
  Future<List<AttendanceEvent>> getAllEvents() async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(_eventsKey) ?? [];
    return jsonList
        .map((json) => AttendanceEvent.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  /// プロジェクト別イベントを取得
  Future<List<AttendanceEvent>> getEventsByProject(String projectId) async {
    final events = await getAllEvents();
    return events.where((e) => e.projectId == projectId).toList();
  }

  /// 日付範囲でイベントを取得
  Future<List<AttendanceEvent>> getEventsByDateRange(
    String projectId,
    DateTime start,
    DateTime end,
  ) async {
    final events = await getEventsByProject(projectId);
    return events.where((e) {
      return e.occurredAt.isAfter(start) && e.occurredAt.isBefore(end);
    }).toList();
  }

  /// 今日のイベントを取得
  Future<List<AttendanceEvent>> getTodayEvents(String projectId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getEventsByDateRange(projectId, startOfDay, endOfDay);
  }

  /// 未同期イベントを取得
  Future<List<AttendanceEvent>> getPendingEvents() async {
    final events = await getAllEvents();
    return events.where((e) => e.syncState == SyncState.pending).toList();
  }

  /// イベントを保存（追記のみ、上書き禁止）
  Future<void> saveEvent(AttendanceEvent event) async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(_eventsKey) ?? [];
    jsonList.add(jsonEncode(event.toJson()));
    await prefs.setStringList(_eventsKey, jsonList);
  }

  /// 複数イベントを一括保存
  Future<void> saveEvents(List<AttendanceEvent> events) async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(_eventsKey) ?? [];
    for (final event in events) {
      jsonList.add(jsonEncode(event.toJson()));
    }
    await prefs.setStringList(_eventsKey, jsonList);
  }

  /// イベントを同期済みとしてマーク
  Future<void> markEventAsSynced(String eventId, DateTime syncTime) async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(_eventsKey) ?? [];
    final updatedList = <String>[];

    for (final json in jsonList) {
      final event = AttendanceEvent.fromJson(jsonDecode(json));
      if (event.id == eventId) {
        updatedList.add(jsonEncode(event.markAsSynced(syncTime).toJson()));
      } else {
        updatedList.add(json);
      }
    }

    await prefs.setStringList(_eventsKey, updatedList);
  }

  // ==========================================
  // 職人管理
  // ==========================================

  /// 全職人を取得
  Future<List<Person>> getAllPersons() async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(_personsKey) ?? [];
    return jsonList.map((json) => Person.fromJson(jsonDecode(json))).toList();
  }

  /// プロジェクト別職人を取得
  Future<List<Person>> getPersonsByProject(String projectId) async {
    final persons = await getAllPersons();
    return persons.where((p) => p.projectId == projectId).toList();
  }

  /// 会社別職人を取得
  Future<List<Person>> getPersonsByCompany(String companyId) async {
    final persons = await getAllPersons();
    return persons.where((p) => p.companyId == companyId).toList();
  }

  /// 職人をIDで取得
  Future<Person?> getPersonById(String personId) async {
    final persons = await getAllPersons();
    try {
      return persons.firstWhere((p) => p.id == personId);
    } catch (_) {
      return null;
    }
  }

  /// QRコードで職人を検索
  Future<Person?> getPersonByQrCode(String qrCode) async {
    final persons = await getAllPersons();
    try {
      return persons.firstWhere((p) => p.qrCode == qrCode);
    } catch (_) {
      return null;
    }
  }

  /// 職人を保存
  Future<void> savePerson(Person person) async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(_personsKey) ?? [];

    // 既存の場合は更新
    final index = jsonList.indexWhere((json) {
      final p = Person.fromJson(jsonDecode(json));
      return p.id == person.id;
    });

    if (index >= 0) {
      jsonList[index] = jsonEncode(person.toJson());
    } else {
      jsonList.add(jsonEncode(person.toJson()));
    }

    await prefs.setStringList(_personsKey, jsonList);
  }

  /// 複数職人を一括保存
  Future<void> savePersons(List<Person> persons) async {
    for (final person in persons) {
      await savePerson(person);
    }
  }

  // ==========================================
  // 会社管理
  // ==========================================

  /// 全会社を取得
  Future<List<Company>> getAllCompanies() async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(_companiesKey) ?? [];
    return jsonList.map((json) => Company.fromJson(jsonDecode(json))).toList();
  }

  /// 会社をIDで取得
  Future<Company?> getCompanyById(String companyId) async {
    final companies = await getAllCompanies();
    try {
      return companies.firstWhere((c) => c.id == companyId);
    } catch (_) {
      return null;
    }
  }

  /// 会社を保存
  Future<void> saveCompany(Company company) async {
    final prefs = await _preferences;
    final jsonList = prefs.getStringList(_companiesKey) ?? [];

    // 既存の場合は更新
    final index = jsonList.indexWhere((json) {
      final c = Company.fromJson(jsonDecode(json));
      return c.id == company.id;
    });

    if (index >= 0) {
      jsonList[index] = jsonEncode(company.toJson());
    } else {
      jsonList.add(jsonEncode(company.toJson()));
    }

    await prefs.setStringList(_companiesKey, jsonList);
  }

  // ==========================================
  // デバイス・同期管理
  // ==========================================

  /// デバイスIDを取得（なければ生成）
  Future<String> getDeviceId() async {
    final prefs = await _preferences;
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  /// 最終同期日時を取得
  Future<DateTime?> getLastSyncAt() async {
    final prefs = await _preferences;
    final timestamp = prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// 最終同期日時を更新
  Future<void> setLastSyncAt(DateTime time) async {
    final prefs = await _preferences;
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  /// デバイスID生成
  String _generateDeviceId() {
    final now = DateTime.now();
    return 'device_${now.millisecondsSinceEpoch}_${now.hashCode.abs()}';
  }

  // ==========================================
  // データエクスポート
  // ==========================================

  /// CSV形式でエクスポート
  Future<String> exportToCsv(String projectId, DateTime start, DateTime end) async {
    final events = await getEventsByDateRange(projectId, start, end);
    final persons = await getPersonsByProject(projectId);
    final companies = await getAllCompanies();

    final personMap = {for (var p in persons) p.id: p};
    final companyMap = {for (var c in companies) c.id: c};

    final buffer = StringBuffer();
    buffer.writeln(AttendanceEvent.csvHeader);

    for (final event in events) {
      final person = personMap[event.personId];
      final company = companyMap[event.companyId];
      buffer.writeln(event.toCsvRow(
        person?.name ?? '不明',
        company?.name ?? '不明',
      ));
    }

    return buffer.toString();
  }

  // ==========================================
  // デバッグ・メンテナンス
  // ==========================================

  /// 全データをクリア（デバッグ用）
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_eventsKey);
    await prefs.remove(_personsKey);
    await prefs.remove(_companiesKey);
  }

  /// サンプルデータを生成
  Future<void> generateSampleData(String projectId) async {
    final now = DateTime.now();

    // サンプル会社
    final companies = [
      Company(
        id: 'company_1',
        name: '山田建設',
        isPending: false,
        createdAt: now,
        updatedAt: now,
      ),
      Company(
        id: 'company_2',
        name: '鈴木電工',
        isPending: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final company in companies) {
      await saveCompany(company);
    }

    // サンプル職人
    final persons = [
      Person(
        id: 'person_1',
        projectId: projectId,
        companyId: 'company_1',
        name: '山田太郎',
        jobType: JobType.carpenter,
        qrCode: 'QR001',
        createdAt: now,
        updatedAt: now,
      ),
      Person(
        id: 'person_2',
        projectId: projectId,
        companyId: 'company_1',
        name: '山田次郎',
        jobType: JobType.scaffolder,
        qrCode: 'QR002',
        createdAt: now,
        updatedAt: now,
      ),
      Person(
        id: 'person_3',
        projectId: projectId,
        companyId: 'company_2',
        name: '鈴木一郎',
        jobType: JobType.electrician,
        qrCode: 'QR003',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final person in persons) {
      await savePerson(person);
    }
  }
}
