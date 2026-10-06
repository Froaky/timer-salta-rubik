import 'package:shared_preferences/shared_preferences.dart';

import 'timer_settings_data.dart';

/// Native (Android/desktop) implementation backed by [SharedPreferences].
class SettingsLocalDataSource {
  static const _inspectionKey = 'salta_rubik.settings.inspection_enabled';
  static const _hideTimerKey = 'salta_rubik.settings.hide_timer_enabled';
  static const _competeModeKey = 'salta_rubik.settings.compete_mode';
  static const _tapToStartKey = 'salta_rubik.settings.tap_to_start_enabled';

  Future<TimerSettingsData> loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    return TimerSettingsData(
      inspectionEnabled: preferences.getBool(_inspectionKey) ?? false,
      hideTimerEnabled: preferences.getBool(_hideTimerKey) ?? false,
      competeMode: preferences.getBool(_competeModeKey) ?? false,
      tapToStartEnabled: preferences.getBool(_tapToStartKey) ?? false,
    );
  }

  Future<void> saveSettings(TimerSettingsData settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_inspectionKey, settings.inspectionEnabled);
    await preferences.setBool(_hideTimerKey, settings.hideTimerEnabled);
    await preferences.setBool(_competeModeKey, settings.competeMode);
    await preferences.setBool(_tapToStartKey, settings.tapToStartEnabled);
  }
}
