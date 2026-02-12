# 📸 スクリーンショット

このディレクトリには、README.mdで使用するスクリーンショットを保存してください。

## 必要な画像

以下のスクリーンショットを撮影してください：

### 1. gantt-chart-screenshot.png
**ガントチャートのメイン画面**

- デモURL: https://niiyamakouki-byte.github.io/desktop-tutorial/
- 推奨サイズ: 1920x1080px
- 内容: タスクバー、フェーズ色分け、今日ライン、進捗バーが見えるように

### 2. task-management-screenshot.png
**タスク管理の詳細パネル**

- タスクをクリックした状態
- 推奨サイズ: 1200x800px
- 内容: タスク詳細、進捗率、遅延ステータス、担当者などが見えるように

### 3. dependency-creation-screenshot.png
**依存関係の作成中**

- タスクバーからドラッグして矢印を引いている状態
- 推奨サイズ: 1200x800px
- 内容: ドラッグ中のベジェ曲線、スナップ表示、ヒントオーバーレイが見えるように

### 4. backup-dialog-screenshot.png
**バックアップダイアログ**

- AppHeaderの「💾 バックアップ」ボタンをクリックした状態
- 推奨サイズ: 800x600px
- 内容: エクスポート/インポートタブ、ダウンロードボタンが見えるように

## スクリーンショットの撮影方法

### ブラウザのスクリーンショット機能を使う（推奨）

#### Chrome
1. デベロッパーツールを開く（F12）
2. Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows)
3. "Capture screenshot" と入力
4. "Capture full size screenshot" を選択

#### Firefox
1. 右クリック → "スクリーンショットを撮る"
2. "ページ全体を保存" を選択

### OSの機能を使う

#### Mac
- Cmd+Shift+4: 範囲選択スクリーンショット
- Cmd+Shift+5: 画面収録コントロール

#### Windows
- Win+Shift+S: 範囲選択スクリーンショット
- Snipping Tool

## 画像の最適化

撮影後、以下のツールで画像を最適化してください：

- **ImageOptim** (Mac): https://imageoptim.com/
- **TinyPNG** (Web): https://tinypng.com/
- **Squoosh** (Web): https://squoosh.app/

目標: 各画像を200KB以下に圧縮

## README.mdへの追加

スクリーンショットを撮影したら、README.mdの該当箇所を以下のように更新してください：

```markdown
### スクリーンショット

#### ガントチャート
![ガントチャート](docs/images/gantt-chart-screenshot.png)

#### タスク管理
![タスク管理](docs/images/task-management-screenshot.png)

#### 依存関係の作成
![依存関係の作成](docs/images/dependency-creation-screenshot.png)

#### データバックアップ
![データバックアップ](docs/images/backup-dialog-screenshot.png)
```

---

**注意**: スクリーンショットにはサンプルデータを使用し、実際のプロジェクト情報が含まれないようにしてください。
