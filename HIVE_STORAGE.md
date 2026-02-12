# Hiveストレージ実装ドキュメント

## 概要

このプロジェクトでは、Hiveを使用したローカルデータ永続化を実装しました。タスクとプロジェクトのデータは自動的にローカルに保存され、アプリ再起動後も復元されます。

## 実装内容

### 1. 依存関係の追加

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.6
```

### 2. リポジトリクラス

#### TaskRepository (`lib/data/repositories/task_repository.dart`)

- タスクデータをHiveにJSON形式で保存
- 自動保存機能（変更から3秒後）
- エクスポート/インポート機能
- CRUD操作のサポート

主要メソッド:
- `initialize()` - Hiveボックスの初期化
- `getAllTasks()` - 全タスクの取得
- `getTasksByProject(projectId)` - プロジェクト別タスク取得
- `saveTask(task)` - 単一タスクの保存
- `saveTasks(tasks)` - 複数タスクの保存
- `deleteTask(id)` - タスクの削除
- `exportToJson()` - JSON形式でエクスポート
- `importFromJson(jsonStr)` - JSON形式からインポート
- `forceSave()` - 即座に保存

#### ProjectRepository (`lib/data/repositories/project_repository.dart`)

- プロジェクトデータをHiveにJSON形式で保存
- TaskRepositoryと同様の機能を提供

### 3. ProjectProviderの統合

`lib/data/services/project_provider.dart`を更新:

- コンストラクタでRepositoryを受け取る
- `initialize()`メソッドでHiveから既存データを読み込み
- データがない場合はモックデータで初期化
- データ変更時に自動保存

自動保存が実行される操作:
- `updateTask()` - タスク更新時
- `toggleTaskExpansion()` - タスク展開/折りたたみ時
- `applyRainCancellation()` - 雨天中止適用時

### 4. エクスポート/インポートUI

`lib/presentation/widgets/modal/data_backup_dialog.dart`:
- データのエクスポート/インポートを行うダイアログ
- ヘッダーのバックアップボタンから起動
- クリップボードへのコピー機能

## 自動保存機能

### 仕組み

1. データが変更されると`_markForAutoSave()`が呼ばれる
2. 既存のタイマーをキャンセルし、新しい3秒タイマーを開始
3. 3秒間新しい変更がなければ自動的に`flush()`を実行
4. これにより、頻繁な変更でもI/O負荷を最小限に抑える

### 即座に保存

```dart
await projectProvider.forceSaveAll();
```

## データのエクスポート/インポート

### エクスポート

ヘッダーのバックアップボタン（📦アイコン）をクリック→「データをエクスポート」

エクスポートされたJSONデータをコピーして安全な場所に保存してください。

### インポート

ヘッダーのバックアップボタン→「データをインポート」→JSONデータを貼り付け

⚠️ **注意**: 既存データは上書きされます。必ず事前にバックアップを取ってください。

## まとめ

Hiveを使用したローカルストレージ実装により:
- ✅ データの永続化
- ✅ 自動保存機能（3秒遅延）
- ✅ JSON形式でのエクスポート/インポート
- ✅ 既存コードとの互換性維持
- ✅ シンプルで保守しやすい実装

次のステップ:
1. Flutter環境でビルドとテスト
2. エラーハンドリングの強化
3. ユニットテストの追加
