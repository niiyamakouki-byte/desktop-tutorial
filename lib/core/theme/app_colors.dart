import 'package:flutter/material.dart';

/// Application color palette for Construction Project Manager
/// Blue/Navy based color scheme for professional construction management
class AppColors {
  AppColors._();

  // ============== Primary Colors ==============
  static const Color primary = Color(0xFF1565C0);        // Primary blue
  static const Color primaryDark = Color(0xFF0D47A1);    // Darker blue
  static const Color primaryLight = Color(0xFF42A5F5);   // Lighter blue
  static const Color secondary = Color(0xFF0277BD);      // Accent blue
  static const Color accent = Color(0xFF00B8D4);         // Cyan accent

  // ============== Background Colors ==============
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F8);
  static const Color inputBackground = Color(0xFFF8FAFC);

  // ============== Text Colors ==============
  static const Color textPrimary = Color(0xFF1A2138);
  static const Color textSecondary = Color(0xFF5E6782);
  static const Color textTertiary = Color(0xFF8F9BB3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF1565C0);

  // ============== Border & Divider Colors ==============
  static const Color border = Color(0xFFE4E9F2);
  static const Color borderFocused = Color(0xFF1565C0);
  static const Color divider = Color(0xFFEDF1F7);

  // ============== Status Colors ==============
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFB300);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ============== Gantt Chart Colors ==============
  static const Color ganttBackground = Color(0xFFFFFFFF);
  static const Color ganttGridLine = Color(0xFFE8ECF1);
  static const Color ganttWeekend = Color(0xFFF5F7FA);
  static const Color ganttToday = Color(0xFFE3F2FD);
  static const Color ganttTodayLine = Color(0xFF1565C0);
  static const Color ganttHeaderBg = Color(0xFF1A2A4A);
  static const Color ganttHeaderText = Color(0xFFFFFFFF);
  static const Color ganttRowHover = Color(0xFFF0F7FF);
  static const Color ganttRowSelected = Color(0xFFE3EFFD);

  // ============== Task Status Colors ==============
  static const Color taskNotStarted = Color(0xFF9E9E9E);
  static const Color taskInProgress = Color(0xFF2196F3);
  static const Color taskCompleted = Color(0xFF4CAF50);
  static const Color taskDelayed = Color(0xFFFF5722);
  static const Color taskOnHold = Color(0xFFFF9800);

  // ============== Task Priority Colors ==============
  static const Color priorityLow = Color(0xFF8BC34A);
  static const Color priorityMedium = Color(0xFFFFC107);
  static const Color priorityHigh = Color(0xFFFF9800);
  static const Color priorityCritical = Color(0xFFF44336);

  // ============== Task Category Colors ==============
  static const Color categoryFoundation = Color(0xFF5C6BC0);
  static const Color categoryStructure = Color(0xFF26A69A);
  static const Color categoryElectrical = Color(0xFFFFCA28);
  static const Color categoryPlumbing = Color(0xFF42A5F5);
  static const Color categoryFinishing = Color(0xFFAB47BC);
  static const Color categoryInspection = Color(0xFFEF5350);
  static const Color categoryGeneral = Color(0xFF78909C);

  // ============== Chat Colors ==============
  static const Color chatBackground = Color(0xFFF8FAFC);
  static const Color chatBubbleSent = Color(0xFF1565C0);
  static const Color chatBubbleReceived = Color(0xFFFFFFFF);
  static const Color chatTextSent = Color(0xFFFFFFFF);
  static const Color chatTextReceived = Color(0xFF1A2138);
  static const Color chatTimestamp = Color(0xFF8F9BB3);
  static const Color chatInputBg = Color(0xFFFFFFFF);
  static const Color chatUnread = Color(0xFFE53935);
  static const Color chatOnline = Color(0xFF4CAF50);
  static const Color chatOffline = Color(0xFF9E9E9E);

  // ============== File Types Colors ==============
  static const Color filePdf = Color(0xFFE53935);
  static const Color fileDoc = Color(0xFF1565C0);
  static const Color fileXls = Color(0xFF4CAF50);
  static const Color fileImage = Color(0xFF9C27B0);
  static const Color fileCad = Color(0xFFFF9800);
  static const Color fileOther = Color(0xFF607D8B);

  // ============== Sidebar Colors ==============
  static const Color sidebarBackground = Color(0xFFFFFFFF);
  static const Color sidebarHeader = Color(0xFF1A2A4A);
  static const Color sidebarDivider = Color(0xFFE4E9F2);
  static const Color sidebarDocSection = Color(0xFFF5F7FA);

  // ============== Shadow Colors ==============
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x33000000);

  // ============== Component Colors ==============
  static const Color chipBackground = Color(0xFFE8EEF4);
  static const Color tooltipBackground = Color(0xFF37474F);
  static const Color snackbarBackground = Color(0xFF323232);
  static const Color iconDefault = Color(0xFF5E6782);
  static const Color iconActive = Color(0xFF1565C0);

  // ============== Dark Mode Colors ==============
  static const Color primaryDarkMode = Color(0xFF64B5F6);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE1E1E1);
  static const Color secondaryDark = Color(0xFF64B5F6);
  static const Color errorDark = Color(0xFFEF5350);

  // ============== Gradient Definitions ==============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A2A4A), Color(0xFF0D1B2A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF1A2A4A), Color(0xFF152238)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============== Helper Methods ==============
  static Color getTaskStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'not_started':
        return taskNotStarted;
      case 'in_progress':
        return taskInProgress;
      case 'completed':
        return taskCompleted;
      case 'delayed':
        return taskDelayed;
      case 'on_hold':
        return taskOnHold;
      default:
        return taskNotStarted;
    }
  }

  static Color getTaskPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return priorityLow;
      case 'medium':
        return priorityMedium;
      case 'high':
        return priorityHigh;
      case 'critical':
        return priorityCritical;
      default:
        return priorityMedium;
    }
  }

  static Color getFileTypeColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return filePdf;
      case 'doc':
      case 'docx':
        return fileDoc;
      case 'xls':
      case 'xlsx':
        return fileXls;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return fileImage;
      case 'dwg':
      case 'dxf':
        return fileCad;
      default:
        return fileOther;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'foundation':
        return categoryFoundation;
      case 'structure':
        return categoryStructure;
      case 'electrical':
        return categoryElectrical;
      case 'plumbing':
        return categoryPlumbing;
      case 'finishing':
        return categoryFinishing;
      case 'inspection':
        return categoryInspection;
      default:
        return categoryGeneral;
    }
  }
}
