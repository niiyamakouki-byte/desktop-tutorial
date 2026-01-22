/**
 * Genba-LINE Commander - LINE API Utilities
 * LINE Messaging API ヘルパー
 */

// ===========================================
// メッセージ送信
// ===========================================

/**
 * Push Message を送信
 */
function sendPushMessage(lineUid, messages) {
  const config = getConfig();
  const url = 'https://api.line.me/v2/bot/message/push';

  const payload = {
    to: lineUid,
    messages: Array.isArray(messages) ? messages : [messages],
  };

  const options = {
    method: 'post',
    contentType: 'application/json',
    headers: {
      'Authorization': `Bearer ${config.LINE_CHANNEL_ACCESS_TOKEN}`,
    },
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  };

  try {
    const response = UrlFetchApp.fetch(url, options);
    const responseCode = response.getResponseCode();

    if (responseCode !== 200) {
      Logger.log(`Push Message Error: ${response.getContentText()}`);
      return { success: false, error: response.getContentText() };
    }

    return { success: true };
  } catch (e) {
    Logger.log(`Push Message Exception: ${e.message}`);
    return { success: false, error: e.message };
  }
}

/**
 * Multicast Message を送信（複数ユーザー）
 */
function sendMulticastMessage(lineUids, messages) {
  if (!lineUids || lineUids.length === 0) {
    return { success: false, error: 'No recipients' };
  }

  const config = getConfig();
  const url = 'https://api.line.me/v2/bot/message/multicast';

  const payload = {
    to: lineUids,
    messages: Array.isArray(messages) ? messages : [messages],
  };

  const options = {
    method: 'post',
    contentType: 'application/json',
    headers: {
      'Authorization': `Bearer ${config.LINE_CHANNEL_ACCESS_TOKEN}`,
    },
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  };

  try {
    const response = UrlFetchApp.fetch(url, options);
    const responseCode = response.getResponseCode();

    if (responseCode !== 200) {
      Logger.log(`Multicast Error: ${response.getContentText()}`);
      return { success: false, error: response.getContentText() };
    }

    return { success: true };
  } catch (e) {
    Logger.log(`Multicast Exception: ${e.message}`);
    return { success: false, error: e.message };
  }
}

/**
 * Reply Message を送信
 */
function sendReplyMessage(replyToken, messages) {
  const config = getConfig();
  const url = 'https://api.line.me/v2/bot/message/reply';

  const payload = {
    replyToken: replyToken,
    messages: Array.isArray(messages) ? messages : [messages],
  };

  const options = {
    method: 'post',
    contentType: 'application/json',
    headers: {
      'Authorization': `Bearer ${config.LINE_CHANNEL_ACCESS_TOKEN}`,
    },
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  };

  try {
    const response = UrlFetchApp.fetch(url, options);
    return { success: response.getResponseCode() === 200 };
  } catch (e) {
    Logger.log(`Reply Message Exception: ${e.message}`);
    return { success: false, error: e.message };
  }
}

// ===========================================
// Flex Message 生成
// ===========================================

/**
 * 雨天中止通知の Flex Message
 */
function createRainCancelFlexMessage(schedule) {
  return {
    type: 'flex',
    altText: `☔️ 【中止】${schedule.project_name}`,
    contents: {
      type: 'bubble',
      size: 'mega',
      header: {
        type: 'box',
        layout: 'vertical',
        contents: [
          {
            type: 'box',
            layout: 'horizontal',
            contents: [
              {
                type: 'text',
                text: '☔️',
                size: 'xxl',
                flex: 0,
              },
              {
                type: 'text',
                text: '作業中止',
                weight: 'bold',
                size: 'xl',
                color: '#FFFFFF',
                margin: 'md',
              },
            ],
          },
        ],
        backgroundColor: COLORS.RAIN,
        paddingAll: 'lg',
      },
      body: {
        type: 'box',
        layout: 'vertical',
        contents: [
          {
            type: 'text',
            text: schedule.project_name,
            weight: 'bold',
            size: 'lg',
            wrap: true,
          },
          {
            type: 'text',
            text: schedule.task_name,
            size: 'md',
            color: '#666666',
            margin: 'md',
            wrap: true,
          },
          {
            type: 'separator',
            margin: 'lg',
          },
          {
            type: 'text',
            text: '日程が未定になりました。\n再調整後、改めてご連絡します。',
            size: 'sm',
            color: '#888888',
            margin: 'lg',
            wrap: true,
          },
        ],
        paddingAll: 'lg',
      },
    },
  };
}

/**
 * 日程確定通知の Flex Message
 */
function createRescheduleFlexMessage(schedule, newDate) {
  const dateObj = new Date(newDate);
  const dateStr = Utilities.formatDate(dateObj, 'Asia/Tokyo', 'M月d日(E)');
  const memberNames = getUserNamesByUids(schedule.member_uids);

  const contents = [
    {
      type: 'text',
      text: schedule.project_name,
      weight: 'bold',
      size: 'lg',
      wrap: true,
    },
    {
      type: 'text',
      text: schedule.task_name,
      size: 'md',
      color: '#666666',
      margin: 'sm',
      wrap: true,
    },
    {
      type: 'separator',
      margin: 'lg',
    },
    {
      type: 'box',
      layout: 'horizontal',
      contents: [
        {
          type: 'text',
          text: '📅 日程',
          size: 'sm',
          color: '#888888',
          flex: 2,
        },
        {
          type: 'text',
          text: dateStr,
          size: 'sm',
          weight: 'bold',
          flex: 4,
        },
      ],
      margin: 'lg',
    },
    {
      type: 'box',
      layout: 'horizontal',
      contents: [
        {
          type: 'text',
          text: '👷 メンバー',
          size: 'sm',
          color: '#888888',
          flex: 2,
        },
        {
          type: 'text',
          text: memberNames.join('、'),
          size: 'sm',
          flex: 4,
          wrap: true,
        },
      ],
      margin: 'md',
    },
  ];

  // 備考があれば追加
  if (schedule.note) {
    contents.push({
      type: 'box',
      layout: 'horizontal',
      contents: [
        {
          type: 'text',
          text: '📝 備考',
          size: 'sm',
          color: '#888888',
          flex: 2,
        },
        {
          type: 'text',
          text: schedule.note,
          size: 'sm',
          flex: 4,
          wrap: true,
        },
      ],
      margin: 'md',
    });
  }

  const footer = {
    type: 'box',
    layout: 'vertical',
    contents: [],
    paddingAll: 'lg',
  };

  // 地図URLがあればボタン追加
  if (schedule.map_url) {
    footer.contents.push({
      type: 'button',
      action: {
        type: 'uri',
        label: '📍 現場の地図を開く',
        uri: schedule.map_url,
      },
      style: 'primary',
      color: COLORS.ACTIVE,
    });
  }

  return {
    type: 'flex',
    altText: `📅 【日程確定】${schedule.project_name} - ${dateStr}`,
    contents: {
      type: 'bubble',
      size: 'mega',
      header: {
        type: 'box',
        layout: 'vertical',
        contents: [
          {
            type: 'box',
            layout: 'horizontal',
            contents: [
              {
                type: 'text',
                text: '📅',
                size: 'xxl',
                flex: 0,
              },
              {
                type: 'text',
                text: '日程確定',
                weight: 'bold',
                size: 'xl',
                color: '#FFFFFF',
                margin: 'md',
              },
            ],
          },
        ],
        backgroundColor: COLORS.ACTIVE,
        paddingAll: 'lg',
      },
      body: {
        type: 'box',
        layout: 'vertical',
        contents: contents,
        paddingAll: 'lg',
      },
      footer: footer.contents.length > 0 ? footer : undefined,
    },
  };
}

/**
 * 日次レポート（明日の予定）の Flex Message
 */
function createDailyReportFlexMessage(schedules, dateStr) {
  const dateObj = new Date(dateStr);
  const displayDate = Utilities.formatDate(dateObj, 'Asia/Tokyo', 'M月d日(E)');

  if (schedules.length === 0) {
    return {
      type: 'text',
      text: `📋 ${displayDate}の予定はありません。`,
    };
  }

  const bubbles = schedules.map(schedule => {
    const memberNames = getUserNamesByUids(schedule.member_uids);

    const bodyContents = [
      {
        type: 'text',
        text: schedule.project_name,
        weight: 'bold',
        size: 'lg',
        wrap: true,
      },
      {
        type: 'text',
        text: schedule.task_name,
        size: 'md',
        color: '#666666',
        margin: 'sm',
        wrap: true,
      },
      {
        type: 'separator',
        margin: 'lg',
      },
      {
        type: 'box',
        layout: 'horizontal',
        contents: [
          {
            type: 'text',
            text: '👷 メンバー',
            size: 'sm',
            color: '#888888',
            flex: 2,
          },
          {
            type: 'text',
            text: memberNames.join('、'),
            size: 'sm',
            flex: 4,
            wrap: true,
          },
        ],
        margin: 'lg',
      },
    ];

    if (schedule.note) {
      bodyContents.push({
        type: 'box',
        layout: 'horizontal',
        contents: [
          {
            type: 'text',
            text: '🅿️ 駐車場',
            size: 'sm',
            color: '#888888',
            flex: 2,
          },
          {
            type: 'text',
            text: schedule.note,
            size: 'sm',
            flex: 4,
            wrap: true,
          },
        ],
        margin: 'md',
      });
    }

    const bubble = {
      type: 'bubble',
      size: 'kilo',
      body: {
        type: 'box',
        layout: 'vertical',
        contents: bodyContents,
        paddingAll: 'lg',
      },
    };

    // 地図ボタン
    if (schedule.map_url) {
      bubble.footer = {
        type: 'box',
        layout: 'vertical',
        contents: [
          {
            type: 'button',
            action: {
              type: 'uri',
              label: '📍 地図',
              uri: schedule.map_url,
            },
            style: 'primary',
            color: COLORS.ACTIVE,
            height: 'sm',
          },
        ],
        paddingAll: 'md',
      };
    }

    return bubble;
  });

  return {
    type: 'flex',
    altText: `📋 ${displayDate}の予定（${schedules.length}件）`,
    contents: {
      type: 'carousel',
      contents: bubbles.slice(0, 10), // LINE制限: 最大10件
    },
  };
}

/**
 * 歓迎メッセージ
 */
function createWelcomeMessage(userName) {
  return {
    type: 'flex',
    altText: 'Genba-LINE Commanderへようこそ！',
    contents: {
      type: 'bubble',
      body: {
        type: 'box',
        layout: 'vertical',
        contents: [
          {
            type: 'text',
            text: '🏗️ Genba-LINE Commander',
            weight: 'bold',
            size: 'lg',
          },
          {
            type: 'text',
            text: `${userName}さん、登録ありがとうございます！`,
            margin: 'lg',
            wrap: true,
          },
          {
            type: 'text',
            text: 'このBotでは、以下の通知が届きます：',
            margin: 'md',
            size: 'sm',
            color: '#666666',
            wrap: true,
          },
          {
            type: 'text',
            text: '📅 明日の現場予定\n☔️ 雨天中止のお知らせ\n📝 日程変更のお知らせ',
            margin: 'md',
            size: 'sm',
            wrap: true,
          },
        ],
        paddingAll: 'lg',
      },
    },
  };
}
