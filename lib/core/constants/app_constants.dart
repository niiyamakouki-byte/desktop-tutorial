/// Application constants for Construction Project Manager
class AppConstants {
  AppConstants._();

  // ============== App Info ==============
  static const String appName = '建設プロジェクト管理';
  static const String appVersion = '1.0.0';

  // ============== Layout Constants ==============
  static const double sidebarWidth = 380.0;
  static const double sidebarCollapsedWidth = 0.0;
  static const double taskListWidth = 350.0;
  static const double ganttRowHeight = 44.0;
  static const double ganttHeaderHeight = 60.0;
  static const double ganttDayWidth = 40.0;
  static const double taskTreeIndent = 24.0;
  static const double minTaskBarWidth = 8.0;

  // ============== Animation Durations ==============
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 400);
  static const Duration sidebarAnimationDuration = Duration(milliseconds: 300);

  // ============== Padding & Spacing ==============
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 24.0;
  static const double paddingXXL = 32.0;

  // ============== Border Radius ==============
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusRound = 999.0;

  // ============== Icon Sizes ==============
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 20.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXL = 32.0;

  // ============== Avatar Sizes ==============
  static const double avatarSizeS = 24.0;
  static const double avatarSizeM = 32.0;
  static const double avatarSizeL = 40.0;
  static const double avatarSizeXL = 48.0;

  // ============== Chat Constants ==============
  static const int maxMessageLength = 5000;
  static const int messagePreviewLength = 100;
  static const double chatBubbleMaxWidth = 280.0;
  static const double attachmentThumbnailSize = 80.0;
  static const double documentCardHeight = 72.0;

  // ============== File Constants ==============
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> supportedDocFormats = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];
  static const List<String> supportedCadFormats = ['dwg', 'dxf'];

  // ============== Date Formats ==============
  static const String dateFormatFull = 'yyyy年MM月dd日';
  static const String dateFormatShort = 'MM/dd';
  static const String dateFormatMonth = 'yyyy年MM月';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy/MM/dd HH:mm';

  // ============== Task Status ==============
  static const String statusNotStarted = 'not_started';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusDelayed = 'delayed';
  static const String statusOnHold = 'on_hold';

  // ============== Task Priority ==============
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityCritical = 'critical';

  // ============== Message Types ==============
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';
  static const String messageTypeSystem = 'system';

  // ============== Japanese Labels ==============
  static const Map<String, String> statusLabels = {
    statusNotStarted: '未着手',
    statusInProgress: '進行中',
    statusCompleted: '完了',
    statusDelayed: '遅延',
    statusOnHold: '保留',
  };

  static const Map<String, String> priorityLabels = {
    priorityLow: '低',
    priorityMedium: '中',
    priorityHigh: '高',
    priorityCritical: '緊急',
  };

  static const List<String> weekDaysJP = ['日', '月', '火', '水', '木', '金', '土'];
  static const List<String> monthsJP = [
    '1月', '2月', '3月', '4月', '5月', '6月',
    '7月', '8月', '9月', '10月', '11月', '12月'
  ];
}
