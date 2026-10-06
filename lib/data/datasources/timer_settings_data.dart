/// Snapshot of the user's timer preferences persisted between launches.
///
/// These flags used to live only in `TimerState` in memory, so every restart
/// (and every browser reload on the web build) reset them to defaults. This
/// value object is what gets read from / written to persistent storage.
class TimerSettingsData {
  final bool inspectionEnabled;
  final bool hideTimerEnabled;
  final bool competeMode;
  final bool tapToStartEnabled;

  const TimerSettingsData({
    required this.inspectionEnabled,
    required this.hideTimerEnabled,
    required this.competeMode,
    required this.tapToStartEnabled,
  });

  static const TimerSettingsData defaults = TimerSettingsData(
    inspectionEnabled: false,
    hideTimerEnabled: false,
    competeMode: false,
    tapToStartEnabled: false,
  );
}
