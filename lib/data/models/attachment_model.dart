/// Attachment model for files shared in chat or associated with tasks
class Attachment {
  final String id;
  final String projectId;
  final String name;
  final String url;
  final String type;
  final int size;
  final String? thumbnailUrl;
  final String uploadedBy;
  final DateTime uploadedAt;
  final bool isPinned;
  final String? description;
  final String? messageId;
  final String? taskId;

  const Attachment({
    required this.id,
    required this.projectId,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    this.thumbnailUrl,
    required this.uploadedBy,
    required this.uploadedAt,
    this.isPinned = false,
    this.description,
    this.messageId,
    this.taskId,
  });

  Attachment copyWith({
    String? id,
    String? projectId,
    String? name,
    String? url,
    String? type,
    int? size,
    String? thumbnailUrl,
    String? uploadedBy,
    DateTime? uploadedAt,
    bool? isPinned,
    String? description,
    String? messageId,
    String? taskId,
  }) {
    return Attachment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      size: size ?? this.size,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isPinned: isPinned ?? this.isPinned,
      description: description ?? this.description,
      messageId: messageId ?? this.messageId,
      taskId: taskId ?? this.taskId,
    );
  }

  String get extension => name.split('.').last.toLowerCase();

  bool get isImage {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  bool get isPdf => extension == 'pdf';

  bool get isDocument {
    return ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(extension);
  }

  bool get isCad {
    return ['dwg', 'dxf'].contains(extension);
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get fileIcon {
    switch (extension) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'doc':
      case 'docx':
        return 'description';
      case 'xls':
      case 'xlsx':
        return 'table_chart';
      case 'ppt':
      case 'pptx':
        return 'slideshow';
      case 'dwg':
      case 'dxf':
        return 'architecture';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'image';
      default:
        return 'insert_drive_file';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'thumbnailUrl': thumbnailUrl,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isPinned': isPinned,
      'description': description,
      'messageId': messageId,
      'taskId': taskId,
    };
  }

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      size: json['size'] as int,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      uploadedBy: json['uploadedBy'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      description: json['description'] as String?,
      messageId: json['messageId'] as String?,
      taskId: json['taskId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attachment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// File type categories
class FileType {
  static const String image = 'image';
  static const String document = 'document';
  static const String spreadsheet = 'spreadsheet';
  static const String presentation = 'presentation';
  static const String pdf = 'pdf';
  static const String cad = 'cad';
  static const String other = 'other';

  static String getType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return image;
      case 'doc':
      case 'docx':
      case 'txt':
        return document;
      case 'xls':
      case 'xlsx':
        return spreadsheet;
      case 'ppt':
      case 'pptx':
        return presentation;
      case 'pdf':
        return pdf;
      case 'dwg':
      case 'dxf':
        return cad;
      default:
        return other;
    }
  }

  static const Map<String, String> labels = {
    image: '画像',
    document: '文書',
    spreadsheet: '表計算',
    presentation: 'プレゼン',
    pdf: 'PDF',
    cad: 'CAD図面',
    other: 'その他',
  };

  static String getLabel(String type) {
    return labels[type] ?? type;
  }
}
