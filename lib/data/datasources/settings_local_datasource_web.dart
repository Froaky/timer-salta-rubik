// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'timer_settings_data.dart';

/// Web implementation backed by `window.localStorage`, matching how the app
/// already persists sessions and solves on web (local_database_browser.dart).
class SettingsLocalDataSource {
  SettingsLocalDataSource({Map<String, String>? storage})
      : _storageOverride = storage;

  static const _inspectionKey = 'salta_rubik.settings.inspection_enabled';
  static const _hideTimerKey = 'salta_rubik.settings.hide_timer_enabled';
  static const _competeModeKey = 'salta_rubik.settings.compete_mode';
  static const _tapToStartKey = 'salta_rubik.settings.tap_to_start_enabled';

  final Map<String, String>? _storageOverride;

  Map<String, String> get _storage =>
      _storageOverride ?? html.window.localStorage;

  Future<TimerSettingsData> loadSettings() async {
    return TimerSettingsData(
      inspectionEnabled: _readBool(_inspectionKey),
      hideTimerEnabled: _readBool(_hideTimerKey),
      competeMode: _readBool(_competeModeKey),
      tapToStartEnabled: _readBool(_tapToStartKey),
    );
  }

  Future<void> saveSettings(TimerSettingsData settings) async {
    _storage[_inspectionKey] = settings.inspectionEnabled.toString();
    _storage[_hideTimerKey] = settings.hideTimerEnabled.toString();
    _storage[_competeModeKey] = settings.competeMode.toString();
    _storage[_tapToStartKey] = settings.tapToStartEnabled.toString();
  }

  bool _readBool(String key) => _storage[key] == 'true';
}
