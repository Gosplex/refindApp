import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<Map<String, String>> getDeviceInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final deviceInfo = DeviceInfoPlugin();

  String deviceType = 'unknown';
  String platform = 'unknown';

  if (kIsWeb) {
    deviceType = 'web';
    platform = 'web';
  } else if (Platform.isAndroid) {
    final android = await deviceInfo.androidInfo;
    deviceType = 'android';
    platform = 'Android ${android.version.release}';
  } else if (Platform.isIOS) {
    final ios = await deviceInfo.iosInfo;
    deviceType = 'ios';
    platform = 'iOS ${ios.systemVersion}';
  }

  return {
    'appVersion': "${packageInfo.version}+${packageInfo.buildNumber}",
    'deviceType': deviceType,
    'platform': platform,
  };
}