import 'package:shared_preferences/shared_preferences.dart';
import 'app_prefs_keys.dart';

/// Migrate presentation/configuration only. Never opens or replaces a database.
abstract final class StandaloneInstallation {
  static Future<void> prepare(SharedPreferences prefs) async {
    final previous = prefs.getString(AppPrefsKeys.appMode);
    if (previous == 'server') {
      // A previous direct-login account must not silently become active again.
      for (final key in [
        AppPrefsKeys.standaloneUsername,
        AppPrefsKeys.standalonePhoneNumber,
      ]) {
        final value = prefs.getString(key);
        if (value != null) await prefs.setString('legacy_client_$key', value);
        await prefs.remove(key);
      }
      await prefs.remove(AppPrefsKeys.standaloneDemoMode);
      await prefs.setInt(
        'native_config_generation',
        (prefs.getInt('native_config_generation') ?? 0) + 1,
      );
    }
    // Keep legacy URL/key and pending imports for recovery; do not contact them.
    await prefs.setString(AppPrefsKeys.appMode, 'standalone');
  }
}
