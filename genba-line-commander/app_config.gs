/**
 * Genba-LINE Commander - Configuration
 * 設定ファイル
 */

// ===========================================
// スクリプトプロパティから取得する設定
// ===========================================

function getConfig() {
  const props = PropertiesService.getScriptProperties();
  return {
    LINE_CHANNEL_ACCESS_TOKEN: props.getProperty('LINE_CHANNEL_ACCESS_TOKEN') || '',
    SPREADSHEET_ID: props.getProperty('SPREADSHEET_ID') || '',
    LIFF_ID: props.getProperty('LIFF_ID') || '',
  };
}

// ===========================================
// 定数
// ===========================================

const SHEET_NAMES = {
  PROJECTS: 'Projects',
  USERS: 'Users',
  SCHEDULE: 'Schedule',
};

const TASK_STATUS = {
  ACTIVE: 'active',
  PENDING: 'pending',
  DONE: 'done',
};

const USER_ROLE = {
  ADMIN: 'admin',
  STAFF: 'staff',
};

const COLORS = {
  ACTIVE: '#2196F3',    // Blue
  PENDING: '#FF9800',   // Orange
  DONE: '#9E9E9E',      // Gray
  RAIN: '#F44336',      // Red
  SUCCESS: '#4CAF50',   // Green
};

// ===========================================
// 初期セットアップ
// ===========================================

/**
 * スプレッドシートを初期化（シートとヘッダーを作成）
 */
function initializeSpreadsheet() {
  const config = getConfig();
  if (!config.SPREADSHEET_ID) {
    throw new Error('SPREADSHEET_ID が設定されていません。スクリプトプロパティを確認してください。');
  }

  const ss = SpreadsheetApp.openById(config.SPREADSHEET_ID);

  // Projects シート
  let projectsSheet = ss.getSheetByName(SHEET_NAMES.PROJECTS);
  if (!projectsSheet) {
    projectsSheet = ss.insertSheet(SHEET_NAMES.PROJECTS);
    projectsSheet.getRange(1, 1, 1, 5).setValues([
      ['id', 'name', 'map_url', 'drive_url', 'status']
    ]);
    projectsSheet.getRange(1, 1, 1, 5).setFontWeight('bold').setBackground('#E3F2FD');
  }

  // Users シート
  let usersSheet = ss.getSheetByName(SHEET_NAMES.USERS);
  if (!usersSheet) {
    usersSheet = ss.insertSheet(SHEET_NAMES.USERS);
    usersSheet.getRange(1, 1, 1, 3).setValues([
      ['line_uid', 'name', 'role']
    ]);
    usersSheet.getRange(1, 1, 1, 3).setFontWeight('bold').setBackground('#E8F5E9');
  }

  // Schedule シート
  let scheduleSheet = ss.getSheetByName(SHEET_NAMES.SCHEDULE);
  if (!scheduleSheet) {
    scheduleSheet = ss.insertSheet(SHEET_NAMES.SCHEDULE);
    scheduleSheet.getRange(1, 1, 1, 7).setValues([
      ['id', 'project_id', 'date', 'task_name', 'member_uids', 'note', 'status']
    ]);
    scheduleSheet.getRange(1, 1, 1, 7).setFontWeight('bold').setBackground('#FFF3E0');
  }

  Logger.log('スプレッドシートの初期化が完了しました');
}

/**
 * サンプルデータを投入
 */
function insertSampleData() {
  const config = getConfig();
  const ss = SpreadsheetApp.openById(config.SPREADSHEET_ID);

  // Sample Projects
  const projectsSheet = ss.getSheetByName(SHEET_NAMES.PROJECTS);
  const projectsData = [
    ['P001', '渋谷ビル新築工事', 'https://maps.google.com/?q=35.6580,139.7016', 'https://drive.google.com/...', 'active'],
    ['P002', '新宿マンション改修', 'https://maps.google.com/?q=35.6896,139.6917', 'https://drive.google.com/...', 'active'],
  ];
  projectsSheet.getRange(2, 1, projectsData.length, 5).setValues(projectsData);

  // Sample Users (LINE UIDは実際のものに置き換え)
  const usersSheet = ss.getSheetByName(SHEET_NAMES.USERS);
  const usersData = [
    ['U_ADMIN_001', '光輝（監督）', 'admin'],
    ['U_STAFF_001', '田中（左官）', 'staff'],
    ['U_STAFF_002', '佐藤（電気）', 'staff'],
    ['U_STAFF_003', '鈴木（配管）', 'staff'],
  ];
  usersSheet.getRange(2, 1, usersData.length, 3).setValues(usersData);

  // Sample Schedule
  const scheduleSheet = ss.getSheetByName(SHEET_NAMES.SCHEDULE);
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = Utilities.formatDate(tomorrow, 'Asia/Tokyo', 'yyyy-MM-dd');

  const dayAfter = new Date();
  dayAfter.setDate(dayAfter.getDate() + 2);
  const dayAfterStr = Utilities.formatDate(dayAfter, 'Asia/Tokyo', 'yyyy-MM-dd');

  const scheduleData = [
    ['S001', 'P001', tomorrowStr, '外壁塗装', 'U_STAFF_001,U_STAFF_002', '駐車場: 北側P利用可', 'active'],
    ['S002', 'P001', dayAfterStr, '配管工事', 'U_STAFF_003', '駐車場: コインP', 'active'],
    ['S003', 'P002', '', '仕上げ工事', 'U_STAFF_001', '', 'pending'],
  ];
  scheduleSheet.getRange(2, 1, scheduleData.length, 7).setValues(scheduleData);

  Logger.log('サンプルデータの投入が完了しました');
}

/**
 * 日次通知トリガーを設定（毎日19:00と06:00）
 */
function setupDailyTriggers() {
  // 既存のトリガーを削除
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(trigger => {
    if (trigger.getHandlerFunction() === 'sendDailyReport') {
      ScriptApp.deleteTrigger(trigger);
    }
  });

  // 19:00 トリガー
  ScriptApp.newTrigger('sendDailyReport')
    .timeBased()
    .atHour(19)
    .everyDays(1)
    .inTimezone('Asia/Tokyo')
    .create();

  // 06:00 トリガー
  ScriptApp.newTrigger('sendDailyReport')
    .timeBased()
    .atHour(6)
    .everyDays(1)
    .inTimezone('Asia/Tokyo')
    .create();

  Logger.log('日次通知トリガーを設定しました（19:00, 06:00）');
}
