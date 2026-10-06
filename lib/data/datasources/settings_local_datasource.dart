// Persists the timer feature flags across launches.
//
// The web build cannot rely on SharedPreferences (the app stores all of its
// data through `dart:html` localStorage — see local_database_browser.dart), so
// settings persistence follows the same platform-conditional pattern as
// [LocalDatabase]: localStorage on web, SharedPreferences on native.
export 'timer_settings_data.dart';

export 'settings_local_datasource_stub.dart'
    if (dart.library.html) 'settings_local_datasource_web.dart'
    if (dart.library.io) 'settings_local_datasource_io.dart';
