import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../saved_posts/models/saved_post_model.dart';
import '../settings/settings_controller.dart';

class ReminderService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final SettingsController _settingsController = SettingsController();

  static const String _baseUrl = "https://us-central1-myrefindapp.cloudfunctions.net";
  static const String _scheduleReminderEndpoint = "$_baseUrl/scheduleReminder";
  static const String _cancelRemindersEndpoint = "$_baseUrl/cancelReminders";

  /// Schedule reminders for a saved post
  static Future<bool> scheduleReminder(SavedPost post) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }

      // Load user settings to check if notifications are enabled
      await _settingsController.loadSettings();
      final settings = _settingsController.settings;

      if (settings != null && !settings.notificationsEnabled) {
        debugPrint("📵 Notifications disabled, skipping reminder schedule");
        return false;
      }

      final requestBody = {
        'userId': userId,
        'postId': post.id,
        'postTitle': post.title,
        'postDescription': post.description ?? '',
        'postDomain': post.domain ?? '',
        'createdAt': post.createdAt.toIso8601String(),
      };

      debugPrint("📤 Scheduling reminder for post: ${post.title}");
      debugPrint("📤 Request body: $requestBody");

      final response = await http.post(
        Uri.parse(_scheduleReminderEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint("⏰ Timeout scheduling reminder");
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("✅ Reminder scheduled successfully: ${data['message']}");
        return true;
      } else {
        debugPrint("❌ Failed to schedule reminder: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error scheduling reminder: $e");
      return false;
    }
  }

  /// Cancel all reminders for a post
  static Future<bool> cancelReminders(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint("❌ No user logged in, cannot cancel reminders");
        return false;
      }

      final requestBody = {
        'userId': userId,
        'postId': postId,
      };

      debugPrint("📤 Cancelling reminders for post: $postId");

      final response = await http.post(
        Uri.parse(_cancelRemindersEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint("⏰ Timeout cancelling reminders");
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("✅ Reminders cancelled successfully: ${data['message']}");
        return true;
      } else {
        debugPrint("❌ Failed to cancel reminders: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error cancelling reminders: $e");
      return false;
    }
  }

  /// Cancel all reminders for multiple posts (batch)
  static Future<Map<String, bool>> cancelMultipleReminders(List<String> postIds) async {
    final results = <String, bool>{};

    for (final postId in postIds) {
      final success = await cancelReminders(postId);
      results[postId] = success;
      // Add a small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }

  /// Reschedule reminders for a post (useful when settings change)
  static Future<bool> rescheduleReminder(SavedPost post) async {
    // First cancel existing reminders
    final cancelled = await cancelReminders(post.id);
    if (!cancelled) {
      debugPrint("⚠️ Could not cancel existing reminders for rescheduling");
    }

    // Then schedule new ones
    return await scheduleReminder(post);
  }
}

// Extension methods for easier use
extension ReminderServiceExtension on SavedPost {
  Future<bool> scheduleReminders() => ReminderService.scheduleReminder(this);
  Future<bool> cancelReminders() => ReminderService.cancelReminders(id);
  Future<bool> rescheduleReminders() => ReminderService.rescheduleReminder(this);
}