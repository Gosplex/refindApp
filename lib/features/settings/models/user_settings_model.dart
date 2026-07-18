class UserSettings {
  final bool notificationsEnabled;
  final String defaultReminder;
  final String stopAfter;
  final String theme;

  final bool weekRecapEnabled;

  final int quietStartHour;
  final int quietStartMinute;
  final int quietEndHour;
  final int quietEndMinute;

  UserSettings({
    required this.notificationsEnabled,
    required this.weekRecapEnabled,
    required this.defaultReminder,
    required this.stopAfter,
    required this.theme,
    required this.quietStartHour,
    required this.quietStartMinute,
    required this.quietEndHour,
    required this.quietEndMinute,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'weekRecapEnabled': weekRecapEnabled,
      'defaultReminder': defaultReminder,
      'stopAfter': stopAfter,
      'theme': theme,
      'quietStartHour': quietStartHour,
      'quietStartMinute': quietStartMinute,
      'quietEndHour': quietEndHour,
      'quietEndMinute': quietEndMinute,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      weekRecapEnabled: map['weekRecapEnabled'] ?? false,
      defaultReminder: map['defaultReminder'] ?? "2 hours",
      stopAfter: map['stopAfter'] ?? "3 days",
      theme: map['theme'] ?? "System",
      quietStartHour: map['quietStartHour'] ?? 22,
      quietStartMinute: map['quietStartMinute'] ?? 0,
      quietEndHour: map['quietEndHour'] ?? 8,
      quietEndMinute: map['quietEndMinute'] ?? 0,
    );
  }
}