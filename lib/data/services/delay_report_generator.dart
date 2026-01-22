/// Delay Report Generator
/// 遅延報告書自動生成サービス
///
/// 工程がズレた際、ゼネコンに送る「角が立たない報告文」を
/// AI支援で自動生成する。監督の精神的苦痛を和らげる。

import '../models/models.dart';
import '../models/phase_model.dart';

/// 遅延の原因カテゴリ
enum DelayReasonCategory {
  /// 天候（雨、台風、雪など）
  weather('weather', '天候', '天候不良'),

  /// 資材遅延
  materialDelay('material_delay', '資材', '資材調達の遅れ'),

  /// 職人の都合（病気、他現場など）
  workerUnavailable('worker_unavailable', '職人', '作業員の都合'),

  /// 設計変更
  designChange('design_change', '設計変更', '設計変更対応'),

  /// 検査待ち
  inspectionDelay('inspection_delay', '検査', '検査日程の調整'),

  /// 近隣対応
  neighborIssue('neighbor_issue', '近隣', '近隣対応'),

  /// 安全確保
  safetyMeasure('safety_measure', '安全', '安全確保のため'),

  /// その他
  other('other', 'その他', 'その他の理由');

  final String value;
  final String shortName;
  final String formalName;

  const DelayReasonCategory(this.value, this.shortName, this.formalName);

  static DelayReasonCategory fromString(String value) {
    return DelayReasonCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DelayReasonCategory.other,
    );
  }
}

/// 遅延イベント
class DelayEvent {
  /// イベントID
  final String id;

  /// プロジェクトID
  final String projectId;

  /// 影響を受けたフェーズID
  final String? phaseId;

  /// 影響を受けたタスクID（複数可）
  final List<String> affectedTaskIds;

  /// 遅延の原因カテゴリ
  final DelayReasonCategory reasonCategory;

  /// 遅延の詳細理由
  final String? reasonDetail;

  /// 遅延日数
  final int delayDays;

  /// 発生日
  final DateTime occurredAt;

  /// 報告日
  final DateTime? reportedAt;

  /// 報告済みか
  final bool isReported;

  /// 報告文
  final String? reportText;

  /// 作成日時
  final DateTime createdAt;

  const DelayEvent({
    required this.id,
    required this.projectId,
    this.phaseId,
    required this.affectedTaskIds,
    required this.reasonCategory,
    this.reasonDetail,
    required this.delayDays,
    required this.occurredAt,
    this.reportedAt,
    this.isReported = false,
    this.reportText,
    required this.createdAt,
  });

  DelayEvent copyWith({
    String? id,
    String? projectId,
    String? phaseId,
    List<String>? affectedTaskIds,
    DelayReasonCategory? reasonCategory,
    String? reasonDetail,
    int? delayDays,
    DateTime? occurredAt,
    DateTime? reportedAt,
    bool? isReported,
    String? reportText,
    DateTime? createdAt,
  }) {
    return DelayEvent(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      phaseId: phaseId ?? this.phaseId,
      affectedTaskIds: affectedTaskIds ?? this.affectedTaskIds,
      reasonCategory: reasonCategory ?? this.reasonCategory,
      reasonDetail: reasonDetail ?? this.reasonDetail,
      delayDays: delayDays ?? this.delayDays,
      occurredAt: occurredAt ?? this.occurredAt,
      reportedAt: reportedAt ?? this.reportedAt,
      isReported: isReported ?? this.isReported,
      reportText: reportText ?? this.reportText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'phaseId': phaseId,
        'affectedTaskIds': affectedTaskIds,
        'reasonCategory': reasonCategory.value,
        'reasonDetail': reasonDetail,
        'delayDays': delayDays,
        'occurredAt': occurredAt.toIso8601String(),
        'reportedAt': reportedAt?.toIso8601String(),
        'isReported': isReported,
        'reportText': reportText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DelayEvent.fromJson(Map<String, dynamic> json) {
    return DelayEvent(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      phaseId: json['phaseId'] as String?,
      affectedTaskIds: (json['affectedTaskIds'] as List).cast<String>(),
      reasonCategory:
          DelayReasonCategory.fromString(json['reasonCategory'] as String),
      reasonDetail: json['reasonDetail'] as String?,
      delayDays: json['delayDays'] as int,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      reportedAt: json['reportedAt'] != null
          ? DateTime.parse(json['reportedAt'] as String)
          : null,
      isReported: json['isReported'] as bool? ?? false,
      reportText: json['reportText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 報告書のフォーマット
enum ReportFormat {
  /// フォーマル（元請け向け公式）
  formal,

  /// セミフォーマル（協力会社向け）
  semiFormal,

  /// カジュアル（社内向け）
  casual,

  /// LINE用（短文）
  line,
}

/// 報告書生成結果
class GeneratedReport {
  /// 件名
  final String subject;

  /// 本文
  final String body;

  /// 挨拶文
  final String greeting;

  /// 締めの言葉
  final String closing;

  /// 添付ファイルの推奨
  final List<String> suggestedAttachments;

  /// フォーマット
  final ReportFormat format;

  const GeneratedReport({
    required this.subject,
    required this.body,
    required this.greeting,
    required this.closing,
    required this.suggestedAttachments,
    required this.format,
  });

  /// フルテキストを取得
  String get fullText {
    return '''$greeting

$body

$closing''';
  }

  /// LINE用短縮版
  String get lineText {
    // 300文字以内に収める
    final lines = body.split('\n').where((l) => l.trim().isNotEmpty).take(3);
    return lines.join('\n');
  }
}

/// 遅延報告書生成サービス
class DelayReportGenerator {
  /// 遅延報告書を生成
  static GeneratedReport generateReport({
    required DelayEvent event,
    required Project project,
    List<Task>? affectedTasks,
    Phase? affectedPhase,
    required ReportFormat format,
    String? recipientName,
    String? senderName,
    DateTime? newCompletionDate,
  }) {
    switch (format) {
      case ReportFormat.formal:
        return _generateFormalReport(
          event: event,
          project: project,
          affectedTasks: affectedTasks,
          affectedPhase: affectedPhase,
          recipientName: recipientName,
          senderName: senderName,
          newCompletionDate: newCompletionDate,
        );
      case ReportFormat.semiFormal:
        return _generateSemiFormalReport(
          event: event,
          project: project,
          affectedTasks: affectedTasks,
          affectedPhase: affectedPhase,
          recipientName: recipientName,
          senderName: senderName,
          newCompletionDate: newCompletionDate,
        );
      case ReportFormat.casual:
        return _generateCasualReport(
          event: event,
          project: project,
          affectedTasks: affectedTasks,
          affectedPhase: affectedPhase,
          senderName: senderName,
        );
      case ReportFormat.line:
        return _generateLineReport(
          event: event,
          project: project,
          affectedTasks: affectedTasks,
          affectedPhase: affectedPhase,
        );
    }
  }

  /// フォーマル報告書（元請け向け）
  static GeneratedReport _generateFormalReport({
    required DelayEvent event,
    required Project project,
    List<Task>? affectedTasks,
    Phase? affectedPhase,
    String? recipientName,
    String? senderName,
    DateTime? newCompletionDate,
  }) {
    final dateStr = _formatDate(event.occurredAt);
    final reasonText = _getReasonText(event.reasonCategory, event.reasonDetail);
    final phaseName = affectedPhase?.name ?? '該当工程';

    final subject = '【工程変更のお知らせ】${project.name}邸 $phaseName について';

    final greeting = '''${recipientName ?? '関係者'}各位

平素より大変お世話になっております。
${senderName ?? '担当'}でございます。''';

    final body = '''標記の件につきまして、下記の通りご報告申し上げます。

【物件名】${project.name}
【発生日】$dateStr
【事由】$reasonText
【影響工程】$phaseName
【工程変更】${event.delayDays}日間の延長

${_getDetailedExplanation(event.reasonCategory, event.delayDays)}

${newCompletionDate != null ? '【変更後完了予定日】${_formatDate(newCompletionDate)}' : ''}

今後の工程につきましては、${_getRecoveryPlan(event.reasonCategory)}、
工期への影響を最小限に抑えるよう努めてまいります。

ご不便をおかけいたしますが、何卒ご理解賜りますようお願い申し上げます。''';

    final closing = '''ご不明な点がございましたら、お気軽にお問い合わせください。

今後ともよろしくお願い申し上げます。''';

    return GeneratedReport(
      subject: subject,
      body: body,
      greeting: greeting,
      closing: closing,
      suggestedAttachments: _getSuggestedAttachments(event.reasonCategory),
      format: ReportFormat.formal,
    );
  }

  /// セミフォーマル報告書（協力会社向け）
  static GeneratedReport _generateSemiFormalReport({
    required DelayEvent event,
    required Project project,
    List<Task>? affectedTasks,
    Phase? affectedPhase,
    String? recipientName,
    String? senderName,
    DateTime? newCompletionDate,
  }) {
    final dateStr = _formatDate(event.occurredAt);
    final phaseName = affectedPhase?.name ?? '該当工程';

    final subject = '【日程変更】${project.name}邸 ${event.delayDays}日延長のご連絡';

    final greeting = '''${recipientName ?? '各位'}

お疲れ様です。${senderName ?? ''}です。''';

    final body = '''${project.name}邸の日程変更についてご連絡いたします。

■ 変更内容
・対象：$phaseName
・変更：${event.delayDays}日間延長
・理由：${_getReasonText(event.reasonCategory, event.reasonDetail)}

${affectedTasks != null && affectedTasks.isNotEmpty ? '''■ 影響するタスク
${affectedTasks.take(5).map((t) => '・${t.name}').join('\n')}
${affectedTasks.length > 5 ? '他${affectedTasks.length - 5}件' : ''}''' : ''}

${newCompletionDate != null ? '■ 変更後の予定\n完了予定：${_formatDate(newCompletionDate)}' : ''}

ご都合の確認をお願いいたします。
問題がある場合は早めにご連絡ください。''';

    final closing = '''よろしくお願いいたします。''';

    return GeneratedReport(
      subject: subject,
      body: body,
      greeting: greeting,
      closing: closing,
      suggestedAttachments: [],
      format: ReportFormat.semiFormal,
    );
  }

  /// カジュアル報告書（社内向け）
  static GeneratedReport _generateCasualReport({
    required DelayEvent event,
    required Project project,
    List<Task>? affectedTasks,
    Phase? affectedPhase,
    String? senderName,
  }) {
    final phaseName = affectedPhase?.name ?? '該当工程';

    final subject = '${project.name}邸 日程変更（${event.delayDays}日）';

    final greeting = 'お疲れ様です。';

    final body = '''${project.name}邸の$phaseNameが${event.delayDays}日延びます。

理由：${_getReasonText(event.reasonCategory, event.reasonDetail)}

${affectedTasks != null && affectedTasks.isNotEmpty ? '''影響タスク：
${affectedTasks.take(3).map((t) => '- ${t.name}').join('\n')}''' : ''}

元請けへは報告済みです。''';

    final closing = '';

    return GeneratedReport(
      subject: subject,
      body: body,
      greeting: greeting,
      closing: closing,
      suggestedAttachments: [],
      format: ReportFormat.casual,
    );
  }

  /// LINE用短文報告
  static GeneratedReport _generateLineReport({
    required DelayEvent event,
    required Project project,
    List<Task>? affectedTasks,
    Phase? affectedPhase,
  }) {
    final phaseName = affectedPhase?.name ?? '工程';
    final reasonShort = event.reasonCategory.shortName;

    final subject = '';

    final greeting = '';

    final body = '''【日程変更】${project.name}邸
$phaseNameが${event.delayDays}日延長
理由：$reasonShort
${event.reasonDetail != null ? '（${event.reasonDetail}）' : ''}''';

    final closing = '';

    return GeneratedReport(
      subject: subject,
      body: body,
      greeting: greeting,
      closing: closing,
      suggestedAttachments: [],
      format: ReportFormat.line,
    );
  }

  /// 原因カテゴリからテキストを生成
  static String _getReasonText(
    DelayReasonCategory category,
    String? detail,
  ) {
    final base = category.formalName;
    if (detail != null && detail.isNotEmpty) {
      return '$base（$detail）';
    }
    return base;
  }

  /// 詳細説明文を生成
  static String _getDetailedExplanation(
    DelayReasonCategory category,
    int delayDays,
  ) {
    switch (category) {
      case DelayReasonCategory.weather:
        return '悪天候により屋外作業が困難な状況となり、安全確保の観点から作業を見合わせました。';
      case DelayReasonCategory.materialDelay:
        return '資材の入荷遅延が発生しており、入荷後速やかに作業を再開いたします。';
      case DelayReasonCategory.workerUnavailable:
        return '作業員の都合により、代替作業員の手配を行っております。';
      case DelayReasonCategory.designChange:
        return '設計変更に伴う確認・調整作業が発生しております。';
      case DelayReasonCategory.inspectionDelay:
        return '検査機関との日程調整に時間を要しております。';
      case DelayReasonCategory.neighborIssue:
        return '近隣住民様へのご説明・対応を優先しております。';
      case DelayReasonCategory.safetyMeasure:
        return '現場の安全確保のため、必要な措置を講じております。';
      default:
        return '諸般の事情により、工程の見直しが必要となりました。';
    }
  }

  /// 回復計画テキストを生成
  static String _getRecoveryPlan(DelayReasonCategory category) {
    switch (category) {
      case DelayReasonCategory.weather:
        return '天候回復後、可能な範囲で作業時間の延長・人員増強を検討し';
      case DelayReasonCategory.materialDelay:
        return '資材入荷後、並行作業の実施を検討し';
      case DelayReasonCategory.workerUnavailable:
        return '代替要員の確保と作業体制の見直しを行い';
      default:
        return '関係者と連携し、代替案の検討を進め';
    }
  }

  /// 推奨添付ファイルを取得
  static List<String> _getSuggestedAttachments(DelayReasonCategory category) {
    switch (category) {
      case DelayReasonCategory.weather:
        return ['天気予報のスクリーンショット', '現場写真'];
      case DelayReasonCategory.materialDelay:
        return ['発注書のコピー', '納品予定の連絡'];
      case DelayReasonCategory.designChange:
        return ['変更図面', '打合せ記録'];
      case DelayReasonCategory.inspectionDelay:
        return ['検査予約確認書'];
      default:
        return [];
    }
  }

  /// 日付フォーマット
  static String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  /// 複数の遅延イベントから週報を生成
  static String generateWeeklySummary({
    required Project project,
    required List<DelayEvent> events,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    if (events.isEmpty) {
      return '''【週報】${project.name}邸（${_formatDate(weekStart)}〜${_formatDate(weekEnd)}）

今週の工程遅延はありませんでした。
予定通り進捗しております。''';
    }

    final totalDelayDays = events.fold<int>(0, (sum, e) => sum + e.delayDays);
    final categorySummary = <DelayReasonCategory, int>{};
    for (final event in events) {
      categorySummary[event.reasonCategory] =
          (categorySummary[event.reasonCategory] ?? 0) + event.delayDays;
    }

    final categoryLines = categorySummary.entries
        .map((e) => '・${e.key.shortName}：${e.value}日')
        .join('\n');

    return '''【週報】${project.name}邸（${_formatDate(weekStart)}〜${_formatDate(weekEnd)}）

■ 工程変更サマリ
・発生件数：${events.length}件
・累計遅延：${totalDelayDays}日

■ 内訳
$categoryLines

■ 対応状況
${events.where((e) => e.isReported).length}/${events.length}件 報告済み''';
  }
}
