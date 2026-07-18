import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_settings_model.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  DocumentReference get _settingsRef =>
      _firestore.collection('users').doc(userId).collection('meta').doc('settings');

  /// 📥 Get settings
  Future<UserSettings> getSettings() async {
    final doc = await _settingsRef.get();

    if (!doc.exists) {
      final defaultSettings = UserSettings(
        notificationsEnabled: true,
        weekRecapEnabled: false,
        defaultReminder: "2 hours",
        stopAfter: "3 days",
        theme: "System",
        quietStartHour: 22,
        quietStartMinute: 0,
        quietEndHour: 8,
        quietEndMinute: 0,
      );

      await _settingsRef.set(defaultSettings.toMap());
      return defaultSettings;
    }

    return UserSettings.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// 💾 Save settings
  Future<void> saveSettings(UserSettings settings) async {
    await _settingsRef.set(settings.toMap());
  }
}