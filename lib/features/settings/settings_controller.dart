import 'models/user_settings_model.dart';
import 'services/settings_service.dart';

class SettingsController {
  final SettingsService _service = SettingsService();

  UserSettings? settings;

  Future<void> loadSettings() async {
    settings = await _service.getSettings();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    settings = newSettings;
    await _service.saveSettings(newSettings);
  }
}