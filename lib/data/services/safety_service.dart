/// Safety Management Service
/// 安全管理サービス - KY活動、ヒヤリハット、安全パトロールのデータ管理

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../models/safety_models.dart';

class SafetyService extends ChangeNotifier {
  static const String _kyRecordsKey = 'ky_activity_records';
  static const String _nearMissKey = 'near_miss_reports';
  static const String _patrolRecordsKey = 'safety_patrol_records';

  SharedPreferences? _prefs;
  bool _initialized = false;

  List<KYActivityRecord> _kyRecords = [];
  List<NearMissReport> _nearMissReports = [];
  List<SafetyPatrolRecord> _patrolRecords = [];

  final _uuid = const Uuid();

  // Getters
  List<KYActivityRecord> get kyRecords => List.unmodifiable(_kyRecords);
  List<NearMissReport> get nearMissReports => List.unmodifiable(_nearMissReports);
  List<SafetyPatrolRecord> get patrolRecords => List.unmodifiable(_patrolRecords);

  /// 初期化
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadAllData();
    _initialized = true;

    // モックデータがない場合は生成
    if (_kyRecords.isEmpty && _nearMissReports.isEmpty && _patrolRecords.isEmpty) {
      _generateMockData();
    }

    notifyListeners();
  }

  Future<void> _loadAllData() async {
    // KY活動記録
    final kyJson = _prefs?.getString(_kyRecordsKey);
    if (kyJson != null) {
      final List<dynamic> list = json.decode(kyJson);
      _kyRecords = list.map((e) => KYActivityRecord.fromJson(e)).toList();
    }

    // ヒヤリハット
    final nmJson = _prefs?.getString(_nearMissKey);
    if (nmJson != null) {
      final List<dynamic> list = json.decode(nmJson);
      _nearMissReports = list.map((e) => NearMissReport.fromJson(e)).toList();
    }

    // 安全パトロール
    final patrolJson = _prefs?.getString(_patrolRecordsKey);
    if (patrolJson != null) {
      final List<dynamic> list = json.decode(patrolJson);
      _patrolRecords = list.map((e) => SafetyPatrolRecord.fromJson(e)).toList();
    }
  }

  Future<void> _saveKYRecords() async {
    await _prefs?.setString(
      _kyRecordsKey,
      json.encode(_kyRecords.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveNearMissReports() async {
    await _prefs?.setString(
      _nearMissKey,
      json.encode(_nearMissReports.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _savePatrolRecords() async {
    await _prefs?.setString(
      _patrolRecordsKey,
      json.encode(_patrolRecords.map((e) => e.toJson()).toList()),
    );
  }

  // ===========================================
  // KY活動記録
  // ===========================================

  /// KY活動記録を追加
  Future<KYActivityRecord> addKYRecord({
    required String projectId,
    required DateTime date,
    required String workContent,
    required List<HazardItem> hazardItems,
    required List<String> participantIds,
    List<String> photoUrls = const [],
    String? weatherCondition,
    String? location,
    required String createdById,
  }) async {
    final now = DateTime.now();
    final record = KYActivityRecord(
      id: _uuid.v4(),
      projectId: projectId,
      date: date,
      workContent: workContent,
      hazardItems: hazardItems,
      participantIds: participantIds,
      photoUrls: photoUrls,
      weatherCondition: weatherCondition,
      location: location,
      createdById: createdById,
      createdAt: now,
      updatedAt: now,
    );

    _kyRecords.insert(0, record);
    await _saveKYRecords();
    notifyListeners();
    return record;
  }

  /// KY活動記録を更新
  Future<void> updateKYRecord(KYActivityRecord record) async {
    final index = _kyRecords.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      _kyRecords[index] = record.copyWith(updatedAt: DateTime.now());
      await _saveKYRecords();
      notifyListeners();
    }
  }

  /// KY活動記録を削除
  Future<void> deleteKYRecord(String id) async {
    _kyRecords.removeWhere((r) => r.id == id);
    await _saveKYRecords();
    notifyListeners();
  }

  /// プロジェクト別KY活動記録を取得
  List<KYActivityRecord> getKYRecordsByProject(String projectId) {
    return _kyRecords.where((r) => r.projectId == projectId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// 日付別KY活動記録を取得
  KYActivityRecord? getKYRecordByDate(String projectId, DateTime date) {
    try {
      return _kyRecords.firstWhere(
        (r) =>
            r.projectId == projectId &&
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  // ===========================================
  // ヒヤリハット報告
  // ===========================================

  /// ヒヤリハット報告を追加
  Future<NearMissReport> addNearMissReport({
    required String projectId,
    required DateTime occurredAt,
    required String location,
    required String description,
    required String causeAnalysis,
    required String countermeasure,
    required NearMissSeverity severity,
    NearMissCategory category = NearMissCategory.other,
    List<String> photoUrls = const [],
    required String reporterId,
  }) async {
    final now = DateTime.now();
    final report = NearMissReport(
      id: _uuid.v4(),
      projectId: projectId,
      occurredAt: occurredAt,
      location: location,
      description: description,
      causeAnalysis: causeAnalysis,
      countermeasure: countermeasure,
      severity: severity,
      category: category,
      photoUrls: photoUrls,
      reporterId: reporterId,
      createdAt: now,
      updatedAt: now,
    );

    _nearMissReports.insert(0, report);
    await _saveNearMissReports();
    notifyListeners();
    return report;
  }

  /// ヒヤリハット報告を更新
  Future<void> updateNearMissReport(NearMissReport report) async {
    final index = _nearMissReports.indexWhere((r) => r.id == report.id);
    if (index >= 0) {
      _nearMissReports[index] = report.copyWith(updatedAt: DateTime.now());
      await _saveNearMissReports();
      notifyListeners();
    }
  }

  /// ヒヤリハット確認
  Future<void> reviewNearMissReport({
    required String reportId,
    required String reviewedById,
    required String comment,
    required NearMissStatus newStatus,
  }) async {
    final index = _nearMissReports.indexWhere((r) => r.id == reportId);
    if (index >= 0) {
      _nearMissReports[index] = _nearMissReports[index].copyWith(
        reviewedById: reviewedById,
        reviewedAt: DateTime.now(),
        reviewComment: comment,
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await _saveNearMissReports();
      notifyListeners();
    }
  }

  /// ヒヤリハット報告を削除
  Future<void> deleteNearMissReport(String id) async {
    _nearMissReports.removeWhere((r) => r.id == id);
    await _saveNearMissReports();
    notifyListeners();
  }

  /// プロジェクト別ヒヤリハット報告を取得
  List<NearMissReport> getNearMissReportsByProject(String projectId) {
    return _nearMissReports.where((r) => r.projectId == projectId).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  /// 重要度別ヒヤリハット報告を取得
  List<NearMissReport> getNearMissReportsBySeverity(
      String projectId, NearMissSeverity severity) {
    return _nearMissReports
        .where((r) => r.projectId == projectId && r.severity == severity)
        .toList();
  }

  /// 未対応ヒヤリハット数
  int getUnresolvedNearMissCount(String projectId) {
    return _nearMissReports
        .where((r) =>
            r.projectId == projectId &&
            (r.status == NearMissStatus.reported ||
                r.status == NearMissStatus.reviewing))
        .length;
  }

  // ===========================================
  // 安全パトロール
  // ===========================================

  /// 安全パトロール記録を追加
  Future<SafetyPatrolRecord> addPatrolRecord({
    required String projectId,
    required DateTime patrolDate,
    required String patrollerName,
    required String patrollerId,
    List<PatrolCheckItem>? checkItems,
  }) async {
    final now = DateTime.now();
    final record = SafetyPatrolRecord(
      id: _uuid.v4(),
      projectId: projectId,
      patrolDate: patrolDate,
      patrollerName: patrollerName,
      patrollerId: patrollerId,
      checkItems: checkItems ?? SafetyChecklistTemplates.getStandardChecklist(),
      createdAt: now,
      updatedAt: now,
    );

    _patrolRecords.insert(0, record);
    await _savePatrolRecords();
    notifyListeners();
    return record;
  }

  /// 安全パトロール記録を更新
  Future<void> updatePatrolRecord(SafetyPatrolRecord record) async {
    final index = _patrolRecords.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      _patrolRecords[index] = record.copyWith(updatedAt: DateTime.now());
      await _savePatrolRecords();
      notifyListeners();
    }
  }

  /// チェック項目を更新
  Future<void> updatePatrolCheckItem({
    required String patrolId,
    required String checkItemId,
    required CheckResult result,
    String? comment,
  }) async {
    final patrolIndex = _patrolRecords.indexWhere((r) => r.id == patrolId);
    if (patrolIndex >= 0) {
      final patrol = _patrolRecords[patrolIndex];
      final updatedItems = patrol.checkItems.map((item) {
        if (item.id == checkItemId) {
          return item.copyWith(result: result, comment: comment);
        }
        return item;
      }).toList();

      _patrolRecords[patrolIndex] = patrol.copyWith(
        checkItems: updatedItems,
        updatedAt: DateTime.now(),
      );
      await _savePatrolRecords();
      notifyListeners();
    }
  }

  /// 不適合箇所を追加
  Future<void> addNonConformance({
    required String patrolId,
    required String location,
    required String description,
    List<String> photoUrls = const [],
  }) async {
    final patrolIndex = _patrolRecords.indexWhere((r) => r.id == patrolId);
    if (patrolIndex >= 0) {
      final patrol = _patrolRecords[patrolIndex];
      final newItem = NonConformanceItem(
        id: _uuid.v4(),
        location: location,
        description: description,
        photoUrls: photoUrls,
      );

      _patrolRecords[patrolIndex] = patrol.copyWith(
        nonConformances: [...patrol.nonConformances, newItem],
        updatedAt: DateTime.now(),
      );
      await _savePatrolRecords();
      notifyListeners();
    }
  }

  /// 是正確認
  Future<void> confirmCorrection({
    required String patrolId,
    required String nonConformanceId,
    required String correctiveAction,
    required String correctedById,
    List<String>? correctionPhotoUrls,
  }) async {
    final patrolIndex = _patrolRecords.indexWhere((r) => r.id == patrolId);
    if (patrolIndex >= 0) {
      final patrol = _patrolRecords[patrolIndex];
      final updatedNonConformances = patrol.nonConformances.map((item) {
        if (item.id == nonConformanceId) {
          return item.copyWith(
            correctiveAction: correctiveAction,
            correctionStatus: CorrectionStatus.verified,
            correctedAt: DateTime.now(),
            correctedById: correctedById,
            correctionPhotoUrls: correctionPhotoUrls,
          );
        }
        return item;
      }).toList();

      _patrolRecords[patrolIndex] = patrol.copyWith(
        nonConformances: updatedNonConformances,
        updatedAt: DateTime.now(),
      );
      await _savePatrolRecords();
      notifyListeners();
    }
  }

  /// パトロール完了
  Future<void> completePatrol({
    required String patrolId,
    required PatrolResult result,
    String? comment,
  }) async {
    final patrolIndex = _patrolRecords.indexWhere((r) => r.id == patrolId);
    if (patrolIndex >= 0) {
      _patrolRecords[patrolIndex] = _patrolRecords[patrolIndex].copyWith(
        overallResult: result,
        overallComment: comment,
        updatedAt: DateTime.now(),
      );
      await _savePatrolRecords();
      notifyListeners();
    }
  }

  /// 安全パトロール記録を削除
  Future<void> deletePatrolRecord(String id) async {
    _patrolRecords.removeWhere((r) => r.id == id);
    await _savePatrolRecords();
    notifyListeners();
  }

  /// プロジェクト別安全パトロール記録を取得
  List<SafetyPatrolRecord> getPatrolRecordsByProject(String projectId) {
    return _patrolRecords.where((r) => r.projectId == projectId).toList()
      ..sort((a, b) => b.patrolDate.compareTo(a.patrolDate));
  }

  /// 未是正の不適合数
  int getPendingCorrectionCount(String projectId) {
    int count = 0;
    for (final patrol in _patrolRecords.where((r) => r.projectId == projectId)) {
      count += patrol.nonConformances
          .where((n) =>
              n.correctionStatus == CorrectionStatus.pending ||
              n.correctionStatus == CorrectionStatus.inProgress)
          .length;
    }
    return count;
  }

  // ===========================================
  // 統計・サマリー
  // ===========================================

  /// 安全統計サマリーを取得
  SafetySummary getSafetySummary(String projectId) {
    final kyCount = getKYRecordsByProject(projectId).length;
    final nearMissCount = getNearMissReportsByProject(projectId).length;
    final patrolCount = getPatrolRecordsByProject(projectId).length;
    final unresolvedNearMiss = getUnresolvedNearMissCount(projectId);
    final pendingCorrections = getPendingCorrectionCount(projectId);

    // 重要度別ヒヤリハット
    final highSeverity = getNearMissReportsBySeverity(projectId, NearMissSeverity.high).length;
    final mediumSeverity = getNearMissReportsBySeverity(projectId, NearMissSeverity.medium).length;
    final lowSeverity = getNearMissReportsBySeverity(projectId, NearMissSeverity.low).length;

    return SafetySummary(
      kyActivityCount: kyCount,
      nearMissCount: nearMissCount,
      patrolCount: patrolCount,
      unresolvedNearMissCount: unresolvedNearMiss,
      pendingCorrectionCount: pendingCorrections,
      highSeverityCount: highSeverity,
      mediumSeverityCount: mediumSeverity,
      lowSeverityCount: lowSeverity,
    );
  }

  // ===========================================
  // モックデータ生成
  // ===========================================

  void _generateMockData() {
    final now = DateTime.now();
    const projectId = 'project_1';

    // KY活動記録
    _kyRecords = [
      KYActivityRecord(
        id: _uuid.v4(),
        projectId: projectId,
        date: now,
        workContent: '外壁足場組立作業',
        hazardItems: [
          HazardItem(
            id: '1',
            hazardDescription: '足場材の落下により下で作業中の作業員に当たる',
            countermeasure: '下部に立入禁止区域を設定、上下作業の禁止',
            category: HazardCategory.collision,
          ),
          HazardItem(
            id: '2',
            hazardDescription: '足場からの墜落',
            countermeasure: 'フルハーネス着用、手すり先行工法の採用',
            category: HazardCategory.falling,
          ),
        ],
        participantIds: ['user_1', 'user_2', 'user_3'],
        weatherCondition: '晴れ',
        location: 'A棟南面',
        createdById: 'user_1',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      KYActivityRecord(
        id: _uuid.v4(),
        projectId: projectId,
        date: now.subtract(const Duration(days: 1)),
        workContent: 'コンクリート打設作業',
        hazardItems: [
          HazardItem(
            id: '3',
            hazardDescription: 'ポンプ車のブーム旋回により接触',
            countermeasure: '旋回範囲に立入禁止区域設定、誘導員配置',
            category: HazardCategory.caught,
          ),
        ],
        participantIds: ['user_1', 'user_4'],
        weatherCondition: '曇り',
        location: '2階床スラブ',
        createdById: 'user_1',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    // ヒヤリハット報告
    _nearMissReports = [
      NearMissReport(
        id: _uuid.v4(),
        projectId: projectId,
        occurredAt: now.subtract(const Duration(days: 2, hours: 10)),
        location: 'B棟1階',
        description: '資材運搬中、床の開口部養生板が外れており、足を踏み外しそうになった',
        causeAnalysis: '養生板の固定が不十分だった。前日の作業で一時的に外した後、固定し忘れた。',
        countermeasure: '養生板の取り外し・設置時のチェックリスト導入。取り外し作業後の確認を義務化。',
        severity: NearMissSeverity.high,
        category: NearMissCategory.falling,
        reporterId: 'user_2',
        status: NearMissStatus.reviewing,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      NearMissReport(
        id: _uuid.v4(),
        projectId: projectId,
        occurredAt: now.subtract(const Duration(days: 5, hours: 14)),
        location: '資材置き場',
        description: 'フォークリフトがバック走行中、後方を歩いていた作業員と接触しそうになった',
        causeAnalysis: '誘導員なしでフォークリフトを運転していた。後方確認が不十分だった。',
        countermeasure: 'フォークリフト使用時は必ず誘導員を配置。バック走行時の警報装置の確認。',
        severity: NearMissSeverity.medium,
        category: NearMissCategory.vehicle,
        reporterId: 'user_3',
        status: NearMissStatus.resolved,
        reviewedById: 'user_1',
        reviewedAt: now.subtract(const Duration(days: 4)),
        reviewComment: '対策を実施済み。全作業員に周知完了。',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    // 安全パトロール記録
    final checkItems = SafetyChecklistTemplates.getStandardChecklist();
    // いくつかチェック済みにする
    final checkedItems = checkItems.asMap().map((index, item) {
      if (index < 10) {
        return MapEntry(index, item.copyWith(result: CheckResult.conform));
      } else if (index == 10) {
        return MapEntry(
            index, item.copyWith(result: CheckResult.nonConform, comment: '一部固定不良あり'));
      }
      return MapEntry(index, item);
    }).values.toList();

    _patrolRecords = [
      SafetyPatrolRecord(
        id: _uuid.v4(),
        projectId: projectId,
        patrolDate: now,
        patrollerName: '山田太郎',
        patrollerId: 'user_1',
        checkItems: checkedItems,
        nonConformances: [
          NonConformanceItem(
            id: _uuid.v4(),
            location: 'A棟3階足場',
            description: '中さんの固定ボルトが緩んでいる箇所あり',
            correctionStatus: CorrectionStatus.pending,
          ),
        ],
        overallResult: PatrolResult.pending,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    notifyListeners();
  }

  void dispose() {
    // Cleanup if needed
  }
}

/// 安全統計サマリー
class SafetySummary {
  final int kyActivityCount;
  final int nearMissCount;
  final int patrolCount;
  final int unresolvedNearMissCount;
  final int pendingCorrectionCount;
  final int highSeverityCount;
  final int mediumSeverityCount;
  final int lowSeverityCount;

  const SafetySummary({
    required this.kyActivityCount,
    required this.nearMissCount,
    required this.patrolCount,
    required this.unresolvedNearMissCount,
    required this.pendingCorrectionCount,
    required this.highSeverityCount,
    required this.mediumSeverityCount,
    required this.lowSeverityCount,
  });

  /// 要注意フラグ
  bool get hasWarnings =>
      unresolvedNearMissCount > 0 ||
      pendingCorrectionCount > 0 ||
      highSeverityCount > 0;
}
