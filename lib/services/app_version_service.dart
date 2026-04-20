import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../features/appUpdate/app_update_model.dart';

class AppVersionService {
  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  PackageInfo? _packageInfo;
  AppUpdateModel? _remoteConfig;

  // -------------------------------
  // INIT
  // -------------------------------
  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    await _fetchRemoteConfig();
  }

  // -------------------------------
  // FIRESTORE FETCH
  // -------------------------------
  Future<void> _fetchRemoteConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("app_config")
          .doc("update_config")
          .get();

      if (doc.exists && doc.data() != null) {
        _remoteConfig = AppUpdateModel.fromMap(doc.data()!);
      }
    } catch (e) {
      print("Update config fetch error: $e");
    }
  }

  // -------------------------------
  // LOCAL VERSION GETTERS
  // -------------------------------
  String get versionName => _packageInfo?.version ?? "0.0.0";

  int get buildNumber =>
      int.tryParse(_packageInfo?.buildNumber ?? "0") ?? 0;

  String get fullVersion =>
      "$versionName+${_packageInfo?.buildNumber ?? "0"}";

  // -------------------------------
  // REMOTE GETTERS
  // -------------------------------
  int get latestVersion {
    if (_remoteConfig == null) return 0;
    return Platform.isAndroid
        ? _remoteConfig!.androidVersion
        : _remoteConfig!.iosVersion;
  }

  String get updateNote {
    if (_remoteConfig == null) return "";
    return Platform.isAndroid
        ? _remoteConfig!.androidNote
        : _remoteConfig!.iosNote;
  }

  bool get isForceUpdate => _remoteConfig?.forceUpdate ?? false;

  // -------------------------------
  // MAIN LOGIC
  // -------------------------------
  bool get isUpdateAvailable {
    return buildNumber < latestVersion;
  }

  AppUpdateModel? get remoteConfig => _remoteConfig;

  // -------------------------------
  // DEBUG (optional)
  // -------------------------------
  void printDebug() {
    print("Local Build: $buildNumber");
    print("Remote Build: $latestVersion");
    print("Force Update: $isForceUpdate");
  }
}