/**
 * Genba-LINE Commander - Backend
 * メインロジック（doGet/doPost/sendNotification）
 */

// ============================================
// 🌐 Web App エンドポイント
// ============================================

/**
 * GET リクエスト処理（LIFF HTML返却）
 * @param {Object} e - リクエストパラメータ
 * @returns {HtmlOutput} HTMLページ
 */
function doGet(e) {
  const template = HtmlService.createTemplateFromFile('index');

  // テンプレートに変数を渡す
  template.liffId = CONFIG.LIFF_ID;
  template.projects = JSON.stringify(getProjects());

  return template.evaluate()
    .setTitle('現場LINE Commander')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/**
 * POST リクエスト処理（LINE Webhook / LIFF API）
 * @param {Object} e - リクエストデータ
 * @returns {TextOutput} JSONレスポンス
 */
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);

    // LINE Webhook からのリクエスト
    if (data.events) {
      return handleLineWebhook(data.events);
    }

    // LIFF からの通知送信リクエスト
    if (data.action === 'sendNotification') {
      const result = sendNotification(data.type, data.payload);
      return jsonResponse(result);
    }

    // LIFF からのファイルアップロード
    if (data.action === 'uploadFile') {
      const result = uploadFileToDrive(data.fileName, data.base64Data, data.mimeType);
      return jsonResponse(result);
    }

    // プロジェクト一覧取得
    if (data.action === 'getProjects') {
      return jsonResponse(createSuccess({ projects: getProjects() }));
    }

    // ユーザー一覧取得（プロジェクト別）
    if (data.action === 'getProjectUsers') {
      const users = findUsersByProject(data.projectId);
      return jsonResponse(createSuccess({ users: users, count: users.length }));
    }

    return jsonResponse(createError('Unknown action', 400));

  } catch (error) {
    console.error('doPost error:', error);
    return jsonResponse(createError(error.message));
  }
}

// ============================================
// 📱 LINE Webhook 処理
// ============================================

/**
 * LINE Webhook イベント処理
 * @param {Object[]} events - LINEイベント配列
 * @returns {TextOutput} 成功レスポンス
 */
function handleLineWebhook(events) {
  events.forEach(event => {
    try {
      if (event.type === 'message' && event.message.type === 'text') {
        handleTextMessage(event);
      } else if (event.type === 'follow') {
        handleFollowEvent(event);
      }
    } catch (error) {
      console.error('Webhook event error:', error);
    }
  });

  return jsonResponse({ status: 'ok' });
}

/**
 * テキストメッセージ処理
 * @param {Object} event - LINEイベント
 */
function handleTextMessage(event) {
  const userId = event.source.userId;
  const text = event.message.text.trim();

  // 登録コマンド
  if (text === '登録' || text === 'とうろく') {
    handleRegistration(userId, event.replyToken);
    return;
  }

  // ヘルプコマンド
  if (text === 'ヘルプ' || text === 'help') {
    sendReplyMessage(event.replyToken, [
      createTextMessage('🏗️ 現場LINE Commander\n\n【コマンド一覧】\n・「登録」→ 通知を受け取る\n・「ヘルプ」→ この説明を表示')
    ]);
    return;
  }
}

/**
 * フォローイベント処理（友だち追加時）
 * @param {Object} event - LINEイベント
 */
function handleFollowEvent(event) {
  const userId = event.source.userId;

  // プロフィール取得
  const profile = getLineProfile(userId);
  const displayName = profile ? profile.displayName : '名前未設定';

  // ユーザー登録
  registerUser(userId, displayName);

  // ウェルカムメッセージ
  sendReplyMessage(event.replyToken, [
    createTextMessage(`🏗️ 現場LINE Commanderへようこそ！\n\n${displayName}さん、登録ありがとうございます。\n現場からの重要なお知らせをお届けします。`)
  ]);
}

/**
 * ユーザー登録処理
 * @param {string} userId - LINE User ID
 * @param {string} replyToken - 返信トークン
 */
function handleRegistration(userId, replyToken) {
  const existingUser = findUserById(userId);

  if (existingUser) {
    sendReplyMessage(replyToken, [
      createTextMessage(MESSAGES.REGISTRATION.ALREADY)
    ]);
    return;
  }

  // プロフィール取得
  const profile = getLineProfile(userId);
  const displayName = profile ? profile.displayName : '名前未設定';

  // 登録実行
  const success = registerUser(userId, displayName);

  if (success) {
    sendReplyMessage(replyToken, [
      createTextMessage(MESSAGES.REGISTRATION.SUCCESS)
    ]);
  } else {
    sendReplyMessage(replyToken, [
      createTextMessage(MESSAGES.REGISTRATION.ERROR)
    ]);
  }
}

// ============================================
// 📤 通知送信
// ============================================

/**
 * 通知を送信（メイン関数）
 * @param {string} type - 通知タイプ (rain_cancel / schedule_change / blueprint_update)
 * @param {Object} payload - 通知データ
 * @returns {Object} 送信結果
 */
function sendNotification(type, payload) {
  try {
    // 送信対象ユーザーを取得
    let targetUserIds;
    if (payload.projectId && payload.projectId !== 'all') {
      const users = findUsersByProject(payload.projectId);
      targetUserIds = users.map(u => u.userId);
    } else {
      targetUserIds = getAllActiveUserIds();
    }

    if (targetUserIds.length === 0) {
      return createError('送信対象のユーザーがいません', 400);
    }

    // Flex Message を生成
    let flexMessage;
    switch (type) {
      case CONFIG.NOTIFICATION_TYPES.RAIN_CANCEL:
        flexMessage = createRainCancelMessage(payload);
        break;
      case CONFIG.NOTIFICATION_TYPES.SCHEDULE_CHANGE:
        flexMessage = createScheduleChangeMessage(payload);
        break;
      case CONFIG.NOTIFICATION_TYPES.BLUEPRINT_UPDATE:
        flexMessage = createBlueprintUpdateMessage(payload);
        break;
      default:
        return createError(`Unknown notification type: ${type}`, 400);
    }

    // マルチキャスト送信（最大500人まで）
    const results = sendMulticastMessage(targetUserIds, [flexMessage]);

    // ログ記録
    logNotification({
      type: type,
      projectId: payload.projectId,
      targetCount: targetUserIds.length,
      successCount: results.successCount,
      failCount: results.failCount,
      payload: payload
    });

    return createSuccess({
      sent: results.successCount,
      failed: results.failCount,
      total: targetUserIds.length
    }, `${results.successCount}人に送信しました`);

  } catch (error) {
    console.error('sendNotification error:', error);
    return createError(error.message);
  }
}

// ============================================
// 💬 Flex Message 生成
// ============================================

/**
 * 雨天中止通知メッセージ
 * @param {Object} payload - { projectId, projectName, date, address, note }
 * @returns {Object} Flex Message
 */
function createRainCancelMessage(payload) {
  const color = COLORS.RAIN_CANCEL;
  const project = payload.projectName || '未設定';
  const date = payload.date ? formatDateShort(payload.date) : '明日';
  const address = payload.address || '';
  const note = payload.note || '';

  const bodyContents = [
    {
      type: 'text',
      text: MESSAGES.RAIN_CANCEL.body,
      wrap: true,
      color: COLORS.GRAY,
      size: 'md'
    },
    {
      type: 'separator',
      margin: 'lg'
    },
    {
      type: 'box',
      layout: 'vertical',
      margin: 'lg',
      spacing: 'sm',
      contents: [
        {
          type: 'box',
          layout: 'baseline',
          spacing: 'sm',
          contents: [
            { type: 'text', text: '現場', color: COLORS.LIGHT_GRAY, size: 'sm', flex: 1 },
            { type: 'text', text: project, wrap: true, color: COLORS.GRAY, size: 'sm', flex: 4 }
          ]
        },
        {
          type: 'box',
          layout: 'baseline',
          spacing: 'sm',
          contents: [
            { type: 'text', text: '日付', color: COLORS.LIGHT_GRAY, size: 'sm', flex: 1 },
            { type: 'text', text: date, wrap: true, color: COLORS.GRAY, size: 'sm', flex: 4 }
          ]
        }
      ]
    }
  ];

  // 備考があれば追加
  if (note) {
    bodyContents.push({
      type: 'box',
      layout: 'vertical',
      margin: 'lg',
      contents: [
        { type: 'text', text: '備考', color: COLORS.LIGHT_GRAY, size: 'xs' },
        { type: 'text', text: note, wrap: true, color: COLORS.GRAY, size: 'sm', margin: 'sm' }
      ]
    });
  }

  const footerContents = [];

  // 📍 住所があればGoogleマップボタンを追加
  if (address) {
    footerContents.push({
      type: 'button',
      style: 'secondary',
      height: 'sm',
      action: {
        type: 'uri',
        label: '📍 現場をマップで確認',
        uri: `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`
      }
    });
  }

  return {
    type: 'flex',
    altText: `${color.icon} ${MESSAGES.RAIN_CANCEL.title}`,
    contents: {
      type: 'bubble',
      header: {
        type: 'box',
        layout: 'vertical',
        backgroundColor: color.primary,
        paddingAll: 'lg',
        contents: [
          {
            type: 'text',
            text: `${color.icon} ${MESSAGES.RAIN_CANCEL.title}`,
            color: COLORS.WHITE,
            weight: 'bold',
            size: 'lg'
          }
        ]
      },
      body: {
        type: 'box',
        layout: 'vertical',
        contents: bodyContents
      },
      footer: footerContents.length > 0 ? {
        type: 'box',
        layout: 'vertical',
        spacing: 'sm',
        contents: footerContents
      } : undefined,
      styles: {
        footer: { separator: true }
      }
    }
  };
}

/**
 * 工程変更通知メッセージ
 * @param {Object} payload - { projectId, projectName, oldDate, newDate, address, note }
 * @returns {Object} Flex Message
 */
function createScheduleChangeMessage(payload) {
  const color = COLORS.SCHEDULE_CHANGE;
  const project = payload.projectName || '未設定';
  const oldDate = payload.oldDate ? formatDateShort(payload.oldDate) : '未設定';
  const newDate = payload.newDate ? formatDateShort(payload.newDate) : '未設定';
  const address = payload.address || '';
  const note = payload.note || '';

  const bodyContents = [
    {
      type: 'text',
      text: MESSAGES.SCHEDULE_CHANGE.body,
      wrap: true,
      color: COLORS.GRAY,
      size: 'md'
    },
    {
      type: 'separator',
      margin: 'lg'
    },
    {
      type: 'box',
      layout: 'vertical',
      margin: 'lg',
      spacing: 'sm',
      contents: [
        {
          type: 'box',
          layout: 'baseline',
          spacing: 'sm',
          contents: [
            { type: 'text', text: '現場', color: COLORS.LIGHT_GRAY, size: 'sm', flex: 1 },
            { type: 'text', text: project, wrap: true, color: COLORS.GRAY, size: 'sm', flex: 4 }
          ]
        }
      ]
    },
    // 日程変更を目立たせるボックス
    {
      type: 'box',
      layout: 'horizontal',
      margin: 'lg',
      spacing: 'md',
      contents: [
        {
          type: 'box',
          layout: 'vertical',
          flex: 1,
          contents: [
            { type: 'text', text: '旧日程', color: COLORS.LIGHT_GRAY, size: 'xs', align: 'center' },
            {
              type: 'text',
              text: oldDate,
              size: 'md',
              align: 'center',
              color: COLORS.GRAY,
              decoration: 'line-through'
            }
          ]
        },
        {
          type: 'text',
          text: '→',
          size: 'xl',
          gravity: 'center',
          color: color.primary
        },
        {
          type: 'box',
          layout: 'vertical',
          flex: 1,
          contents: [
            { type: 'text', text: '新日程', color: color.primary, size: 'xs', align: 'center', weight: 'bold' },
            {
              type: 'text',
              text: newDate,
              size: 'lg',
              weight: 'bold',
              align: 'center',
              color: color.text
            }
          ]
        }
      ]
    }
  ];

  // 備考があれば追加
  if (note) {
    bodyContents.push({
      type: 'box',
      layout: 'vertical',
      margin: 'lg',
      contents: [
        { type: 'text', text: '備考', color: COLORS.LIGHT_GRAY, size: 'xs' },
        { type: 'text', text: note, wrap: true, color: COLORS.GRAY, size: 'sm', margin: 'sm' }
      ]
    });
  }

  const footerContents = [];

  // 📍 住所があればGoogleマップボタンを追加
  if (address) {
    footerContents.push({
      type: 'button',
      style: 'secondary',
      height: 'sm',
      action: {
        type: 'uri',
        label: '📍 現場をマップで確認',
        uri: `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`
      }
    });
  }

  return {
    type: 'flex',
    altText: `${color.icon} ${MESSAGES.SCHEDULE_CHANGE.title}`,
    contents: {
      type: 'bubble',
      header: {
        type: 'box',
        layout: 'vertical',
        backgroundColor: color.primary,
        paddingAll: 'lg',
        contents: [
          {
            type: 'text',
            text: `${color.icon} ${MESSAGES.SCHEDULE_CHANGE.title}`,
            color: COLORS.WHITE,
            weight: 'bold',
            size: 'lg'
          }
        ]
      },
      body: {
        type: 'box',
        layout: 'vertical',
        contents: bodyContents
      },
      footer: footerContents.length > 0 ? {
        type: 'box',
        layout: 'vertical',
        spacing: 'sm',
        contents: footerContents
      } : undefined,
      styles: {
        footer: { separator: true }
      }
    }
  };
}

/**
 * 図面更新通知メッセージ
 * @param {Object} payload - { projectId, projectName, fileName, fileUrl, address, note }
 * @returns {Object} Flex Message
 */
function createBlueprintUpdateMessage(payload) {
  const color = COLORS.BLUEPRINT_UPDATE;
  const project = payload.projectName || '未設定';
  const fileName = payload.fileName || '図面ファイル';
  const fileUrl = payload.fileUrl || '';
  const address = payload.address || '';
  const note = payload.note || '';

  const bodyContents = [
    {
      type: 'text',
      text: MESSAGES.BLUEPRINT_UPDATE.body,
      wrap: true,
      color: COLORS.GRAY,
      size: 'md'
    },
    {
      type: 'separator',
      margin: 'lg'
    },
    {
      type: 'box',
      layout: 'vertical',
      margin: 'lg',
      spacing: 'sm',
      contents: [
        {
          type: 'box',
          layout: 'baseline',
          spacing: 'sm',
          contents: [
            { type: 'text', text: '現場', color: COLORS.LIGHT_GRAY, size: 'sm', flex: 1 },
            { type: 'text', text: project, wrap: true, color: COLORS.GRAY, size: 'sm', flex: 4 }
          ]
        },
        {
          type: 'box',
          layout: 'baseline',
          spacing: 'sm',
          contents: [
            { type: 'text', text: 'ファイル', color: COLORS.LIGHT_GRAY, size: 'sm', flex: 1 },
            { type: 'text', text: fileName, wrap: true, color: COLORS.GRAY, size: 'sm', flex: 4 }
          ]
        }
      ]
    }
  ];

  // 備考があれば追加
  if (note) {
    bodyContents.push({
      type: 'box',
      layout: 'vertical',
      margin: 'lg',
      contents: [
        { type: 'text', text: '備考', color: COLORS.LIGHT_GRAY, size: 'xs' },
        { type: 'text', text: note, wrap: true, color: COLORS.GRAY, size: 'sm', margin: 'sm' }
      ]
    });
  }

  const footerContents = [];

  // 図面表示ボタン（メイン）
  if (fileUrl) {
    footerContents.push({
      type: 'button',
      style: 'primary',
      height: 'sm',
      color: color.primary,
      action: {
        type: 'uri',
        label: '📐 図面を開く',
        uri: fileUrl
      }
    });
  }

  // 📍 住所があればGoogleマップボタンを追加
  if (address) {
    footerContents.push({
      type: 'button',
      style: 'secondary',
      height: 'sm',
      action: {
        type: 'uri',
        label: '📍 現場をマップで確認',
        uri: `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`
      }
    });
  }

  return {
    type: 'flex',
    altText: `${color.icon} ${MESSAGES.BLUEPRINT_UPDATE.title}`,
    contents: {
      type: 'bubble',
      header: {
        type: 'box',
        layout: 'vertical',
        backgroundColor: color.primary,
        paddingAll: 'lg',
        contents: [
          {
            type: 'text',
            text: `${color.icon} ${MESSAGES.BLUEPRINT_UPDATE.title}`,
            color: COLORS.WHITE,
            weight: 'bold',
            size: 'lg'
          }
        ]
      },
      body: {
        type: 'box',
        layout: 'vertical',
        contents: bodyContents
      },
      footer: footerContents.length > 0 ? {
        type: 'box',
        layout: 'vertical',
        spacing: 'sm',
        contents: footerContents
      } : undefined,
      styles: {
        footer: { separator: true }
      }
    }
  };
}

// ============================================
// 📡 LINE API 送信
// ============================================

/**
 * リプライメッセージを送信
 * @param {string} replyToken - 返信トークン
 * @param {Object[]} messages - メッセージ配列
 */
function sendReplyMessage(replyToken, messages) {
  const options = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${CONFIG.LINE_CHANNEL_ACCESS_TOKEN}`
    },
    payload: JSON.stringify({
      replyToken: replyToken,
      messages: messages
    })
  };

  try {
    UrlFetchApp.fetch('https://api.line.me/v2/bot/message/reply', options);
  } catch (error) {
    console.error('Reply message error:', error);
  }
}

/**
 * プッシュメッセージを送信（個別）
 * @param {string} userId - LINE User ID
 * @param {Object[]} messages - メッセージ配列
 * @returns {boolean} 成功/失敗
 */
function sendPushMessage(userId, messages) {
  const options = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${CONFIG.LINE_CHANNEL_ACCESS_TOKEN}`
    },
    payload: JSON.stringify({
      to: userId,
      messages: messages
    }),
    muteHttpExceptions: true
  };

  try {
    const response = UrlFetchApp.fetch(CONFIG.LINE_PUSH_API_URL, options);
    return response.getResponseCode() === 200;
  } catch (error) {
    console.error('Push message error:', error);
    return false;
  }
}

/**
 * マルチキャストメッセージを送信（複数人同時）
 * @param {string[]} userIds - LINE User ID配列（最大500人）
 * @param {Object[]} messages - メッセージ配列
 * @returns {Object} { successCount, failCount }
 */
function sendMulticastMessage(userIds, messages) {
  const MAX_RECIPIENTS = 500;
  let successCount = 0;
  let failCount = 0;

  // 500人ずつ分割して送信
  for (let i = 0; i < userIds.length; i += MAX_RECIPIENTS) {
    const batch = userIds.slice(i, i + MAX_RECIPIENTS);

    const options = {
      method: 'post',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${CONFIG.LINE_CHANNEL_ACCESS_TOKEN}`
      },
      payload: JSON.stringify({
        to: batch,
        messages: messages
      }),
      muteHttpExceptions: true
    };

    try {
      const response = UrlFetchApp.fetch(CONFIG.LINE_MULTICAST_API_URL, options);
      if (response.getResponseCode() === 200) {
        successCount += batch.length;
      } else {
        console.error('Multicast error:', response.getContentText());
        failCount += batch.length;
      }
    } catch (error) {
      console.error('Multicast error:', error);
      failCount += batch.length;
    }
  }

  return { successCount, failCount };
}

/**
 * LINEプロフィール取得
 * @param {string} userId - LINE User ID
 * @returns {Object|null} プロフィール情報
 */
function getLineProfile(userId) {
  const options = {
    method: 'get',
    headers: {
      'Authorization': `Bearer ${CONFIG.LINE_CHANNEL_ACCESS_TOKEN}`
    },
    muteHttpExceptions: true
  };

  try {
    const response = UrlFetchApp.fetch(
      `https://api.line.me/v2/bot/profile/${userId}`,
      options
    );

    if (response.getResponseCode() === 200) {
      return JSON.parse(response.getContentText());
    }
    return null;
  } catch (error) {
    console.error('Get profile error:', error);
    return null;
  }
}

/**
 * テキストメッセージオブジェクト生成
 * @param {string} text - メッセージテキスト
 * @returns {Object} メッセージオブジェクト
 */
function createTextMessage(text) {
  return {
    type: 'text',
    text: text
  };
}
