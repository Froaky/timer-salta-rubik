import 'timer_settings_data.dart';

/// Fallback used when neither `dart:html` nor `dart:io` is available. Keeps the
/// settings in memory for the current session so the app still behaves, without
/// throwing on unsupported platforms.
class SettingsLocalDataSource {
  TimerSettingsData _settings = TimerSettingsData.defaults;

  Future<TimerSettingsData> loadSettings() async => _settings;

  Future<void> saveSettings(TimerSettingsData settings) async {
    _settings = settings;
  }
}
