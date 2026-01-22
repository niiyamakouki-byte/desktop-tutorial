/**
 * Genba-LINE Commander - Database Utilities
 * スプレッドシート操作ヘルパー
 */

// ===========================================
// 汎用ヘルパー
// ===========================================

/**
 * スプレッドシートを取得
 */
function getSpreadsheet() {
  const config = getConfig();
  return SpreadsheetApp.openById(config.SPREADSHEET_ID);
}

/**
 * シートを取得
 */
function getSheet(sheetName) {
  return getSpreadsheet().getSheetByName(sheetName);
}

/**
 * シートの全データを取得（ヘッダー除く）
 */
function getSheetData(sheetName) {
  const sheet = getSheet(sheetName);
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  return data.slice(1).map(row => {
    const obj = {};
    headers.forEach((header, i) => {
      obj[header] = row[i];
    });
    return obj;
  });
}

/**
 * IDで行を検索してインデックスを返す（1-based、ヘッダー含む）
 */
function findRowById(sheetName, id, idColumn = 'id') {
  const sheet = getSheet(sheetName);
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf(idColumn);

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === id) {
      return i + 1; // 1-based row number
    }
  }
  return -1;
}

// ===========================================
// Projects 操作
// ===========================================

/**
 * 全プロジェクトを取得
 */
function getAllProjects() {
  return getSheetData(SHEET_NAMES.PROJECTS);
}

/**
 * IDでプロジェクトを取得
 */
function getProjectById(projectId) {
  const projects = getAllProjects();
  return projects.find(p => p.id === projectId) || null;
}

// ===========================================
// Users 操作
// ===========================================

/**
 * 全ユーザーを取得
 */
function getAllUsers() {
  return getSheetData(SHEET_NAMES.USERS);
}

/**
 * LINE UIDでユーザーを取得
 */
function getUserByLineUid(lineUid) {
  const users = getAllUsers();
  return users.find(u => u.line_uid === lineUid) || null;
}

/**
 * UIDリストからユーザー名リストを取得
 */
function getUserNamesByUids(uidsString) {
  if (!uidsString) return [];
  const uids = uidsString.split(',').map(u => u.trim());
  const users = getAllUsers();

  return uids.map(uid => {
    const user = users.find(u => u.line_uid === uid);
    return user ? user.name : uid;
  });
}

/**
 * 友だち追加時にユーザー登録
 */
function registerUser(lineUid, displayName) {
  const existing = getUserByLineUid(lineUid);
  if (existing) return existing;

  const sheet = getSheet(SHEET_NAMES.USERS);
  sheet.appendRow([lineUid, displayName, USER_ROLE.STAFF]);

  return {
    line_uid: lineUid,
    name: displayName,
    role: USER_ROLE.STAFF,
  };
}

// ===========================================
// Schedule 操作
// ===========================================

/**
 * 全スケジュールを取得
 */
function getAllSchedules() {
  const schedules = getSheetData(SHEET_NAMES.SCHEDULE);
  const projects = getAllProjects();

  return schedules.map(s => {
    const project = projects.find(p => p.id === s.project_id);
    return {
      ...s,
      project_name: project ? project.name : '不明',
      map_url: project ? project.map_url : '',
      drive_url: project ? project.drive_url : '',
    };
  });
}

/**
 * IDでスケジュールを取得
 */
function getScheduleById(scheduleId) {
  const schedules = getAllSchedules();
  return schedules.find(s => s.id === scheduleId) || null;
}

/**
 * 日付でスケジュールを取得
 */
function getSchedulesByDate(dateStr) {
  const schedules = getAllSchedules();
  return schedules.filter(s => {
    // 日付を文字列で比較
    const scheduleDate = s.date instanceof Date
      ? Utilities.formatDate(s.date, 'Asia/Tokyo', 'yyyy-MM-dd')
      : s.date;
    return scheduleDate === dateStr && s.status === TASK_STATUS.ACTIVE;
  });
}

/**
 * ユーザーの特定日のスケジュールを取得
 */
function getSchedulesByUserAndDate(lineUid, dateStr) {
  const schedules = getSchedulesByDate(dateStr);
  return schedules.filter(s => {
    const members = s.member_uids ? s.member_uids.split(',').map(m => m.trim()) : [];
    return members.includes(lineUid);
  });
}

/**
 * 未定（Pending）タスクを取得
 */
function getPendingSchedules() {
  const schedules = getAllSchedules();
  return schedules.filter(s => s.status === TASK_STATUS.PENDING || !s.date);
}

/**
 * 今後7日間のスケジュールを取得
 */
function getUpcomingSchedules(days = 7) {
  const schedules = getAllSchedules();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const endDate = new Date(today);
  endDate.setDate(endDate.getDate() + days);

  return schedules.filter(s => {
    if (!s.date || s.status !== TASK_STATUS.ACTIVE) return false;

    const scheduleDate = s.date instanceof Date ? s.date : new Date(s.date);
    scheduleDate.setHours(0, 0, 0, 0);

    return scheduleDate >= today && scheduleDate <= endDate;
  }).sort((a, b) => {
    const dateA = a.date instanceof Date ? a.date : new Date(a.date);
    const dateB = b.date instanceof Date ? b.date : new Date(b.date);
    return dateA - dateB;
  });
}

/**
 * スケジュールを更新
 */
function updateSchedule(scheduleId, updates) {
  const sheet = getSheet(SHEET_NAMES.SCHEDULE);
  const data = sheet.getDataRange().getValues();
  const headers = data[0];

  const rowIndex = findRowById(SHEET_NAMES.SCHEDULE, scheduleId);
  if (rowIndex === -1) {
    throw new Error(`Schedule not found: ${scheduleId}`);
  }

  // 各フィールドを更新
  Object.keys(updates).forEach(key => {
    const colIndex = headers.indexOf(key);
    if (colIndex !== -1) {
      sheet.getRange(rowIndex, colIndex + 1).setValue(updates[key]);
    }
  });

  return getScheduleById(scheduleId);
}

/**
 * 新しいスケジュールを追加
 */
function addSchedule(scheduleData) {
  const sheet = getSheet(SHEET_NAMES.SCHEDULE);

  // 新しいIDを生成
  const schedules = getAllSchedules();
  const maxId = schedules.reduce((max, s) => {
    const num = parseInt(s.id.replace('S', ''), 10);
    return num > max ? num : max;
  }, 0);
  const newId = `S${String(maxId + 1).padStart(3, '0')}`;

  const row = [
    newId,
    scheduleData.project_id || '',
    scheduleData.date || '',
    scheduleData.task_name || '',
    scheduleData.member_uids || '',
    scheduleData.note || '',
    scheduleData.status || TASK_STATUS.ACTIVE,
  ];

  sheet.appendRow(row);
  return getScheduleById(newId);
}

/**
 * メンバーの日付重複チェック
 */
function checkMemberConflicts(memberUids, dateStr, excludeScheduleId = null) {
  const schedules = getSchedulesByDate(dateStr);
  const members = memberUids.split(',').map(m => m.trim());
  const conflicts = [];

  schedules.forEach(s => {
    if (excludeScheduleId && s.id === excludeScheduleId) return;

    const scheduleMembers = s.member_uids ? s.member_uids.split(',').map(m => m.trim()) : [];
    const overlapping = members.filter(m => scheduleMembers.includes(m));

    if (overlapping.length > 0) {
      const names = getUserNamesByUids(overlapping.join(','));
      conflicts.push({
        scheduleId: s.id,
        projectName: s.project_name,
        taskName: s.task_name,
        conflictingMembers: names,
      });
    }
  });

  return conflicts;
}
