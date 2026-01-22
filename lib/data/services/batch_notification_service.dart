/// Batch Notification Service
/// GAS 6分制限対策のためのキューベース一括通知処理
///
/// Geminiレビュー指摘事項:
/// - 職人100人に一斉送信するとUrlFetchAppのループで6分超え
/// - 対策：送信処理を「キュー」に入れ、小分けに実行するロジック
/// - 同時書き込み（排他制御）の問題も考慮

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 通知タイプ
enum BatchNotificationType {
  /// スケジュール変更
  scheduleChange('schedule_change', 'スケジュール変更'),

  /// 雨天中止
  rainCancellation('rain_cancellation', '雨天中止'),

  /// リマインダー
  reminder('reminder', 'リマインダー'),

  /// 緊急連絡
  urgent('urgent', '緊急連絡');

  final String value;
  final String displayName;

  const BatchNotificationType(this.value, this.displayName);
}

/// 通知先
class NotificationRecipient {
  final String id;
  final String name;
  final String lineUid;
  final String? phoneNumber;

  const NotificationRecipient({
    required this.id,
    required this.name,
    required this.lineUid,
    this.phoneNumber,
  });

  factory NotificationRecipient.fromJson(Map<String, dynamic> json) {
    return NotificationRecipient(
      id: json['id'] as String,
      name: json['name'] as String,
      lineUid: json['lineUid'] as String,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lineUid': lineUid,
        'phoneNumber': phoneNumber,
      };
}

/// バッチ通知ジョブ
class NotificationJob {
  /// ジョブID
  final String id;

  /// 通知タイプ
  final BatchNotificationType type;

  /// プロジェクトID
  final String projectId;

  /// 送信メッセージ
  final String message;

  /// 送信先リスト
  final List<NotificationRecipient> recipients;

  /// 作成日時
  final DateTime createdAt;

  /// ステータス
  final JobStatus status;

  /// 処理済み数
  final int processedCount;

  /// 成功数
  final int successCount;

  /// 失敗数
  final int failedCount;

  /// エラーメッセージ
  final String? errorMessage;

  /// 完了日時
  final DateTime? completedAt;

  const NotificationJob({
    required this.id,
    required this.type,
    required this.projectId,
    required this.message,
    required this.recipients,
    required this.createdAt,
    this.status = JobStatus.pending,
    this.processedCount = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    this.completedAt,
  });

  factory NotificationJob.fromJson(Map<String, dynamic> json) {
    return NotificationJob(
      id: json['id'] as String,
      type: BatchNotificationType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => BatchNotificationType.scheduleChange,
      ),
      projectId: json['projectId'] as String,
      message: json['message'] as String,
      recipients: (json['recipients'] as List<dynamic>)
          .map((r) => NotificationRecipient.fromJson(r as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: JobStatus.fromString(json['status'] as String? ?? 'pending'),
      processedCount: json['processedCount'] as int? ?? 0,
      successCount: json['successCount'] as int? ?? 0,
      failedCount: json['failedCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'projectId': projectId,
        'message': message,
        'recipients': recipients.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'status': status.value,
        'processedCount': processedCount,
        'successCount': successCount,
        'failedCount': failedCount,
        'errorMessage': errorMessage,
        'completedAt': completedAt?.toIso8601String(),
      };

  NotificationJob copyWith({
    String? id,
    BatchNotificationType? type,
    String? projectId,
    String? message,
    List<NotificationRecipient>? recipients,
    DateTime? createdAt,
    JobStatus? status,
    int? processedCount,
    int? successCount,
    int? failedCount,
    String? errorMessage,
    DateTime? completedAt,
  }) {
    return NotificationJob(
      id: id ?? this.id,
      type: type ?? this.type,
      projectId: projectId ?? this.projectId,
      message: message ?? this.message,
      recipients: recipients ?? this.recipients,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      processedCount: processedCount ?? this.processedCount,
      successCount: successCount ?? this.successCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: errorMessage ?? this.errorMessage,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 完了率
  double get completionRate {
    if (recipients.isEmpty) return 0;
    return processedCount / recipients.length;
  }

  /// 成功率
  double get successRate {
    if (processedCount == 0) return 0;
    return successCount / processedCount;
  }
}

/// ジョブステータス
enum JobStatus {
  /// 待機中
  pending('pending'),

  /// 処理中
  processing('processing'),

  /// 完了
  completed('completed'),

  /// 部分的に失敗
  partiallyFailed('partially_failed'),

  /// 失敗
  failed('failed'),

  /// キャンセル
  cancelled('cancelled');

  final String value;

  const JobStatus(this.value);

  static JobStatus fromString(String value) {
    return JobStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => JobStatus.pending,
    );
  }
}

/// バッチ通知サービス設定
class BatchNotificationConfig {
  /// バッチサイズ（一度に処理する件数）
  /// GAS 6分制限を考慮して、1バッチ20件程度が安全
  final int batchSize;

  /// バッチ間の待機時間（ミリ秒）
  /// GAS実行トリガーの間隔を考慮
  final int batchDelayMs;

  /// 最大同時バッチ数
  final int maxConcurrentBatches;

  /// リトライ回数
  final int maxRetries;

  /// APIエンドポイント
  final String apiBaseUrl;

  const BatchNotificationConfig({
    this.batchSize = 20,
    this.batchDelayMs = 1000,
    this.maxConcurrentBatches = 1,
    this.maxRetries = 3,
    this.apiBaseUrl = '/api',
  });
}

/// バッチ通知サービス
class BatchNotificationService {
  static const String _jobsStorageKey = 'batch_notification_jobs';

  final BatchNotificationConfig config;
  final Random _random = Random();

  final _jobsController = StreamController<List<NotificationJob>>.broadcast();
  List<NotificationJob> _jobs = [];
  bool _isProcessing = false;

  /// ジョブリストストリーム（UIバインディング用）
  Stream<List<NotificationJob>> get jobsStream => _jobsController.stream;

  /// 現在のジョブリスト
  List<NotificationJob> get jobs => _jobs;

  BatchNotificationService({
    this.config = const BatchNotificationConfig(),
  });

  /// 初期化
  Future<void> initialize() async {
    await _loadJobs();
  }

  /// ジョブを更新
  void _updateJobs(List<NotificationJob> jobs) {
    _jobs = jobs;
    _jobsController.add(jobs);
    _persistJobs();
  }

  /// 通知ジョブを作成
  Future<NotificationJob> createJob({
    required BatchNotificationType type,
    required String projectId,
    required String message,
    required List<NotificationRecipient> recipients,
  }) async {
    final job = NotificationJob(
      id: _generateId(),
      type: type,
      projectId: projectId,
      message: message,
      recipients: recipients,
      createdAt: DateTime.now(),
    );

    _updateJobs([..._jobs, job]);

    // 自動処理開始
    _processNextJob();

    return job;
  }

  /// 次のジョブを処理
  Future<void> _processNextJob() async {
    if (_isProcessing) return;

    final pendingJob = _jobs.firstWhere(
      (j) => j.status == JobStatus.pending,
      orElse: () => NotificationJob(
        id: '',
        type: BatchNotificationType.scheduleChange,
        projectId: '',
        message: '',
        recipients: [],
        createdAt: DateTime.now(),
        status: JobStatus.completed,
      ),
    );

    if (pendingJob.id.isEmpty) return;

    _isProcessing = true;
    await _processJob(pendingJob);
    _isProcessing = false;

    // 次のジョブがあれば続けて処理
    _processNextJob();
  }

  /// ジョブを処理（バッチ分割）
  Future<void> _processJob(NotificationJob job) async {
    // ステータスを処理中に更新
    _updateJobStatus(job.id, JobStatus.processing);

    final recipients = job.recipients;
    final batches = _splitIntoBatches(recipients, config.batchSize);

    int processedCount = 0;
    int successCount = 0;
    int failedCount = 0;

    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];

      try {
        // バッチを送信
        final result = await _sendBatch(job, batch);
        successCount += result.successCount;
        failedCount += result.failedCount;
      } catch (e) {
        failedCount += batch.length;
        if (kDebugMode) {
          print('Batch $i failed: $e');
        }
      }

      processedCount += batch.length;

      // 進捗を更新
      _updateJobProgress(
        job.id,
        processedCount: processedCount,
        successCount: successCount,
        failedCount: failedCount,
      );

      // バッチ間の待機（GAS制限対策）
      if (i < batches.length - 1) {
        await Future.delayed(Duration(milliseconds: config.batchDelayMs));
      }
    }

    // 最終ステータスを決定
    final finalStatus = failedCount == 0
        ? JobStatus.completed
        : failedCount == recipients.length
            ? JobStatus.failed
            : JobStatus.partiallyFailed;

    _updateJobFinal(job.id, finalStatus);
  }

  /// リストをバッチに分割
  List<List<NotificationRecipient>> _splitIntoBatches(
    List<NotificationRecipient> items,
    int batchSize,
  ) {
    final batches = <List<NotificationRecipient>>[];
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }

  /// バッチを送信
  Future<BatchResult> _sendBatch(
    NotificationJob job,
    List<NotificationRecipient> batch,
  ) async {
    // TODO: 実際のGAS/LINE API呼び出し
    // 現在はモック実装
    await Future.delayed(const Duration(milliseconds: 500));

    // モック: 95%成功率
    int success = 0;
    int failed = 0;

    for (final recipient in batch) {
      if (_random.nextDouble() < 0.95) {
        success++;
      } else {
        failed++;
      }
    }

    return BatchResult(successCount: success, failedCount: failed);
  }

  /// ジョブステータスを更新
  void _updateJobStatus(String jobId, JobStatus status) {
    final newJobs = _jobs.map((j) {
      if (j.id == jobId) {
        return j.copyWith(status: status);
      }
      return j;
    }).toList();

    _updateJobs(newJobs);
  }

  /// ジョブ進捗を更新
  void _updateJobProgress(
    String jobId, {
    required int processedCount,
    required int successCount,
    required int failedCount,
  }) {
    final newJobs = _jobs.map((j) {
      if (j.id == jobId) {
        return j.copyWith(
          processedCount: processedCount,
          successCount: successCount,
          failedCount: failedCount,
        );
      }
      return j;
    }).toList();

    _updateJobs(newJobs);
  }

  /// ジョブ完了を更新
  void _updateJobFinal(String jobId, JobStatus status) {
    final newJobs = _jobs.map((j) {
      if (j.id == jobId) {
        return j.copyWith(
          status: status,
          completedAt: DateTime.now(),
        );
      }
      return j;
    }).toList();

    _updateJobs(newJobs);
  }

  /// ジョブをキャンセル
  void cancelJob(String jobId) {
    final newJobs = _jobs.map((j) {
      if (j.id == jobId && j.status == JobStatus.pending) {
        return j.copyWith(status: JobStatus.cancelled);
      }
      return j;
    }).toList();

    _updateJobs(newJobs);
  }

  /// 失敗したジョブをリトライ
  Future<void> retryJob(String jobId) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);

    if (job.status == JobStatus.failed ||
        job.status == JobStatus.partiallyFailed) {
      // 失敗した送信先だけリトライするロジックを実装可能
      // 現在は全件リトライ
      final newJob = job.copyWith(
        status: JobStatus.pending,
        processedCount: 0,
        successCount: 0,
        failedCount: 0,
        completedAt: null,
      );

      final newJobs = _jobs.map((j) => j.id == jobId ? newJob : j).toList();
      _updateJobs(newJobs);

      _processNextJob();
    }
  }

  /// 完了したジョブをクリア
  void clearCompletedJobs() {
    final newJobs = _jobs
        .where((j) =>
            j.status != JobStatus.completed &&
            j.status != JobStatus.cancelled)
        .toList();

    _updateJobs(newJobs);
  }

  /// ジョブを永続化
  Future<void> _persistJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _jobs.map((j) => j.toJson()).toList();
      await prefs.setString(_jobsStorageKey, jsonEncode(json));
    } catch (e) {
      if (kDebugMode) {
        print('Persist jobs error: $e');
      }
    }
  }

  /// ジョブを読み込み
  Future<void> _loadJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_jobsStorageKey);

      if (jsonStr != null) {
        final jsonList = jsonDecode(jsonStr) as List<dynamic>;
        _jobs = jsonList
            .map((j) => NotificationJob.fromJson(j as Map<String, dynamic>))
            .toList();
        _jobsController.add(_jobs);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Load jobs error: $e');
      }
    }
  }

  /// ユニークID生成
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'job_${timestamp}_$random';
  }

  /// リソース解放
  void dispose() {
    _jobsController.close();
  }
}

/// バッチ結果
class BatchResult {
  final int successCount;
  final int failedCount;

  const BatchResult({
    required this.successCount,
    required this.failedCount,
  });
}

/// バッチ通知サービスのシングルトンインスタンス
class BatchNotificationServiceProvider {
  static BatchNotificationService? _instance;

  static BatchNotificationService get instance {
    _instance ??= BatchNotificationService();
    return _instance!;
  }

  static Future<void> initialize(BatchNotificationConfig config) async {
    _instance = BatchNotificationService(config: config);
    await _instance!.initialize();
  }

  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
