/// Project Flow Management Models
/// Managing the workflow: 依頼 → 現調 → 仕様決定 → 品番決定 → 図面 → 金額調整 → 契約 → 着工

/// Project stage in the workflow
enum ProjectStage {
  inquiry,        // 依頼受付
  siteVisit,      // 現地調査
  specification,  // 仕様決定
  productSelect,  // 品番決定
  drawing,        // 図面作成
  pricing,        // 金額調整
  contract,       // 契約
  construction,   // 着工
  completed,      // 完工
}

extension ProjectStageExtension on ProjectStage {
  String get label {
    switch (this) {
      case ProjectStage.inquiry:
        return '依頼受付';
      case ProjectStage.siteVisit:
        return '現地調査';
      case ProjectStage.specification:
        return '仕様決定';
      case ProjectStage.productSelect:
        return '品番決定';
      case ProjectStage.drawing:
        return '図面作成';
      case ProjectStage.pricing:
        return '金額調整';
      case ProjectStage.contract:
        return '契約';
      case ProjectStage.construction:
        return '着工';
      case ProjectStage.completed:
        return '完工';
    }
  }

  String get description {
    switch (this) {
      case ProjectStage.inquiry:
        return 'お客様からの依頼を受け付け、概要を把握';
      case ProjectStage.siteVisit:
        return '現場を訪問し、現状を確認・採寸';
      case ProjectStage.specification:
        return '使用する材料・工法の仕様を決定';
      case ProjectStage.productSelect:
        return '具体的な品番・型番を選定';
      case ProjectStage.drawing:
        return '施工図面・詳細図を作成';
      case ProjectStage.pricing:
        return '見積もり作成・金額交渉';
      case ProjectStage.contract:
        return '契約締結・発注準備';
      case ProjectStage.construction:
        return '施工開始';
      case ProjectStage.completed:
        return '施工完了・引き渡し';
    }
  }

  int get order => index;

  bool isAfter(ProjectStage other) => index > other.index;
  bool isBefore(ProjectStage other) => index < other.index;

  ProjectStage? get next {
    if (index < ProjectStage.values.length - 1) {
      return ProjectStage.values[index + 1];
    }
    return null;
  }

  ProjectStage? get previous {
    if (index > 0) {
      return ProjectStage.values[index - 1];
    }
    return null;
  }
}

/// Checklist item for each stage
class StageChecklistItem {
  final String id;
  final String label;
  final String? description;
  final bool isRequired;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final String? notes;
  final List<String>? attachmentIds;

  const StageChecklistItem({
    required this.id,
    required this.label,
    this.description,
    this.isRequired = false,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    this.notes,
    this.attachmentIds,
  });

  StageChecklistItem copyWith({
    String? id,
    String? label,
    String? description,
    bool? isRequired,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    String? notes,
    List<String>? attachmentIds,
  }) {
    return StageChecklistItem(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      notes: notes ?? this.notes,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }
}

/// Stage progress tracking
class StageProgress {
  final ProjectStage stage;
  final StageStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? assigneeId;
  final List<StageChecklistItem> checklist;
  final String? notes;
  final List<String>? documentIds;  // 関連ドキュメント

  const StageProgress({
    required this.stage,
    this.status = StageStatus.notStarted,
    this.startedAt,
    this.completedAt,
    this.assigneeId,
    this.checklist = const [],
    this.notes,
    this.documentIds,
  });

  StageProgress copyWith({
    ProjectStage? stage,
    StageStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? assigneeId,
    List<StageChecklistItem>? checklist,
    String? notes,
    List<String>? documentIds,
  }) {
    return StageProgress(
      stage: stage ?? this.stage,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      assigneeId: assigneeId ?? this.assigneeId,
      checklist: checklist ?? this.checklist,
      notes: notes ?? this.notes,
      documentIds: documentIds ?? this.documentIds,
    );
  }

  /// Calculate completion percentage
  double get completionPercentage {
    if (checklist.isEmpty) {
      return status == StageStatus.completed ? 1.0 : 0.0;
    }
    final completed = checklist.where((item) => item.isCompleted).length;
    return completed / checklist.length;
  }

  /// Check if all required items are completed
  bool get canAdvance {
    final requiredItems = checklist.where((item) => item.isRequired);
    return requiredItems.every((item) => item.isCompleted);
  }
}

enum StageStatus {
  notStarted,
  inProgress,
  completed,
  skipped,
  blocked,
}

extension StageStatusExtension on StageStatus {
  String get label {
    switch (this) {
      case StageStatus.notStarted:
        return '未着手';
      case StageStatus.inProgress:
        return '進行中';
      case StageStatus.completed:
        return '完了';
      case StageStatus.skipped:
        return 'スキップ';
      case StageStatus.blocked:
        return 'ブロック中';
    }
  }
}

/// Default checklists for each stage
class DefaultChecklists {
  static List<StageChecklistItem> getForStage(ProjectStage stage) {
    switch (stage) {
      case ProjectStage.inquiry:
        return [
          const StageChecklistItem(id: 'inq_1', label: '顧客情報の登録', isRequired: true),
          const StageChecklistItem(id: 'inq_2', label: '依頼内容のヒアリング', isRequired: true),
          const StageChecklistItem(id: 'inq_3', label: '概算予算の確認'),
          const StageChecklistItem(id: 'inq_4', label: '希望工期の確認'),
          const StageChecklistItem(id: 'inq_5', label: '現調日程の調整', isRequired: true),
        ];
      case ProjectStage.siteVisit:
        return [
          const StageChecklistItem(id: 'sv_1', label: '現場写真の撮影', isRequired: true),
          const StageChecklistItem(id: 'sv_2', label: '採寸・寸法の記録', isRequired: true),
          const StageChecklistItem(id: 'sv_3', label: '既存設備の確認', isRequired: true),
          const StageChecklistItem(id: 'sv_4', label: '搬入経路の確認'),
          const StageChecklistItem(id: 'sv_5', label: '電源・配管経路の確認'),
          const StageChecklistItem(id: 'sv_6', label: '現調報告書の作成', isRequired: true),
        ];
      case ProjectStage.specification:
        return [
          const StageChecklistItem(id: 'spec_1', label: '仕様案の作成', isRequired: true),
          const StageChecklistItem(id: 'spec_2', label: '顧客への仕様説明'),
          const StageChecklistItem(id: 'spec_3', label: '仕様の承認取得', isRequired: true),
          const StageChecklistItem(id: 'spec_4', label: '仕様書の確定', isRequired: true),
        ];
      case ProjectStage.productSelect:
        return [
          const StageChecklistItem(id: 'prod_1', label: '品番リストの作成', isRequired: true),
          const StageChecklistItem(id: 'prod_2', label: '在庫・納期の確認', isRequired: true),
          const StageChecklistItem(id: 'prod_3', label: '代替品の検討'),
          const StageChecklistItem(id: 'prod_4', label: '品番の確定', isRequired: true),
          const StageChecklistItem(id: 'prod_5', label: '拾い出しリストの完成', isRequired: true),
        ];
      case ProjectStage.drawing:
        return [
          const StageChecklistItem(id: 'drw_1', label: '施工図の作成', isRequired: true),
          const StageChecklistItem(id: 'drw_2', label: '詳細図の作成'),
          const StageChecklistItem(id: 'drw_3', label: '図面チェック', isRequired: true),
          const StageChecklistItem(id: 'drw_4', label: '顧客への図面説明'),
          const StageChecklistItem(id: 'drw_5', label: '図面の承認', isRequired: true),
        ];
      case ProjectStage.pricing:
        return [
          const StageChecklistItem(id: 'prc_1', label: '材料費の算出', isRequired: true),
          const StageChecklistItem(id: 'prc_2', label: '工賃の算出', isRequired: true),
          const StageChecklistItem(id: 'prc_3', label: '見積書の作成', isRequired: true),
          const StageChecklistItem(id: 'prc_4', label: '見積書の提出', isRequired: true),
          const StageChecklistItem(id: 'prc_5', label: '金額交渉・調整'),
          const StageChecklistItem(id: 'prc_6', label: '最終金額の合意', isRequired: true),
        ];
      case ProjectStage.contract:
        return [
          const StageChecklistItem(id: 'cnt_1', label: '契約書の作成', isRequired: true),
          const StageChecklistItem(id: 'cnt_2', label: '契約内容の確認', isRequired: true),
          const StageChecklistItem(id: 'cnt_3', label: '契約書の締結', isRequired: true),
          const StageChecklistItem(id: 'cnt_4', label: '着手金の入金確認'),
          const StageChecklistItem(id: 'cnt_5', label: '材料の発注開始', isRequired: true),
          const StageChecklistItem(id: 'cnt_6', label: '工程表の作成', isRequired: true),
        ];
      case ProjectStage.construction:
        return [
          const StageChecklistItem(id: 'cst_1', label: '材料の納品確認', isRequired: true),
          const StageChecklistItem(id: 'cst_2', label: '着工前確認', isRequired: true),
          const StageChecklistItem(id: 'cst_3', label: '施工の実施', isRequired: true),
          const StageChecklistItem(id: 'cst_4', label: '中間検査'),
          const StageChecklistItem(id: 'cst_5', label: '完了検査', isRequired: true),
          const StageChecklistItem(id: 'cst_6', label: '手直し対応'),
        ];
      case ProjectStage.completed:
        return [
          const StageChecklistItem(id: 'cmp_1', label: '完了報告書の作成', isRequired: true),
          const StageChecklistItem(id: 'cmp_2', label: '顧客への引き渡し', isRequired: true),
          const StageChecklistItem(id: 'cmp_3', label: '最終請求書の発行', isRequired: true),
          const StageChecklistItem(id: 'cmp_4', label: '入金確認', isRequired: true),
          const StageChecklistItem(id: 'cmp_5', label: 'アフターフォロー登録'),
        ];
    }
  }
}

/// Project flow state for a project
class ProjectFlow {
  final String projectId;
  final ProjectStage currentStage;
  final Map<ProjectStage, StageProgress> stageProgress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectFlow({
    required this.projectId,
    this.currentStage = ProjectStage.inquiry,
    required this.stageProgress,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get overall project completion percentage
  double get overallProgress {
    final completedStages = stageProgress.values
        .where((p) => p.status == StageStatus.completed)
        .length;
    return completedStages / ProjectStage.values.length;
  }

  /// Get what needs to be done next
  List<String> get nextActions {
    final current = stageProgress[currentStage];
    if (current == null) return [];

    final actions = <String>[];

    // Check incomplete required items
    for (final item in current.checklist) {
      if (item.isRequired && !item.isCompleted) {
        actions.add(item.label);
      }
    }

    return actions;
  }

  /// Check if can advance to next stage
  bool get canAdvanceToNextStage {
    final current = stageProgress[currentStage];
    return current?.canAdvance ?? false;
  }

  /// Factory to create initial flow
  factory ProjectFlow.initial(String projectId) {
    final now = DateTime.now();
    final stageProgress = <ProjectStage, StageProgress>{};

    for (final stage in ProjectStage.values) {
      stageProgress[stage] = StageProgress(
        stage: stage,
        status: stage == ProjectStage.inquiry
            ? StageStatus.inProgress
            : StageStatus.notStarted,
        checklist: DefaultChecklists.getForStage(stage),
        startedAt: stage == ProjectStage.inquiry ? now : null,
      );
    }

    return ProjectFlow(
      projectId: projectId,
      currentStage: ProjectStage.inquiry,
      stageProgress: stageProgress,
      createdAt: now,
      updatedAt: now,
    );
  }
}
