import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OneSignalService {
  static const String appId = "1abc9286-16b4-4392-96e4-ecf963aa89ea";
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize OneSignal
      await OneSignal.initialize(appId);

      // Request permission
      bool hasPermission = await OneSignal.Notifications.requestPermission(true);

      if (hasPermission) {
        print("✅ Notification permission granted");
      } else {
        print("⚠️ Notification permission not granted");
      }

      // Listen to auth changes instead of checking once
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          await OneSignal.login(user.uid);
          print("✅ OneSignal logged in for user: ${user.uid}");
        } else {
          // Optional: logout from OneSignal when user signs out
          await OneSignal.logout();
          print("⚠️ User logged out from OneSignal");
        }
      });

      _initialized = true;

    } catch (e) {
      print("❌ OneSignal initialization error: $e");
    }
  }

  static Future<bool> checkPermission() async {
    return await OneSignal.Notifications.requestPermission(false);
  }
}