# 🏗️ Genba-LINE Commander (現場LINE Commander)

建設現場の職人へ一斉通知を送るLINE Botシステム

## 📋 機能

### 3つの通知タイプ
| タイプ | アイコン | カラー | 用途 |
|--------|---------|--------|------|
| 雨天中止 | ☔️ | 赤 | 翌日の作業中止を通知 |
| 工程変更 | 📅 | 黄 | 日程変更を視覚的に伝達 |
| 図面更新 | 📐 | 青 | 最新図面をワンタップで閲覧 |

### 追加機能
- 📍 **Googleマップ連携**: 住所タップで現場をマップ表示
- 📎 **ファイルアップロード**: PDFやCADファイルをGoogle Driveに保存
- 👷 **自動登録**: 友だち追加時に自動でユーザー登録
- 📊 **送信ログ**: 全ての通知履歴をスプレッドシートに記録

---

## 🛠️ セットアップ手順

### 1. LINE Developers 設定

1. [LINE Developers Console](https://developers.line.biz/) でプロバイダーを作成
2. Messaging API チャネルを作成
3. 以下を取得:
   - **Channel Access Token** (長期トークン)
   - **Channel Secret**

### 2. Google Spreadsheet 作成

1. 新しいスプレッドシートを作成
2. スプレッドシートIDをコピー（URLの `/d/` と `/edit` の間の部分）

### 3. Google Drive フォルダ作成

1. 図面保存用のフォルダを作成
2. フォルダIDをコピー（URLの最後の部分）

### 4. Google Apps Script 設定

1. [Google Apps Script](https://script.google.com/) で新規プロジェクト作成
2. 各 `.gs` ファイルを作成してコードをコピー
3. `index.html` ファイルを作成してコードをコピー

### 5. スクリプトプロパティ設定

GASエディタで: **プロジェクトの設定** → **スクリプト プロパティ**

| プロパティ名 | 値 |
|-------------|-----|
| `LINE_CHANNEL_ACCESS_TOKEN` | LINEのアクセストークン |
| `SPREADSHEET_ID` | スプレッドシートID |
| `DRIVE_FOLDER_ID` | DriveフォルダID |
| `LIFF_ID` | LIFF ID（後で設定） |

### 6. スプレッドシート初期化

GASエディタで `initializeSpreadsheet` 関数を実行

### 7. Web App デプロイ

1. **デプロイ** → **新しいデプロイ**
2. 種類: **ウェブアプリ**
3. 実行者: **自分**
4. アクセス: **全員**
5. デプロイURLをコピー

### 8. LINE Webhook 設定

LINE Developers Console で:
- Webhook URL: `{デプロイURL}`
- Webhook利用: **ON**
- 応答メッセージ: **OFF**

### 9. LIFF 設定

1. LINE Developers で LIFF アプリを追加
2. エンドポイントURL: `{デプロイURL}`
3. LIFF IDをスクリプトプロパティに追加

---

## 📁 ファイル構成

```
genba-line-commander/
├── config.gs      # 設定・定数管理
├── utils.gs       # スプレッドシート操作
├── backend.gs     # メインロジック
├── drive.gs       # ファイル操作
├── index.html     # 管理者UI
└── README.md      # このファイル
```

---

## 📊 スプレッドシート構造

### Users シート
| userId | displayName | registeredAt | status |
|--------|-------------|--------------|--------|
| Uxxxx | 山田太郎 | 2024-01-01T00:00:00Z | active |

### Projects シート
| projectId | projectName | address | startDate | endDate | status |
|-----------|-------------|---------|-----------|---------|--------|
| P001 | 渋谷ビル新築工事 | 東京都渋谷区... | 2024-01-01 | 2024-12-31 | active |

### UserProjects シート
| userId | projectId | role | assignedAt |
|--------|-----------|------|------------|
| Uxxxx | P001 | worker | 2024-01-01T00:00:00Z |

### NotificationLogs シート
| logId | timestamp | type | projectId | targetCount | successCount | failCount | payload |
|-------|-----------|------|-----------|-------------|--------------|-----------|---------|

---

## 🔧 カスタマイズ

### メッセージ内容の変更

`config.gs` の `MESSAGES` オブジェクトを編集:

```javascript
const MESSAGES = {
  RAIN_CANCEL: {
    title: '【重要】作業中止のお知らせ',
    body: '明日の作業は雨天のため中止です。'
  },
  // ...
};
```

### カラーテーマの変更

`config.gs` の `COLORS` オブジェクトを編集:

```javascript
const COLORS = {
  RAIN_CANCEL: {
    primary: '#E53935',  // 赤
    // ...
  },
  // ...
};
```

---

## 🐛 トラブルシューティング

### 通知が届かない
- LINE Channel Access Token が有効か確認
- ユーザーがBotを友だち追加しているか確認
- スプレッドシートにユーザーが登録されているか確認

### ファイルアップロードが失敗する
- Google Driveフォルダの共有設定を確認
- ファイルサイズが10MB以下か確認

### LIFFが開かない
- LIFF IDが正しく設定されているか確認
- エンドポイントURLがHTTPSか確認

---

## 📝 ライセンス

MIT License

---

## 🤝 コントリビューション

Issue や Pull Request は大歓迎です！
