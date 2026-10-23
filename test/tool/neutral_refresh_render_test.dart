import 'package:safetyreport/screens/settings_screen.dart';
import 'package:safetyreport/screens/setup_screen.dart';
import 'package:safetyreport/screens/statistics_screen.dart';
import 'package:safetyreport/community/gate/community_gate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safetyreport/widgets/sr_navigation.dart';
import 'package:safetyreport/widgets/report_detail_sheet.dart';
import 'package:safetyreport/navigation/main_tabs.dart';
import 'package:safetyreport/screens/reports_workspace.dart';
import 'package:safetyreport/screens/notifications_screen.dart';
import 'package:safetyreport/providers/notification_history_provider.dart';
// Opt-in synthetic Flutter renders; never overwrites approved goldens.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safetyreport/models/app_mode.dart';
import 'package:safetyreport/models/report.dart';
import 'package:safetyreport/providers/report_provider.dart';
import 'package:safetyreport/screens/dashboard_screen.dart';
import 'package:safetyreport/theme/app_theme.dart';
import 'package:safetyreport/widgets/report_list_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixtureProvider extends ReportProvider {
  _FixtureProvider(this.mode);
  final AppMode mode;
  @override
  AppMode get appMode => mode;
  @override
  bool get isLoading => false;
  @override
  Future<({List<Report> reports, int total})> readServerPage(
    String category, {
    int offset = 0,
    int limit = 200,
    bool Function()? isCancelled,
  }) async => (reports: [_report], total: 1);
  @override
  Future<void> fetchCategoryReports(String category) async {}
  @override
  Future<void> ensureCategoryReportsLoaded({bool forceRefresh = false}) async {}
  @override
  Future<void> fetchDuplicateReports() async {}
  @override
  Future<void> fetchSummary() async {}
  @override
  Future<void> refreshSummaryAndRecentAnswers() async {}
  @override
  List<Report> get recentAnswerReports => [_report];
  @override
  DashboardStats get stats => DashboardStats(
    lastCrawlTime: '',
    total: 128,
    acceptCount: 94,
    partialCount: 6,
    rejectCount: 18,
    supplementCount: 3,
    processingCount: 7,
    completedCount: 118,
    withdrawCount: 0,
    withdrawRawCount: 0,
    withdrawGraphCount: 0,
    tFineCount: 62,
    tPenaltyCount: 12,
    tRejectCount: 18,
    tUnconfirmedCount: 0,
    recentAnswers: const [],
    watchlist: [_report],
    watchlistTotal: 1,
  );
}

final _report = Report.fromJson({
  'ID': 'synthetic',
  '신고번호': 'SPP-2610-0000001',
  '신고명': '교차로 신호 위반',
  '처리상태': '수용',
  '신고일': '2026-10-01',
  '답변일': '2026-10-12',
  '처리기관': '예시시 교통안전과',
  '차량번호': '12가3456',
  '위반장소': '예시시 예시구 중앙로 교차로',
  'category': 'traffic',
  '범칙금_과태료': '과태료: 70,000원',
});

void main() {
  final out = Platform.environment['SR_REFRESH_RENDER_OUT'];
  setUpAll(() async {
    if (out == null) return;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'safetyreport',
      packageName: 'fixture',
      version: '1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.fentanest.mysafetyreport/permissions'),
          (_) async => false,
        );

    final font = Platform.environment['SR_RENDER_FONT']!;
    final icons =
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    for (final entry in {'Roboto': font, 'MaterialIcons': icons}.entries) {
      await (FontLoader(entry.key)..addFont(
            Future.value(
              ByteData.sublistView(File(entry.value).readAsBytesSync()),
            ),
          ))
          .load();
    }
    Directory(out).createSync(recursive: true);
  });
  for (final mode in [AppMode.standalone]) {
    for (final brightness in Brightness.values) {
      for (final width in [360.0, 412.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          for (final screen in [
            'dashboard',
            'reports',
            'detail',
            'workspace',
            'activity',
            'management',
            'settings',
            'setup',
            'insights',
          ]) {
            final name =
                '${mode.name}-${brightness.name}-${width.toInt()}-$scale-$screen';
            testWidgets(name, (tester) async {
              tester.view.physicalSize = Size(width, 900);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              final provider = _FixtureProvider(mode);
              addTearDown(provider.dispose);
              const key = ValueKey('capture');
              await tester.pumpWidget(
                MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                      create: (_) => CommunityGate(configStatus: () => 'ok'),
                    ),
                    ChangeNotifierProvider<ReportProvider>.value(
                      value: provider,
                    ),
                    ChangeNotifierProvider(
                      create: (_) => NotificationHistoryProvider(),
                    ),
                  ],
                  child: RepaintBoundary(
                    key: key,
                    child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.build(brightness).copyWith(
                        appBarTheme: AppTheme.build(brightness).appBarTheme
                            .copyWith(
                              titleTextStyle: AppTheme.build(brightness)
                                  .appBarTheme
                                  .titleTextStyle!
                                  .copyWith(fontFamily: 'Roboto'),
                            ),
                      ),
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.linear(scale)),
                        child: child!,
                      ),
                      home: screen == 'settings'
                          ? const SettingsScreen()
                          : screen == 'setup'
                          ? const SetupScreen()
                          : screen == 'insights'
                          ? const StatisticsScreen()
                          : screen == 'detail'
                          ? Scaffold(
                              appBar: AppBar(title: const Text('신고 상세')),
                              body: ReportDetailSheet(
                                report: _report,
                                fullPage: true,
                              ),
                            )
                          : (screen == 'workspace' || screen == 'management')
                          ? Scaffold(
                              body: const ReportsWorkspace(),
                              bottomNavigationBar: SrNavigation(
                                destination: AppDestination.reports,
                                onSelect: (_) {},
                              ),
                            )
                          : screen == 'activity'
                          ? Scaffold(
                              body: const NotificationsScreen(),
                              bottomNavigationBar: SrNavigation(
                                destination: AppDestination.activity,
                                onSelect: (_) {},
                              ),
                            )
                          : screen == 'dashboard'
                          ? Scaffold(
                              body: const DashboardScreen(),
                              bottomNavigationBar: SrNavigation(
                                destination: AppDestination.home,
                                onSelect: (_) {},
                              ),
                            )
                          : Scaffold(
                              appBar: AppBar(title: const Text('신고내역')),
                              body: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  for (var i = 0; i < 3; i++)
                                    ReportListCard(
                                      report: _report,
                                      selectionMode: false,
                                      isSelected: false,
                                      onTap: () {},
                                      onLongPress: () {},
                                      metaItems: [
                                        ReportCardMetaItem(
                                          icon: Icons.calendar_today,
                                          text: _report.date,
                                        ),
                                        ReportCardMetaItem(
                                          icon: Icons.business,
                                          text: _report.agency,
                                        ),
                                        ReportCardMetaItem.fine(_report),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              );
              // Statistics loads native SQLite asynchronously. This capture covers
              // its loading/error shell; populated chart semantics have separate tests.
              if (screen == 'insights') {
                await tester.pump(const Duration(milliseconds: 300));
              } else {
                await tester.pumpAndSettle();
              }
              if (screen == 'management') {
                await tester.tap(find.text('관리').first);
                await tester.pumpAndSettle();
              }
              expect(tester.takeException(), isNull);
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(key),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 1);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                File(
                  '$out/$name.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }, skip: out == null);
          }
        }
      }
    }
  }
}
