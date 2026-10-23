import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safetyreport/navigation/main_tabs.dart';
import 'package:safetyreport/theme/app_theme.dart';
import 'package:safetyreport/widgets/sr_navigation.dart';
import 'package:safetyreport/widgets/sr_surface.dart';
import 'package:safetyreport/services/app_prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('legacy management shares Reports without changing native IDs', () {
    expect(AppDestination.fromLegacy(2), AppDestination.reports);
    expect(AppDestination.values.map((d) => d.legacyTab), [0, 1, 3, 4]);
    int? selected;
    final controller = MainTabController(onSelectTab: (i) => selected = i);
    controller.goTo(2, subTab: 1);
    expect(selected, 2);
    expect(controller.takeSubTab(2), 1);
    expect(controller.takeSubTab(2), isNull);
    controller.goTo(2, subTab: 3);
    controller.goTo(1);
    expect(controller.takeSubTab(2), isNull);
    expect(controller.takeSubTab(1), 0);
    controller.dispose();
  });
  testWidgets('legacy glass preference is retained but never rendered', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({AppPrefsKeys.glassEffects: true});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SrSurface(child: Text('content')),
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        AppPrefsKeys.glassEffects,
      ),
      isTrue,
    );
  });
  for (final scale in [1.0, 1.3, 2.0]) {
    for (final dark in [false, true]) {
      testWidgets('bottom navigation readable at 360 scale $scale dark $dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        AppDestination? selected;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: Scaffold(
                bottomNavigationBar: SrNavigation(
                  destination: AppDestination.home,
                  unread: 123,
                  onSelect: (d) => selected = d,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('활동'));
        expect(selected, AppDestination.activity);
        expect(tester.takeException(), isNull);
        for (final item in find.byType(InkWell).evaluate()) {
          expect(
            tester.getSize(find.byWidget(item.widget)).height,
            greaterThanOrEqualTo(48),
          );
        }
        for (final animation in tester.widgetList<AnimatedContainer>(
          find.byType(AnimatedContainer),
        )) {
          expect(animation.duration, Duration.zero);
        }
      });
    }
  }
  testWidgets('rail scrolls in short landscape at large text', (tester) async {
    tester.view.physicalSize = const Size(800, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AppDestination? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Row(
              children: [
                SrNavigation(
                  destination: AppDestination.home,
                  rail: true,
                  onSelect: (d) => selected = d,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('활동'));
    await tester.tap(find.text('활동'));
    expect(selected, AppDestination.activity);
  });
  for (final highContrast in [false, true]) {
    testWidgets('opaque fallback high contrast $highContrast', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(highContrast: highContrast),
            child: const SrSurface(child: Text('content')),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });
  }
}
