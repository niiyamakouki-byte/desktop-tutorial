/**
 * Genba-LINE Commander - Drive
 * Google Drive ファイル操作
 */

// ============================================
// 📁 ファイルアップロード
// ============================================

/**
 * Base64データをGoogle Driveにアップロード
 * @param {string} fileName - ファイル名
 * @param {string} base64Data - Base64エンコードされたファイルデータ
 * @param {string} mimeType - MIMEタイプ
 * @returns {Object} アップロード結果
 */
function uploadFileToDrive(fileName, base64Data, mimeType) {
  try {
    // Base64デコード
    const decoded = Utilities.base64Decode(base64Data);
    const blob = Utilities.newBlob(decoded, mimeType, fileName);

    // 保存先フォルダを取得
    const folder = DriveApp.getFolderById(CONFIG.DRIVE_FOLDER_ID);

    // ファイル名に日時を追加（重複防止）
    const timestamp = Utilities.formatDate(new Date(), 'Asia/Tokyo', 'yyyyMMdd_HHmmss');
    const uniqueFileName = `${timestamp}_${fileName}`;

    // アップロード実行
    const file = folder.createFile(blob.setName(uniqueFileName));

    // 閲覧権限を設定（リンクを知っている人は閲覧可能）
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

    // 結果を返却
    return createSuccess({
      fileId: file.getId(),
      fileName: uniqueFileName,
      fileUrl: file.getUrl(),
      viewUrl: `https://drive.google.com/file/d/${file.getId()}/view`,
      downloadUrl: `https://drive.google.com/uc?export=download&id=${file.getId()}`,
      mimeType: mimeType,
      size: file.getSize()
    }, 'ファイルをアップロードしました');

  } catch (error) {
    console.error('Upload error:', error);
    return createError(`アップロードに失敗しました: ${error.message}`);
  }
}

/**
 * 複数ファイルをアップロード
 * @param {Object[]} files - [{ fileName, base64Data, mimeType }, ...]
 * @returns {Object} アップロード結果
 */
function uploadMultipleFiles(files) {
  const results = [];
  let successCount = 0;
  let failCount = 0;

  files.forEach(file => {
    const result = uploadFileToDrive(file.fileName, file.base64Data, file.mimeType);
    if (result.success) {
      successCount++;
      results.push(result.data);
    } else {
      failCount++;
      results.push({ error: result.error, fileName: file.fileName });
    }
  });

  return createSuccess({
    files: results,
    successCount: successCount,
    failCount: failCount
  }, `${successCount}件のファイルをアップロードしました`);
}

// ============================================
// 📂 フォルダ操作
// ============================================

/**
 * プロジェクト用サブフォルダを作成/取得
 * @param {string} projectId - プロジェクトID
 * @param {string} projectName - プロジェクト名
 * @returns {Folder} フォルダオブジェクト
 */
function getProjectFolder(projectId, projectName) {
  const parentFolder = DriveApp.getFolderById(CONFIG.DRIVE_FOLDER_ID);
  const folderName = `${projectId}_${projectName}`;

  // 既存フォルダを検索
  const folders = parentFolder.getFoldersByName(folderName);
  if (folders.hasNext()) {
    return folders.next();
  }

  // なければ作成
  const newFolder = parentFolder.createFolder(folderName);
  newFolder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

  return newFolder;
}

/**
 * プロジェクトフォルダにファイルをアップロード
 * @param {string} projectId - プロジェクトID
 * @param {string} projectName - プロジェクト名
 * @param {string} fileName - ファイル名
 * @param {string} base64Data - Base64データ
 * @param {string} mimeType - MIMEタイプ
 * @returns {Object} アップロード結果
 */
function uploadToProjectFolder(projectId, projectName, fileName, base64Data, mimeType) {
  try {
    const folder = getProjectFolder(projectId, projectName);

    // Base64デコード
    const decoded = Utilities.base64Decode(base64Data);
    const blob = Utilities.newBlob(decoded, mimeType, fileName);

    // ファイル名に日時を追加
    const timestamp = Utilities.formatDate(new Date(), 'Asia/Tokyo', 'yyyyMMdd_HHmmss');
    const uniqueFileName = `${timestamp}_${fileName}`;

    // アップロード
    const file = folder.createFile(blob.setName(uniqueFileName));
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

    return createSuccess({
      fileId: file.getId(),
      fileName: uniqueFileName,
      fileUrl: file.getUrl(),
      viewUrl: `https://drive.google.com/file/d/${file.getId()}/view`,
      projectId: projectId
    }, 'ファイルをアップロードしました');

  } catch (error) {
    console.error('Project folder upload error:', error);
    return createError(`アップロードに失敗しました: ${error.message}`);
  }
}

// ============================================
// 📄 ファイル情報取得
// ============================================

/**
 * フォルダ内のファイル一覧を取得
 * @param {string} folderId - フォルダID（省略時はルートフォルダ）
 * @returns {Object[]} ファイル情報配列
 */
function getFileList(folderId) {
  try {
    const folder = folderId
      ? DriveApp.getFolderById(folderId)
      : DriveApp.getFolderById(CONFIG.DRIVE_FOLDER_ID);

    const files = folder.getFiles();
    const fileList = [];

    while (files.hasNext()) {
      const file = files.next();
      fileList.push({
        id: file.getId(),
        name: file.getName(),
        mimeType: file.getMimeType(),
        size: file.getSize(),
        createdDate: file.getDateCreated(),
        lastUpdated: file.getLastUpdated(),
        url: file.getUrl(),
        viewUrl: `https://drive.google.com/file/d/${file.getId()}/view`
      });
    }

    // 更新日時でソート（新しい順）
    fileList.sort((a, b) => b.lastUpdated - a.lastUpdated);

    return createSuccess({ files: fileList, count: fileList.length });

  } catch (error) {
    console.error('Get file list error:', error);
    return createError(`ファイル一覧の取得に失敗しました: ${error.message}`);
  }
}

/**
 * ファイル情報を取得
 * @param {string} fileId - ファイルID
 * @returns {Object} ファイル情報
 */
function getFileInfo(fileId) {
  try {
    const file = DriveApp.getFileById(fileId);

    return createSuccess({
      id: file.getId(),
      name: file.getName(),
      mimeType: file.getMimeType(),
      size: file.getSize(),
      createdDate: file.getDateCreated(),
      lastUpdated: file.getLastUpdated(),
      url: file.getUrl(),
      viewUrl: `https://drive.google.com/file/d/${file.getId()}/view`,
      downloadUrl: `https://drive.google.com/uc?export=download&id=${file.getId()}`
    });

  } catch (error) {
    console.error('Get file info error:', error);
    return createError(`ファイル情報の取得に失敗しました: ${error.message}`);
  }
}

// ============================================
// 🗑️ ファイル削除
// ============================================

/**
 * ファイルを削除（ゴミ箱へ移動）
 * @param {string} fileId - ファイルID
 * @returns {Object} 削除結果
 */
function deleteFile(fileId) {
  try {
    const file = DriveApp.getFileById(fileId);
    file.setTrashed(true);

    return createSuccess({ fileId: fileId }, 'ファイルを削除しました');

  } catch (error) {
    console.error('Delete file error:', error);
    return createError(`ファイルの削除に失敗しました: ${error.message}`);
  }
}

// ============================================
// 🔧 ユーティリティ
// ============================================

/**
 * MIMEタイプからファイル種別を判定
 * @param {string} mimeType - MIMEタイプ
 * @returns {string} ファイル種別
 */
function getFileType(mimeType) {
  const typeMap = {
    'application/pdf': 'PDF',
    'image/jpeg': '画像',
    'image/png': '画像',
    'image/gif': '画像',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'Excel',
    'application/vnd.ms-excel': 'Excel',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'Word',
    'application/msword': 'Word',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'PowerPoint',
    'application/vnd.ms-powerpoint': 'PowerPoint',
    'application/octet-stream': 'CAD/その他'
  };

  return typeMap[mimeType] || 'その他';
}

/**
 * ファイルサイズを読みやすい形式に変換
 * @param {number} bytes - バイト数
 * @returns {string} フォーマット済みサイズ
 */
function formatFileSize(bytes) {
  if (bytes === 0) return '0 B';

  const units = ['B', 'KB', 'MB', 'GB'];
  const k = 1024;
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + units[i];
}

// ============================================
// 🧪 テスト関数
// ============================================

/**
 * アップロードテスト（手動実行用）
 */
function testUpload() {
  // テスト用の小さなテキストファイル
  const testContent = 'これはテストファイルです。\n現場LINE Commander';
  const base64Data = Utilities.base64Encode(testContent);

  const result = uploadFileToDrive(
    'test.txt',
    base64Data,
    'text/plain'
  );

  console.log('Upload result:', JSON.stringify(result, null, 2));
}
