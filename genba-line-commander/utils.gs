/**
 * Genba-LINE Commander - Utilities
 * スプレッドシート操作ヘルパー関数
 */

// ============================================
// 📊 スプレッドシート操作
// ============================================

/**
 * シートからデータを取得（ヘッダー付きオブジェクト配列）
 * @param {string} sheetName - シート名
 * @returns {Object[]} データ配列
 */
function getSheetData(sheetName) {
  try {
    const ss = SpreadsheetApp.openById(CONFIG.SPREADSHEET_ID);
    const sheet = ss.getSheetByName(sheetName);

    if (!sheet) {
      console.error(`Sheet not found: ${sheetName}`);
      return [];
    }

    const data = sheet.getDataRange().getValues();
    if (data.length <= 1) return []; // ヘッダーのみ

    const headers = data[0];
    const rows = data.slice(1);

    return rows.map(row => {
      const obj = {};
      headers.forEach((header, index) => {
        obj[header] = row[index];
      });
      return obj;
    });
  } catch (error) {
    console.error(`Error reading sheet ${sheetName}:`, error);
    return [];
  }
}

/**
 * シートにデータを追加
 * @param {string} sheetName - シート名
 * @param {Array} rowData - 追加するデータ配列
 * @returns {boolean} 成功/失敗
 */
function appendToSheet(sheetName, rowData) {
  try {
    const ss = SpreadsheetApp.openById(CONFIG.SPREADSHEET_ID);
    const sheet = ss.getSheetByName(sheetName);

    if (!sheet) {
      console.error(`Sheet not found: ${sheetName}`);
      return false;
    }

    sheet.appendRow(rowData);
    return true;
  } catch (error) {
    console.error(`Error appending to sheet ${sheetName}:`, error);
    return false;
  }
}

/**
 * シート内でデータを検索
 * @param {string} sheetName - シート名
 * @param {string} column - 検索対象カラム名
 * @param {*} value - 検索値
 * @returns {Object|null} 見つかった行データ
 */
function findInSheet(sheetName, column, value) {
  const data = getSheetData(sheetName);
  return data.find(row => row[column] === value) || null;
}

/**
 * シート内でデータを複数検索
 * @param {string} sheetName - シート名
 * @param {string} column - 検索対象カラム名
 * @param {*} value - 検索値
 * @returns {Object[]} 見つかった行データ配列
 */
function findAllInSheet(sheetName, column, value) {
  const data = getSheetData(sheetName);
  return data.filter(row => row[column] === value);
}

// ============================================
// 👷 ユーザー管理
// ============================================

/**
 * ユーザーをLINE IDで検索
 * @param {string} userId - LINE User ID
 * @returns {Object|null} ユーザー情報
 */
function findUserById(userId) {
  return findInSheet(CONFIG.SHEETS.USERS, 'userId', userId);
}

/**
 * 新規ユーザーを登録
 * @param {string} userId - LINE User ID
 * @param {string} displayName - 表示名
 * @returns {boolean} 成功/失敗
 */
function registerUser(userId, displayName) {
  // 既存チェック
  if (findUserById(userId)) {
    console.log(`User already exists: ${userId}`);
    return false;
  }

  const rowData = [
    userId,
    displayName || '名前未設定',
    new Date().toISOString(),
    'active'
  ];

  return appendToSheet(CONFIG.SHEETS.USERS, rowData);
}

/**
 * プロジェクトに紐づくユーザー一覧を取得
 * @param {string} projectId - プロジェクトID
 * @returns {Object[]} ユーザー情報配列
 */
function findUsersByProject(projectId) {
  // プロジェクト紐付けを検索
  const userProjects = findAllInSheet(CONFIG.SHEETS.USER_PROJECTS, 'projectId', projectId);

  if (userProjects.length === 0) {
    return [];
  }

  // ユーザー詳細を取得
  const allUsers = getSheetData(CONFIG.SHEETS.USERS);
  const userIds = userProjects.map(up => up.userId);

  return allUsers.filter(user =>
    userIds.includes(user.userId) && user.status === 'active'
  );
}

/**
 * 全アクティブユーザーのLINE IDを取得
 * @returns {string[]} LINE User ID配列
 */
function getAllActiveUserIds() {
  const users = getSheetData(CONFIG.SHEETS.USERS);
  return users
    .filter(user => user.status === 'active')
    .map(user => user.userId);
}

// ============================================
// 🏗️ プロジェクト管理
// ============================================

/**
 * プロジェクト一覧を取得
 * @returns {Object[]} プロジェクト配列
 */
function getProjects() {
  const projects = getSheetData(CONFIG.SHEETS.PROJECTS);
  return projects.filter(p => p.status === 'active');
}

/**
 * プロジェクトをIDで検索
 * @param {string} projectId - プロジェクトID
 * @returns {Object|null} プロジェクト情報
 */
function findProjectById(projectId) {
  return findInSheet(CONFIG.SHEETS.PROJECTS, 'projectId', projectId);
}

// ============================================
// 📝 ログ管理
// ============================================

/**
 * 送信ログを記録
 * @param {Object} logData - ログデータ
 */
function logNotification(logData) {
  const rowData = [
    Utilities.getUuid(),
    new Date().toISOString(),
    logData.type,
    logData.projectId || 'ALL',
    logData.targetCount,
    logData.successCount,
    logData.failCount,
    JSON.stringify(logData.payload || {})
  ];

  appendToSheet(CONFIG.SHEETS.LOGS, rowData);
}

// ============================================
// 🔧 ユーティリティ
// ============================================

/**
 * 日付をフォーマット（yyyy/MM/dd(E)形式）
 * @param {Date|string} date - 日付
 * @returns {string} フォーマット済み文字列
 */
function formatDate(date) {
  const d = new Date(date);
  const weekDays = ['日', '月', '火', '水', '木', '金', '土'];

  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const weekDay = weekDays[d.getDay()];

  return `${year}/${month}/${day}(${weekDay})`;
}

/**
 * 短い日付フォーマット（MM/dd(E)形式）
 * @param {Date|string} date - 日付
 * @returns {string} フォーマット済み文字列
 */
function formatDateShort(date) {
  const d = new Date(date);
  const weekDays = ['日', '月', '火', '水', '木', '金', '土'];

  const month = d.getMonth() + 1;
  const day = d.getDate();
  const weekDay = weekDays[d.getDay()];

  return `${month}/${day}(${weekDay})`;
}

/**
 * JSON形式でレスポンスを返す
 * @param {Object} data - レスポンスデータ
 * @returns {TextOutput} JSONレスポンス
 */
function jsonResponse(data) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * エラーレスポンスを生成
 * @param {string} message - エラーメッセージ
 * @param {number} code - エラーコード
 * @returns {Object} エラーオブジェクト
 */
function createError(message, code = 500) {
  return {
    success: false,
    error: {
      code: code,
      message: message
    }
  };
}

/**
 * 成功レスポンスを生成
 * @param {Object} data - レスポンスデータ
 * @param {string} message - 成功メッセージ
 * @returns {Object} 成功オブジェクト
 */
function createSuccess(data = {}, message = 'Success') {
  return {
    success: true,
    message: message,
    data: data
  };
}
