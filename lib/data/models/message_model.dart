import 'user_model.dart';
import 'attachment_model.dart';

/// Message model for project chat
class Message {
  final String id;
  final String projectId;
  final String senderId;
  final User? sender;
  final String content;
  final String type;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isRead;
  final List<String> readBy;
  final List<Attachment> attachments;
  final String? replyToId;
  final Message? replyTo;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final Map<String, int> reactions;

  const Message({
    required this.id,
    required this.projectId,
    required this.senderId,
    this.sender,
    required this.content,
    this.type = 'text',
    required this.sentAt,
    this.readAt,
    this.isRead = false,
    this.readBy = const [],
    this.attachments = const [],
    this.replyToId,
    this.replyTo,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.reactions = const {},
  });

  Message copyWith({
    String? id,
    String? projectId,
    String? senderId,
    User? sender,
    String? content,
    String? type,
    DateTime? sentAt,
    DateTime? readAt,
    bool? isRead,
    List<String>? readBy,
    List<Attachment>? attachments,
    String? replyToId,
    Message? replyTo,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    Map<String, int>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      attachments: attachments ?? this.attachments,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      reactions: reactions ?? this.reactions,
    );
  }

  bool get hasAttachments => attachments.isNotEmpty;

  bool get isSystemMessage => type == 'system';

  String get displayContent {
    if (isDeleted) return 'このメッセージは削除されました';
    return content;
  }

  String get timeString {
    final now = DateTime.now();
    final diff = now.difference(sentAt);

    if (diff.inDays == 0) {
      return '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨日 ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final weekDays = ['日', '月', '火', '水', '木', '金', '土'];
      return '${weekDays[sentAt.weekday % 7]} ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${sentAt.month}/${sentAt.day} ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'senderId': senderId,
      'sender': sender?.toJson(),
      'content': content,
      'type': type,
      'sentAt': sentAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isRead': isRead,
      'readBy': readBy,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'replyToId': replyToId,
      'replyTo': replyTo?.toJson(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'reactions': reactions,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      senderId: json['senderId'] as String,
      sender: json['sender'] != null
          ? User.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'text',
      sentAt: DateTime.parse(json['sentAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      readBy: (json['readBy'] as List?)?.cast<String>() ?? [],
      attachments: (json['attachments'] as List?)
              ?.map((a) => Attachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      replyToId: json['replyToId'] as String?,
      replyTo: json['replyTo'] != null
          ? Message.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      reactions: (json['reactions'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Message type definitions
class MessageType {
  static const String text = 'text';
  static const String image = 'image';
  static const String file = 'file';
  static const String system = 'system';
  static const String taskUpdate = 'task_update';
  static const String mention = 'mention';
}

/// Chat group for organizing messages by date
class MessageGroup {
  final DateTime date;
  final List<Message> messages;

  const MessageGroup({
    required this.date,
    required this.messages,
  });

  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groupDate = DateTime(date.year, date.month, date.day);

    if (groupDate == today) return '今日';
    if (groupDate == today.subtract(const Duration(days: 1))) return '昨日';
    if (now.difference(date).inDays < 7) {
      final weekDays = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];
      return weekDays[date.weekday % 7];
    }
    return '${date.year}/${date.month}/${date.day}';
  }

  static List<MessageGroup> groupByDate(List<Message> messages) {
    final groups = <DateTime, List<Message>>{};

    for (final message in messages) {
      final date = DateTime(
        message.sentAt.year,
        message.sentAt.month,
        message.sentAt.day,
      );
      groups.putIfAbsent(date, () => []).add(message);
    }

    return groups.entries
        .map((e) => MessageGroup(date: e.key, messages: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
