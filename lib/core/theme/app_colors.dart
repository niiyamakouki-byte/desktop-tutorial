import 'package:flutter/material.dart';

/// Application color palette for Construction Project Manager
/// Navy Blue based color scheme with industrial accent colors
class AppColors {
  AppColors._();

  // ============== Primary Colors (Navy Blue Theme) ==============
  static const Color primary = Color(0xFF1A365D);        // Deep Navy Blue
  static const Color primaryDark = Color(0xFF0F2342);    // Darker Navy
  static const Color primaryLight = Color(0xFF2C5282);   // Lighter Navy
  static const Color secondary = Color(0xFF2B6CB0);      // Accent Blue
  static const Color accent = Color(0xFF4299E1);         // Bright Blue accent
  static const Color primarySoft = Color(0xFF3182CE);    // Soft primary for highlights

  // ============== Industrial Accent Colors ==============
  static const Color safetyYellow = Color(0xFFEAB308);   // Safety Yellow
  static const Color safetyYellowLight = Color(0xFFFEF9C3);
  static const Color industrialOrange = Color(0xFFF97316); // Industrial Orange
  static const Color industrialOrangeLight = Color(0xFFFFEDD5);
  static const Color constructionRed = Color(0xFFDC2626); // Warning Red
  static const Color constructionGreen = Color(0xFF16A34A); // Go/Safe Green

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

  // ============== Gantt Chart Colors (Modern Material Design 3) ==============
  static const Color ganttBackground = Color(0xFFFCFCFC);
  static const Color ganttGridLine = Color(0xFFE8E8E8);
  static const Color ganttWeekend = Color(0xFFF5F5F5);
  static const Color ganttToday = Color(0xFFF0F7FF);
  static const Color ganttTodayLine = Color(0xFF1976D2);
  static const Color ganttHeaderBg = Color(0xFFFFFFFF);
  static const Color ganttHeaderText = Color(0xFF424242);
  static const Color ganttHeaderSubtext = Color(0xFF9E9E9E);
  static const Color ganttRowHover = Color(0xFFF5F9FF);
  static const Color ganttRowSelected = Color(0xFFE3F2FD);
  static const Color ganttRowAlternate = Color(0xFFFAFAFA);
  static const Color ganttDependencyLine = Color(0xFF757575);
  static const Color ganttDependencyHighlight = Color(0xFF1976D2);
  static const Color ganttMonthDivider = Color(0xFFBDBDBD);

  // ============== Modern Task Bar Colors ==============
  static const Color taskBarBlue = Color(0xFF42A5F5);
  static const Color taskBarGreen = Color(0xFF66BB6A);
  static const Color taskBarOrange = Color(0xFFFFA726);
  static const Color taskBarPurple = Color(0xFFAB47BC);
  static const Color taskBarTeal = Color(0xFF26A69A);
  static const Color taskBarPink = Color(0xFFEC407A);
  static const Color taskBarIndigo = Color(0xFF5C6BC0);

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

  // ============== Chat Colors (Navy Theme) ==============
  static const Color chatBackground = Color(0xFFF7FAFC);
  static const Color chatBubbleSent = Color(0xFF1A365D);
  static const Color chatBubbleReceived = Color(0xFFFFFFFF);
  static const Color chatTextSent = Color(0xFFFFFFFF);
  static const Color chatTextReceived = Color(0xFF1A202C);
  static const Color chatTimestamp = Color(0xFF718096);
  static const Color chatInputBg = Color(0xFFFFFFFF);
  static const Color chatUnread = Color(0xFFE53E3E);
  static const Color chatOnline = Color(0xFF38A169);
  static const Color chatOffline = Color(0xFFA0AEC0);
  static const Color chatReadIndicator = Color(0xFF4299E1);

  // ============== File Types Colors ==============
  static const Color filePdf = Color(0xFFE53935);
  static const Color fileDoc = Color(0xFF1565C0);
  static const Color fileXls = Color(0xFF4CAF50);
  static const Color fileImage = Color(0xFF9C27B0);
  static const Color fileCad = Color(0xFFFF9800);
  static const Color fileOther = Color(0xFF607D8B);

  // ============== Sidebar Colors (Navy Theme) ==============
  static const Color sidebarBackground = Color(0xFFFFFFFF);
  static const Color sidebarHeader = Color(0xFF1A365D);
  static const Color sidebarDivider = Color(0xFFE2E8F0);
  static const Color sidebarDocSection = Color(0xFFF7FAFC);
  static const Color sidebarStockBg = Color(0xFFEDF2F7);
  static const Color sidebarFlowBg = Color(0xFFF7FAFC);

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
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color surfaceDark = Color(0xFF1A1A24);
  static const Color surfaceVariantDark = Color(0xFF252532);
  static const Color textPrimaryDark = Color(0xFFF1F1F3);
  static const Color textSecondaryDark = Color(0xFFA0A0B0);
  static const Color textTertiaryDark = Color(0xFF6A6A7A);
  static const Color secondaryDark = Color(0xFF64B5F6);
  static const Color errorDark = Color(0xFFEF5350);
  static const Color borderDark = Color(0xFF2A2A3A);
  static const Color dividerDark = Color(0xFF1F1F2F);

  // ============== Glassmorphism Colors ==============
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBorderLight = Color(0x4DFFFFFF);
  static const Color glassOverlay = Color(0x0DFFFFFF);
  static const Color glassDark = Color(0x33000000);
  static const Color glassBorderDark = Color(0x1AFFFFFF);

  // ============== Weather Alert Colors ==============
  static const Color weatherSunny = Color(0xFFFBBF24);
  static const Color weatherCloudy = Color(0xFF94A3B8);
  static const Color weatherRainy = Color(0xFF3B82F6);
  static const Color weatherStormy = Color(0xFF6366F1);
  static const Color weatherAlert = Color(0xFFDC2626);
  static const Color concreteAlert = Color(0xFFEF4444);

  // ============== Gradient Definitions (Navy Theme) ==============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2C5282), Color(0xFF1A365D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A365D), Color(0xFF0F2342)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [Color(0xFF1A365D), Color(0xFF2D3748)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [Color(0xFF4299E1), Color(0xFF2B6CB0)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient stockSectionGradient = LinearGradient(
    colors: [Color(0xFFEDF2F7), Color(0xFFF7FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient industrialGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient safetyGradient = LinearGradient(
    colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassMorphGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkModeGradient = LinearGradient(
    colors: [Color(0xFF1A1A24), Color(0xFF0A0A0F)],
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

  /// Get modern task bar color by index (for variety)
  static Color getTaskBarColorByIndex(int index) {
    final colors = [
      taskBarBlue,
      taskBarGreen,
      taskBarOrange,
      taskBarPurple,
      taskBarTeal,
      taskBarPink,
      taskBarIndigo,
    ];
    return colors[index % colors.length];
  }

  /// Get phase color for Gantt chart (建設工程用)
  static Color getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case '基礎':
      case 'foundation':
        return taskBarIndigo;
      case '躯体':
      case 'structure':
        return taskBarBlue;
      case '内装':
      case 'interior':
        return taskBarGreen;
      case '外装':
      case 'exterior':
        return taskBarTeal;
      case '設備':
      case 'equipment':
        return taskBarOrange;
      case '検査':
      case 'inspection':
        return taskBarPink;
      case '土木':
      case 'civil':
        return taskBarPurple;
      default:
        return taskBarBlue;
    }
  }
}
