# 工程管理ツール 開発計画

## 概要
建設現場向け工程管理ツール。競合（APDW Project Compass）との差別化ポイントは「直感的なガントチャート操作」。

## 目標
現場管理者が**説明書なしで**使える直感的なUI

---

## Phase 1: ガントチャート操作性改善（優先度: 高）

### 1.1 バーの両端ドラッグでリサイズ
**状態**: 🔴 未着手
**担当**: サブエージェント1

- [ ] TaskBarにリサイズハンドル追加（左端・右端）
- [ ] ドラッグで開始日/終了日を変更
- [ ] スナップ機能（日単位でスナップ）
- [ ] ビジュアルフィードバック（ハンドルホバー時のカーソル変更）

**ファイル**:
- `lib/presentation/widgets/gantt/task_row.dart`

### 1.2 ドラッグ中のリアルタイム連動プレビュー
**状態**: 🔴 未着手
**担当**: サブエージェント2

- [ ] 依存関係のある後続タスクをリアルタイムで移動表示
- [ ] ゴースト表示（元の位置を薄く表示）
- [ ] 影響範囲のハイライト
- [ ] ドラッグ確定時に実際のデータ更新

**ファイル**:
- `lib/data/services/task_cascade_service.dart`
- `lib/presentation/widgets/gantt/timeline_panel.dart`

### 1.3 曲線ドラッグで依存関係作成
**状態**: 🔴 未着手
**担当**: サブエージェント3

- [ ] タスクバーの端からドラッグ開始
- [ ] ベジェ曲線でリアルタイム描画
- [ ] ターゲットタスクへのスナップ
- [ ] 依存タイプ選択UI（FS/SS/FF/SF）

**ファイル**:
- `lib/presentation/widgets/gantt/dependency_connector.dart`
- `lib/presentation/widgets/gantt/enhanced_dependency_painter.dart`

---

## Phase 2: UX改善

### 2.1 ミニマップ/オーバービュー
- 全体俯瞰表示
- クリックでジャンプ

### 2.2 キーボードショートカット
- 矢印キーでタスク移動
- Shift+ドラッグで複数選択

### 2.3 アンドゥ/リドゥ
- 操作履歴管理
- Ctrl+Z / Ctrl+Y

---

## Phase 3: 機能拡張

### 3.1 リソース管理
- 職人の稼働状況
- 機材の割り当て

### 3.2 コスト連動
- 日程変更→コスト自動再計算

---

## 技術スタック
- **Frontend**: Flutter Web
- **State**: Provider / Riverpod
- **Hosting**: GitHub Pages + Firebase

## リポジトリ
- GitHub: https://github.com/niiyamakouki-byte/desktop-tutorial
- Demo: https://niiyamakouki-byte.github.io/desktop-tutorial/

---

## 今日のタスク
1. [ ] Phase 1.1: バーのリサイズ機能
2. [ ] Phase 1.2: 連動プレビュー
3. [ ] Phase 1.3: 依存関係ドラッグ作成
