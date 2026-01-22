/// Template Service
/// Provides AI prompts and spreadsheet templates for users
/// Users can use these with their own AI tools (ChatGPT, Claude, etc.)

import '../models/material_model.dart';
import '../models/models.dart';

/// AI Prompt Templates for various construction workflows
class AIPromptTemplates {
  /// Prompt for extracting product codes from drawings/specifications
  static String getDrawingExtractionPrompt({
    String? drawingType,
    String? category,
  }) {
    final categoryHint = category != null ? '（$category関連）' : '';
    return '''
以下の図面/仕様書から品番・数量を抽出してください$categoryHint。

【出力形式】
CSV形式で以下の項目を抽出してください：
品番,品名,メーカー,数量,単位,備考

【抽出ルール】
1. 品番は正確に記載してください（ハイフン、スペースを含む）
2. 数量が明記されていない場合は「要確認」と記載
3. 同一品番が複数ある場合は合計数量を計算
4. 規格・サイズが複数ある場合は別行で記載
5. 不明な項目は「-」と記載

【カテゴリ別の注意点】
- 電気工事: ケーブル長さ(m)、器具数(個)、配管長さ(m)に注意
- 配管工事: 口径、材質、継手の種類を確認
- 建築工事: 寸法、仕上げ材、下地材を区別

---
図面/仕様書の内容を以下に貼り付けてください：

''';
  }

  /// Prompt for creating material estimate from requirements
  static String getMaterialEstimatePrompt() {
    return '''
以下の工事内容から必要な材料リストを作成してください。

【出力形式】
| 品番 | 品名 | メーカー | 数量 | 単位 | 概算単価 | 概算金額 | 納期目安 |
|------|------|----------|------|------|----------|----------|----------|

【見積もりルール】
1. 一般的に使用される標準品番を提案
2. 数量には10%程度の余裕を見込む
3. 単価は市場価格の目安を記載
4. 納期は一般的なリードタイムを記載

【カテゴリ】
□ 電気設備（ケーブル、配管、器具）
□ 給排水設備（配管、継手、器具）
□ 空調設備（ダクト、配管、機器）
□ 建築（躯体、仕上げ、建具）

---
工事概要を以下に記載してください：

''';
  }

  /// Prompt for checking material lead times against schedule
  static String getScheduleCheckPrompt({
    required DateTime constructionStart,
    List<String>? materialCategories,
  }) {
    final dateStr = '${constructionStart.year}年${constructionStart.month}月${constructionStart.day}日';
    final categories = materialCategories?.join('、') ?? '全カテゴリ';

    return '''
着工予定日: $dateStr
対象材料: $categories

以下の材料リストの納期を確認し、発注期限を計算してください。

【計算ルール】
発注期限 = 着工日 - 納期日数 - 予備日(2日)

【出力形式】
| 品番 | 品名 | 納期(日) | 発注期限 | 発注状況 | 緊急度 |
|------|------|----------|----------|----------|--------|

【緊急度の判定】
- 🔴 期限超過: 発注期限を過ぎている
- 🟠 緊急(3日以内): 発注期限まで3日以内
- 🟡 注意(7日以内): 発注期限まで7日以内
- 🟢 余裕あり: 発注期限まで8日以上

---
材料リストを以下に貼り付けてください：

''';
  }

  /// Prompt for creating order sheet to send to supplier
  static String getOrderSheetPrompt({
    required String supplierName,
    required String projectName,
    DateTime? deliveryDate,
  }) {
    final deliveryStr = deliveryDate != null
        ? '${deliveryDate.year}年${deliveryDate.month}月${deliveryDate.day}日'
        : '至急ご連絡ください';

    return '''
以下の内容で発注書を作成してください。

【発注先】$supplierName 様
【件名】$projectName 材料発注
【納品希望日】$deliveryStr

【発注書フォーマット】
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
発注書
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
発注日: [今日の日付]
発注番号: [自動採番]

発注先: $supplierName 御中
件名: $projectName

| No | 品番 | 品名 | 数量 | 単位 | 単価 | 金額 | 備考 |
|----|------|------|------|------|------|------|------|

小計: ¥
消費税(10%): ¥
合計: ¥

納品希望日: $deliveryStr
納品場所: [現場住所]

備考:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---
発注する材料リストを以下に入力してください：

''';
  }

  /// Prompt for comparing supplier quotes
  static String getQuoteComparisonPrompt() {
    return '''
以下の見積書を比較分析してください。

【比較項目】
1. 単価比較（品番ごと）
2. 納期比較
3. 合計金額比較
4. 支払条件比較

【出力形式】
## 1. 単価比較表
| 品番 | 品名 | A社単価 | B社単価 | C社単価 | 最安値 |
|------|------|---------|---------|---------|--------|

## 2. 総合評価
| 項目 | A社 | B社 | C社 |
|------|-----|-----|-----|
| 合計金額 | | | |
| 納期 | | | |
| 評価 | ★ | ★ | ★ |

## 3. 推奨
[最も優れた見積もりとその理由]

---
各社の見積書を以下に入力してください：

''';
  }
}

/// Spreadsheet/CSV Template Generator
class SpreadsheetTemplates {
  /// Generate material list CSV template
  static String getMaterialListCsv() {
    return '''品番,品名,メーカー,仕様,数量,単位,単価,金額,納期(日),カテゴリ,仕入先,備考
WN1001,フルカラー埋込スイッチ,パナソニック,100V 15A,20,個,280,5600,3,電気,電材商事,
VVF2.0-2C,VVFケーブル 2.0mm 2芯,パナソニック,600V 2.0mm×2C,500,m,150,75000,3,電気,電材商事,
VP-50A,塩ビ管 VP50,積水化学,50A×4m,30,本,500,15000,5,配管,配管資材センター,
''';
  }

  /// Generate order sheet CSV template
  static String getOrderSheetCsv({
    String? projectName,
    String? supplierName,
    DateTime? orderDate,
  }) {
    final dateStr = orderDate != null
        ? '${orderDate.year}/${orderDate.month}/${orderDate.day}'
        : '';

    return '''発注書
発注日,$dateStr
発注番号,
発注先,$supplierName
件名,$projectName

No,品番,品名,数量,単位,単価,金額,納期,備考
1,,,,,,,,,
2,,,,,,,,,
3,,,,,,,,,

,,,,,小計,0,,
,,,,,消費税,0,,
,,,,,合計,0,,

納品希望日,
納品場所,
備考,
''';
  }

  /// Generate task-material mapping CSV
  static String getTaskMaterialCsv(List<Task> tasks, List<TaskConstructionMaterial> materials) {
    final buffer = StringBuffer();
    buffer.writeln('タスクID,タスク名,着工日,品番,品名,数量,単位,納期(日),発注期限,発注状況');

    for (final tm in materials) {
      final task = tasks.firstWhere(
        (t) => t.id == tm.taskId,
        orElse: () => Task(
          id: tm.taskId,
          name: '不明',
          startDate: DateTime.now(),
          endDate: DateTime.now(),
        ),
      );

      final deadline = tm.calculateOrderDeadline(task.startDate);
      final deadlineStr = deadline != null
          ? '${deadline.year}/${deadline.month}/${deadline.day}'
          : '';

      buffer.writeln(
        '${task.id},'
        '${task.name},'
        '${task.startDate.year}/${task.startDate.month}/${task.startDate.day},'
        '${tm.material?.productCode ?? ""},'
        '${tm.material?.name ?? ""},'
        '${tm.quantity},'
        '${tm.material?.unit ?? ""},'
        '${tm.material?.leadTimeDays ?? ""},'
        '$deadlineStr,'
        '${tm.orderStatus.label}',
      );
    }

    return buffer.toString();
  }

  /// Generate supplier order summary CSV
  static String getSupplierOrderSummaryCsv(List<PurchaseOrder> orders) {
    final buffer = StringBuffer();
    buffer.writeln('発注番号,発注日,仕入先,品目数,合計金額,納品予定日,ステータス');

    for (final order in orders) {
      buffer.writeln(
        '${order.orderNumber ?? order.id},'
        '${order.orderDate.year}/${order.orderDate.month}/${order.orderDate.day},'
        '${order.supplierName},'
        '${order.items.length},'
        '${order.totalAmount.round()},'
        '${order.expectedDelivery != null ? "${order.expectedDelivery!.year}/${order.expectedDelivery!.month}/${order.expectedDelivery!.day}" : ""},'
        '${order.status.label}',
      );
    }

    return buffer.toString();
  }

  /// Generate project checklist template
  static String getProjectChecklistCsv(String projectStage) {
    return '''$projectStage チェックリスト
No,項目,必須,完了,完了日,担当者,備考
1,,,□,,,
2,,,□,,,
3,,,□,,,
4,,,□,,,
5,,,□,,,
''';
  }

  /// Generate deadline alert report CSV
  static String getDeadlineAlertsCsv(List<OrderAlert> alerts) {
    final buffer = StringBuffer();
    buffer.writeln('緊急度,タイトル,メッセージ,タスクID,材料ID,作成日時');

    for (final alert in alerts) {
      buffer.writeln(
        '${alert.severity.label},'
        '"${alert.title}",'
        '"${alert.message}",'
        '${alert.taskId ?? ""},'
        '${alert.materialId ?? ""},'
        '${alert.createdAt.year}/${alert.createdAt.month}/${alert.createdAt.day} ${alert.createdAt.hour}:${alert.createdAt.minute}',
      );
    }

    return buffer.toString();
  }
}

/// Template Service for managing and exporting templates
class TemplateService {
  /// Get all available prompt templates
  static List<PromptTemplate> getAvailablePrompts() {
    return [
      PromptTemplate(
        id: 'drawing_extraction',
        name: '図面品番抽出',
        description: '図面・仕様書から品番と数量を抽出するプロンプト',
        category: 'extraction',
        icon: 'description',
      ),
      PromptTemplate(
        id: 'material_estimate',
        name: '材料見積もり作成',
        description: '工事内容から必要材料リストを作成するプロンプト',
        category: 'estimate',
        icon: 'calculate',
      ),
      PromptTemplate(
        id: 'schedule_check',
        name: '納期スケジュール確認',
        description: '材料納期と着工日を照合するプロンプト',
        category: 'schedule',
        icon: 'schedule',
      ),
      PromptTemplate(
        id: 'order_sheet',
        name: '発注書作成',
        description: '仕入先への発注書を作成するプロンプト',
        category: 'order',
        icon: 'receipt_long',
      ),
      PromptTemplate(
        id: 'quote_comparison',
        name: '見積比較',
        description: '複数社の見積書を比較分析するプロンプト',
        category: 'analysis',
        icon: 'compare',
      ),
    ];
  }

  /// Get prompt content by ID
  static String getPromptContent(String promptId, {Map<String, dynamic>? params}) {
    switch (promptId) {
      case 'drawing_extraction':
        return AIPromptTemplates.getDrawingExtractionPrompt(
          drawingType: params?['drawingType'],
          category: params?['category'],
        );
      case 'material_estimate':
        return AIPromptTemplates.getMaterialEstimatePrompt();
      case 'schedule_check':
        return AIPromptTemplates.getScheduleCheckPrompt(
          constructionStart: params?['constructionStart'] ?? DateTime.now(),
          materialCategories: params?['categories'],
        );
      case 'order_sheet':
        return AIPromptTemplates.getOrderSheetPrompt(
          supplierName: params?['supplierName'] ?? '御中',
          projectName: params?['projectName'] ?? 'プロジェクト',
          deliveryDate: params?['deliveryDate'],
        );
      case 'quote_comparison':
        return AIPromptTemplates.getQuoteComparisonPrompt();
      default:
        return '';
    }
  }

  /// Get all available spreadsheet templates
  static List<SpreadsheetTemplate> getAvailableSpreadsheets() {
    return [
      SpreadsheetTemplate(
        id: 'material_list',
        name: '材料リスト',
        description: '品番・数量・単価を管理する材料一覧',
        format: 'csv',
      ),
      SpreadsheetTemplate(
        id: 'order_sheet',
        name: '発注書',
        description: '仕入先への発注書フォーマット',
        format: 'csv',
      ),
      SpreadsheetTemplate(
        id: 'task_material',
        name: 'タスク-材料紐付け',
        description: '工程と必要材料の紐付け一覧',
        format: 'csv',
      ),
      SpreadsheetTemplate(
        id: 'deadline_alerts',
        name: '発注期限アラート',
        description: '発注期限が近い材料の一覧',
        format: 'csv',
      ),
    ];
  }
}

/// Model for prompt template metadata
class PromptTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;

  const PromptTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
  });
}

/// Model for spreadsheet template metadata
class SpreadsheetTemplate {
  final String id;
  final String name;
  final String description;
  final String format;

  const SpreadsheetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
  });
}
