import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Lightweight device/app metadata for the user document.
///
/// Uses dart:io's [Platform] rather than device_info_plus — the extra plugin
/// pulled a win32 6 transitive dependency that conflicted with the rest of the
/// tree (and failed to compile on the latest Xcode SDK), and we only need
/// coarse OS info here, not detailed hardware data.
Future<Map<String, String>> getDeviceInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();

  String deviceType = 'unknown';
  String platform = 'unknown';

  if (kIsWeb) {
    deviceType = 'web';
    platform = 'web';
  } else if (Platform.isAndroid) {
    deviceType = 'android';
    platform = 'Android ${Platform.operatingSystemVersion}';
  } else if (Platform.isIOS) {
    deviceType = 'ios';
    platform = 'iOS ${Platform.operatingSystemVersion}';
  } else {
    deviceType = Platform.operatingSystem;
    platform = Platform.operatingSystemVersion;
  }

  return {
    'appVersion': "${packageInfo.version}+${packageInfo.buildNumber}",
    'deviceType': deviceType,
    'platform': platform,
  };
}
