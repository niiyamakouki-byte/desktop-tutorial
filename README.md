# 🏗️ 建設DXコックピット

**直感的な操作で現場を管理する、次世代の工程管理ツール**

> 📱 **NEW!** スマホ縦画面対応完了（2026-02-12）- 360px-414pxの小画面でも快適に操作可能

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Demo](https://img.shields.io/badge/Demo-Live-success)](https://niiyamakouki-byte.github.io/desktop-tutorial/)

現場管理者が**説明書なしで**使える、建設業界向けの高機能工程管理アプリです。複雑な工程をガントチャートで視覚化し、ドラッグ&ドロップの直感操作で日程調整ができます。

---

## ✨ 主要機能

### 🎯 1. 直感的なガントチャート
- **ドラッグ&ドロップ**: タスクバーをドラッグして日程変更
- **リサイズ操作**: バーの両端をドラッグして期間調整（1日単位スナップ）
- **依存関係作成**: タスク間を線でつなぐだけで依存関係を設定
- **リアルタイム計算**: 営業日ベースの自動計算（土日祝日除外）

### 📊 2. タスク管理
- **遅延ステータス**: 順調/リスク/待ち/超過を自動判定
- **待ち理由管理**: 前工程待ち、材料待ち、承認待ちなど詳細管理
- **進捗バー**: 視覚的な進捗表示（%表示）
- **フェーズ管理**: 基礎→構造→設備→内装→外構→検査の色分け表示

### 💾 3. データ永続化
- **自動保存**: 編集内容を3秒後に自動保存（Hive使用）
- **バックアップ・復元**: JSON形式でプロジェクトデータをエクスポート/インポート
- **ブラウザストレージ**: ローカルストレージで安全に保存

### 📅 4. 営業日計算
- **土日祝日除外**: 営業日ベースで正確な工期計算
- **日本祝日対応**: 2026-2030年の祝日をサポート
- **カスタマイズ可能**: 土日/祝日の除外設定を個別に変更可能

---

## 🎬 デモ

**🌐 ライブデモ**: [https://niiyamakouki-byte.github.io/desktop-tutorial/](https://niiyamakouki-byte.github.io/desktop-tutorial/)

### スクリーンショット

```
※ 実際のスクリーンショットは以下のパスに保存してください：
docs/images/gantt-chart-screenshot.png
docs/images/task-management-screenshot.png
docs/images/dependency-creation-screenshot.png
docs/images/backup-dialog-screenshot.png
```

> **ヒント**: GitHub Pagesで公開中のデモをブラウザで開いてスクリーンショットを撮影できます

---

## 🚀 使い方（クイックスタート）

### 1. プロジェクトを作成
アプリ起動後、「新規プロジェクト」ボタンから建設プロジェクトを作成します。

### 2. タスクを追加
左サイドバーの「タスク追加」からタスクを作成。タスク名、開始日、期間を設定します。

### 3. ガントチャートで調整
- **日程変更**: タスクバーをドラッグして移動
- **期間変更**: バーの左右端をドラッグしてリサイズ
- **依存関係**: タスクバー右端の🟠から線をドラッグして他のタスクに接続

### 4. 進捗を更新
タスクをクリックして詳細パネルを開き、進捗率を更新します。

詳細な使い方は [USAGE.md](USAGE.md) をご覧ください。

---

## 🛠️ 技術スタック

| カテゴリ | 技術 |
|---------|------|
| **フレームワーク** | Flutter 3.0+ (Web対応) |
| **状態管理** | Provider パターン |
| **ローカルストレージ** | Hive 2.2+ |
| **UI** | Material Design 3 |
| **フォント** | Google Fonts |
| **ホスティング** | GitHub Pages |
| **バージョン管理** | Git / GitHub |

### 主要パッケージ

```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.1        # 状態管理
  hive: ^2.2.3            # ローカルストレージ
  hive_flutter: ^1.1.0    # Flutter統合
  intl: ^0.18.1           # 日付フォーマット
  uuid: ^4.2.1            # ID生成
  google_fonts: ^6.1.0    # Webフォント
  flutter_animate: ^4.3.0 # アニメーション
```

---

## 💻 ローカル開発

### 必要環境

- Flutter SDK 3.0以上
- Dart SDK 3.0以上
- Chrome（Web開発用）

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/niiyamakouki-byte/desktop-tutorial.git
cd desktop-tutorial

# 依存関係をインストール
flutter pub get

# Hiveアダプターを生成（初回のみ）
flutter pub run build_runner build --delete-conflicting-outputs

# 開発サーバーを起動
flutter run -d chrome
```

ブラウザで `http://localhost:####` が自動的に開きます。

### ビルド（本番用）

```bash
# Web版をビルド
flutter build web --release

# ビルド結果は build/web/ に出力されます
```

---

## 📚 ドキュメント

- [使い方ガイド (USAGE.md)](USAGE.md) - 詳細な操作方法
- [開発計画 (DEVPLAN.md)](DEVPLAN.md) - 開発ロードマップ
- [変更履歴 (CHANGELOG.md)](CHANGELOG.md) - バージョン履歴

### 技術レポート
- [リサイズ機能レポート (RESIZE_FEATURE_REPORT.md)](RESIZE_FEATURE_REPORT.md)
- [依存関係UI進捗 (DEPENDENCY_UI_PROGRESS.md)](DEPENDENCY_UI_PROGRESS.md)
- [Hiveストレージ (HIVE_STORAGE.md)](HIVE_STORAGE.md)

---

## 🤝 コントリビューション

プルリクエストを歓迎します！大きな変更の場合は、まずIssueで議論してください。

### 開発フロー

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

---

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

---

## 📱 モバイル対応

### スマホ縦画面対応（v1.1 - 2026-02-12）

iPhone、Android等のスマホ縦画面（360px-414px）で快適に使用できるよう、レスポンシブ対応を実装しました。

**主な対応内容:**
- ✅ タッチ操作でのドラッグ&ドロップ
- ✅ ボタンサイズを44px以上に拡大（Appleガイドライン準拠）
- ✅ ヘッダーボタンをグリッドレイアウトに変更
- ✅ ノード幅を画面サイズに応じて自動調整
- ✅ モーダルを画面幅95%に最適化
- ✅ iOSでの自動ズーム防止

**対応デバイス:**
- iPhone 12 Pro (390x844)
- iPhone SE (375x667)
- Android (360x640)
- iPad (768x1024)
- 横画面モードにも対応

詳細は [MOBILE_RESPONSIVE_REPORT.md](MOBILE_RESPONSIVE_REPORT.md) を参照してください。

---

## 🙏 謝辞

- **Flutter Team**: 素晴らしいフレームワークに感謝
- **Hive**: 高速なローカルストレージを提供
- **建設業界の方々**: 貴重なフィードバックをありがとうございます

---

## 📞 サポート

質問や問題がある場合は、[GitHub Issues](https://github.com/niiyamakouki-byte/desktop-tutorial/issues) でお知らせください。

---

**Built with ❤️ for 建設業界**

現場の効率化を、直感的なUIで。
