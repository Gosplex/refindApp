class AppUpdateModel {
  final int androidVersion;
  final int iosVersion;
  final bool forceUpdate;
  final String androidNote;
  final String iosNote;

  AppUpdateModel({
    required this.androidVersion,
    required this.iosVersion,
    required this.forceUpdate,
    required this.androidNote,
    required this.iosNote,
  });

  factory AppUpdateModel.fromMap(Map<String, dynamic> map) {
    return AppUpdateModel(
      androidVersion: map['android_version'] ?? 0,
      iosVersion: map['ios_version'] ?? 0,
      forceUpdate: map['force_update'] ?? false,
      androidNote: map['android_update_note'] ?? '',
      iosNote: map['ios_update_note'] ?? '',
    );
  }
}