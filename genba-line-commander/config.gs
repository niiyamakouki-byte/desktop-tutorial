/**
 * Genba-LINE Commander - Configuration
 * 建設現場LINE通知システム設定ファイル
 */

// ============================================
// 🔐 環境設定（デプロイ前に設定必須）
// ============================================

const CONFIG = {
  // LINE Messaging API
  LINE_CHANNEL_ACCESS_TOKEN: PropertiesService.getScriptProperties().getProperty('LINE_CHANNEL_ACCESS_TOKEN') || 'YOUR_LINE_CHANNEL_ACCESS_TOKEN',
  LINE_PUSH_API_URL: 'https://api.line.me/v2/bot/message/push',
  LINE_MULTICAST_API_URL: 'https://api.line.me/v2/bot/message/multicast',

  // Google Spreadsheet
  SPREADSHEET_ID: PropertiesService.getScriptProperties().getProperty('SPREADSHEET_ID') || 'YOUR_SPREADSHEET_ID',

  // Google Drive
  DRIVE_FOLDER_ID: PropertiesService.getScriptProperties().getProperty('DRIVE_FOLDER_ID') || 'YOUR_DRIVE_FOLDER_ID',

  // LIFF
  LIFF_ID: PropertiesService.getScriptProperties().getProperty('LIFF_ID') || 'YOUR_LIFF_ID',

  // シート名
  SHEETS: {
    USERS: 'Users',           // 職人マスタ
    PROJECTS: 'Projects',     // 現場マスタ
    USER_PROJECTS: 'UserProjects',  // 職人-現場紐付け
    SCHEDULE: 'Schedule',     // 工程スケジュール
    LOGS: 'NotificationLogs'  // 送信ログ
  },

  // 通知タイプ
  NOTIFICATION_TYPES: {
    RAIN_CANCEL: 'rain_cancel',     // 雨天中止
    SCHEDULE_CHANGE: 'schedule_change',  // 工程変更
    BLUEPRINT_UPDATE: 'blueprint_update' // 図面更新
  }
};

// ============================================
// 🎨 カラーテーマ（Flex Message用）
// ============================================

const COLORS = {
  // 通知タイプ別カラー（Gemini提案の鮮やかな配色）
  RAIN_CANCEL: {
    primary: '#FF4444',      // 赤（警告）- より鮮やか
    secondary: '#FFCDD2',
    text: '#CC0000',
    icon: '🌧️'
  },
  SCHEDULE_CHANGE: {
    primary: '#FFB300',      // 黄（注意）- アンバー
    secondary: '#FFE082',
    text: '#E65100',
    icon: '📅'
  },
  BLUEPRINT_UPDATE: {
    primary: '#2196F3',      // 青（情報）- Material Blue
    secondary: '#BBDEFB',
    text: '#0D47A1',
    icon: '📄'
  },

  // 共通カラー
  WHITE: '#FFFFFF',
  GRAY: '#666666',
  LIGHT_GRAY: '#AAAAAA'
};

// ============================================
// 📝 メッセージテンプレート
// ============================================

const MESSAGES = {
  RAIN_CANCEL: {
    title: '【重要】作業中止のお知らせ',
    body: '明日の作業は雨天のため中止です。'
  },
  SCHEDULE_CHANGE: {
    title: '【確認】工程変更のお知らせ',
    body: '工程が変更になりました。ご確認ください。'
  },
  BLUEPRINT_UPDATE: {
    title: '【New】図面更新のお知らせ',
    body: '最新図面がアップロードされました。'
  },

  // Bot登録用
  REGISTRATION: {
    SUCCESS: '✅ 登録が完了しました！\n現場からの通知をお届けします。',
    ALREADY: 'ℹ️ 既に登録済みです。',
    ERROR: '❌ 登録に失敗しました。管理者にお問い合わせください。'
  }
};

/**
 * スクリプトプロパティの初期設定（初回のみ実行）
 * GASエディタから手動実行してください
 */
function initializeScriptProperties() {
  const scriptProperties = PropertiesService.getScriptProperties();

  // 以下の値を実際の値に置き換えて実行
  scriptProperties.setProperties({
    'LINE_CHANNEL_ACCESS_TOKEN': 'YOUR_LINE_CHANNEL_ACCESS_TOKEN',
    'SPREADSHEET_ID': 'YOUR_SPREADSHEET_ID',
    'DRIVE_FOLDER_ID': 'YOUR_DRIVE_FOLDER_ID',
    'LIFF_ID': 'YOUR_LIFF_ID'
  });

  console.log('Script properties initialized successfully.');
}

/**
 * スプレッドシートの初期構造を作成
 */
function initializeSpreadsheet() {
  const ss = SpreadsheetApp.openById(CONFIG.SPREADSHEET_ID);

  // Users シート
  let usersSheet = ss.getSheetByName(CONFIG.SHEETS.USERS);
  if (!usersSheet) {
    usersSheet = ss.insertSheet(CONFIG.SHEETS.USERS);
    usersSheet.appendRow(['userId', 'displayName', 'registeredAt', 'status']);
    usersSheet.getRange(1, 1, 1, 4).setFontWeight('bold');
  }

  // Projects シート
  let projectsSheet = ss.getSheetByName(CONFIG.SHEETS.PROJECTS);
  if (!projectsSheet) {
    projectsSheet = ss.insertSheet(CONFIG.SHEETS.PROJECTS);
    projectsSheet.appendRow(['projectId', 'projectName', 'address', 'startDate', 'endDate', 'status']);
    projectsSheet.getRange(1, 1, 1, 6).setFontWeight('bold');
  }

  // UserProjects シート（紐付け）
  let userProjectsSheet = ss.getSheetByName(CONFIG.SHEETS.USER_PROJECTS);
  if (!userProjectsSheet) {
    userProjectsSheet = ss.insertSheet(CONFIG.SHEETS.USER_PROJECTS);
    userProjectsSheet.appendRow(['userId', 'projectId', 'role', 'assignedAt']);
    userProjectsSheet.getRange(1, 1, 1, 4).setFontWeight('bold');
  }

  // Schedule シート（工程管理）
  let scheduleSheet = ss.getSheetByName(CONFIG.SHEETS.SCHEDULE);
  if (!scheduleSheet) {
    scheduleSheet = ss.insertSheet(CONFIG.SHEETS.SCHEDULE);
    scheduleSheet.appendRow(['scheduleId', 'projectId', 'taskName', 'date', 'status', 'note']);
    scheduleSheet.getRange(1, 1, 1, 6).setFontWeight('bold');
    // サンプルデータ
    scheduleSheet.appendRow(['S001', 'P001', 'モルタル造形', '2025-01-25', 'scheduled', '']);
  }

  // NotificationLogs シート
  let logsSheet = ss.getSheetByName(CONFIG.SHEETS.LOGS);
  if (!logsSheet) {
    logsSheet = ss.insertSheet(CONFIG.SHEETS.LOGS);
    logsSheet.appendRow(['logId', 'timestamp', 'type', 'projectId', 'targetCount', 'successCount', 'failCount', 'payload']);
    logsSheet.getRange(1, 1, 1, 8).setFontWeight('bold');
  }

  console.log('Spreadsheet structure initialized successfully.');
}
