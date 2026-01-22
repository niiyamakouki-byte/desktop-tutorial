import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Weather condition types
enum WeatherCondition {
  sunny,
  partlyCloudy,
  cloudy,
  rainy,
  heavyRain,
  stormy,
  snow,
}

/// Weather data for a specific date
class WeatherData {
  final DateTime date;
  final WeatherCondition condition;
  final double temperature;
  final int precipitationProbability;
  final double windSpeed;
  final bool isConcretePouring;
  final bool hasWeatherAlert;

  const WeatherData({
    required this.date,
    required this.condition,
    required this.temperature,
    required this.precipitationProbability,
    this.windSpeed = 0,
    this.isConcretePouring = false,
    this.hasWeatherAlert = false,
  });

  /// Check if weather is suitable for outdoor work
  bool get isSuitableForOutdoorWork {
    return condition != WeatherCondition.heavyRain &&
        condition != WeatherCondition.stormy &&
        precipitationProbability < 70;
  }

  /// Check if concrete pouring should be postponed
  bool get shouldPostponeConcrete {
    return isConcretePouring &&
        (condition == WeatherCondition.rainy ||
            condition == WeatherCondition.heavyRain ||
            condition == WeatherCondition.stormy ||
            precipitationProbability > 50);
  }

  /// Get icon for weather condition
  IconData get icon {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.partlyCloudy:
        return Icons.cloud_queue_rounded;
      case WeatherCondition.cloudy:
        return Icons.cloud_rounded;
      case WeatherCondition.rainy:
        return Icons.water_drop_rounded;
      case WeatherCondition.heavyRain:
        return Icons.thunderstorm_rounded;
      case WeatherCondition.stormy:
        return Icons.bolt_rounded;
      case WeatherCondition.snow:
        return Icons.ac_unit_rounded;
    }
  }

  /// Get color for weather condition
  Color get color {
    switch (condition) {
      case WeatherCondition.sunny:
        return AppColors.weatherSunny;
      case WeatherCondition.partlyCloudy:
        return AppColors.weatherCloudy;
      case WeatherCondition.cloudy:
        return AppColors.weatherCloudy;
      case WeatherCondition.rainy:
        return AppColors.weatherRainy;
      case WeatherCondition.heavyRain:
        return AppColors.weatherStormy;
      case WeatherCondition.stormy:
        return AppColors.weatherAlert;
      case WeatherCondition.snow:
        return AppColors.weatherRainy;
    }
  }

  /// Get Japanese label for weather condition
  String get label {
    switch (condition) {
      case WeatherCondition.sunny:
        return '晴れ';
      case WeatherCondition.partlyCloudy:
        return '曇り時々晴れ';
      case WeatherCondition.cloudy:
        return '曇り';
      case WeatherCondition.rainy:
        return '雨';
      case WeatherCondition.heavyRain:
        return '大雨';
      case WeatherCondition.stormy:
        return '暴風雨';
      case WeatherCondition.snow:
        return '雪';
    }
  }
}

/// Weather service for fetching and managing weather data
class WeatherService {
  // Mock weather data for demo purposes
  static Map<DateTime, WeatherData> _mockWeatherData = {};

  /// Initialize mock weather data for the next 14 days
  static void initializeMockData() {
    final now = DateTime.now();
    final conditions = [
      WeatherCondition.sunny,
      WeatherCondition.sunny,
      WeatherCondition.partlyCloudy,
      WeatherCondition.cloudy,
      WeatherCondition.rainy,
      WeatherCondition.partlyCloudy,
      WeatherCondition.sunny,
      WeatherCondition.sunny,
      WeatherCondition.cloudy,
      WeatherCondition.heavyRain,
      WeatherCondition.rainy,
      WeatherCondition.partlyCloudy,
      WeatherCondition.sunny,
      WeatherCondition.sunny,
    ];

    final precipitations = [0, 10, 20, 40, 80, 30, 5, 0, 35, 90, 70, 25, 10, 5];

    for (var i = 0; i < 14; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      _mockWeatherData[date] = WeatherData(
        date: date,
        condition: conditions[i],
        temperature: 15 + (i % 7) * 2,
        precipitationProbability: precipitations[i],
        windSpeed: (i % 5) * 3.0,
        // Mark some days as concrete pouring days for demo
        isConcretePouring: i == 4 || i == 9,
        hasWeatherAlert: conditions[i] == WeatherCondition.heavyRain ||
            conditions[i] == WeatherCondition.stormy,
      );
    }
  }

  /// Get weather data for a specific date
  static WeatherData? getWeatherForDate(DateTime date) {
    if (_mockWeatherData.isEmpty) {
      initializeMockData();
    }
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _mockWeatherData[normalizedDate];
  }

  /// Get weather data for a date range
  static List<WeatherData> getWeatherForDateRange(
      DateTime start, DateTime end) {
    if (_mockWeatherData.isEmpty) {
      initializeMockData();
    }

    final result = <WeatherData>[];
    var currentDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!currentDate.isAfter(endDate)) {
      final weather = _mockWeatherData[currentDate];
      if (weather != null) {
        result.add(weather);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return result;
  }

  /// Get alerts for a date range
  static List<WeatherAlert> getAlertsForDateRange(DateTime start, DateTime end) {
    final weatherData = getWeatherForDateRange(start, end);
    final alerts = <WeatherAlert>[];

    for (final weather in weatherData) {
      if (weather.shouldPostponeConcrete) {
        alerts.add(WeatherAlert(
          date: weather.date,
          type: WeatherAlertType.concreteWarning,
          title: 'コンクリート打設注意',
          message:
              '${weather.date.month}/${weather.date.day}は${weather.label}予報です。打設日程の変更を推奨します。',
          severity: AlertSeverity.high,
        ));
      } else if (weather.hasWeatherAlert) {
        alerts.add(WeatherAlert(
          date: weather.date,
          type: WeatherAlertType.weatherWarning,
          title: '悪天候警報',
          message:
              '${weather.date.month}/${weather.date.day}は${weather.label}予報です。屋外作業に注意してください。',
          severity: AlertSeverity.medium,
        ));
      }
    }

    return alerts;
  }

  /// Mark a task date as concrete pouring day
  static void markConcreteDay(DateTime date, bool isConcreteDay) {
    if (_mockWeatherData.isEmpty) {
      initializeMockData();
    }
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final existing = _mockWeatherData[normalizedDate];
    if (existing != null) {
      _mockWeatherData[normalizedDate] = WeatherData(
        date: existing.date,
        condition: existing.condition,
        temperature: existing.temperature,
        precipitationProbability: existing.precipitationProbability,
        windSpeed: existing.windSpeed,
        isConcretePouring: isConcreteDay,
        hasWeatherAlert: existing.hasWeatherAlert,
      );
    }
  }
}

/// Weather alert data
class WeatherAlert {
  final DateTime date;
  final WeatherAlertType type;
  final String title;
  final String message;
  final AlertSeverity severity;

  const WeatherAlert({
    required this.date,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
  });
}

enum WeatherAlertType {
  weatherWarning,
  concreteWarning,
  windWarning,
  temperatureWarning,
}

enum AlertSeverity { low, medium, high, critical }
