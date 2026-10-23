import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safetyreport/models/app_mode.dart';
import 'package:safetyreport/providers/report_provider.dart';
import 'package:safetyreport/services/app_prefs_keys.dart';
import 'package:safetyreport/services/standalone_installation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'Client upgrade preserves recovery data but requires fresh direct login',
    () async {
      SharedPreferences.setMockInitialValues({
        AppPrefsKeys.appMode: 'server',
        AppPrefsKeys.baseUrl: 'https://fixture.invalid',
        AppPrefsKeys.apiKey: 'synthetic',
        AppPrefsKeys.standaloneUsername: 'old-account',
        AppPrefsKeys.standalonePhoneNumber: '01000000000',
        AppPrefsKeys.pendingDbImport: 'copy:/synthetic/backup.db',
        'native_config_generation': 3,
        'community_gate_cache_v1': 'preserved',
      });
      final provider = ReportProvider.standaloneOnly();
      await provider.init();
      expect(provider.appMode, AppMode.standalone);
      expect(provider.isConfigured, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppPrefsKeys.baseUrl), 'https://fixture.invalid');
      expect(prefs.getString(AppPrefsKeys.apiKey), 'synthetic');
      expect(
        prefs.getString('legacy_client_standaloneUsername'),
        'old-account',
      );
      expect(
        prefs.getString(AppPrefsKeys.pendingDbImport),
        'copy:/synthetic/backup.db',
      );
      expect(prefs.getString('community_gate_cache_v1'), 'preserved');
      expect(prefs.getInt('native_config_generation'), 4);
      await StandaloneInstallation.prepare(prefs);
      expect(prefs.getInt('native_config_generation'), 4);
      expect(
        () => provider.setConfig('https://fixture.invalid', 'key'),
        throwsUnsupportedError,
      );
      provider.dispose();
    },
  );
  test('existing direct account and demo settings remain intact', () async {
    SharedPreferences.setMockInitialValues({
      AppPrefsKeys.appMode: 'standalone',
      AppPrefsKeys.standaloneUsername: 'fixture',
      AppPrefsKeys.standaloneDemoMode: true,
    });
    final provider = ReportProvider.standaloneOnly();
    await provider.init();
    expect(provider.standaloneUsername, 'fixture');
    expect(provider.isStandaloneDemo, true);
    provider.dispose();
  });
  test('new install and reset both stay standalone', () async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fentanest.mysafetyreport/permissions'),
          (_) async => true,
        );
    final provider = ReportProvider.standaloneOnly();
    await provider.init();
    expect(provider.appMode, AppMode.standalone);
    expect(provider.isConfigured, false);
    await provider.resetConfig();
    expect(provider.appMode, AppMode.standalone);
    expect(provider.isConfigured, false);
    provider.dispose();
  });
}
