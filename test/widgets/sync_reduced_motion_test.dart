import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:safetyreport/providers/report_provider.dart';
import 'package:safetyreport/widgets/sync_status_card.dart';

class _SyncProvider extends ReportProvider {
  @override
  bool get isSyncing => true;
}

void main() {
  testWidgets('sync icon stops when reduced motion changes during a sync', (
    tester,
  ) async {
    final provider = _SyncProvider();
    addTearDown(provider.dispose);
    Future<void> pump(bool reduced) => tester.pumpWidget(
      ChangeNotifierProvider<ReportProvider>.value(
        value: provider,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const Scaffold(body: SyncActionButton()),
          ),
        ),
      ),
    );
    await pump(false);
    await tester.pump(const Duration(milliseconds: 300));
    final active = tester
        .widget<RotationTransition>(
          find.descendant(
            of: find.byType(SyncActionButton),
            matching: find.byType(RotationTransition),
          ),
        )
        .turns;
    expect(active.value, isNot(0));
    await pump(true);
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester
          .widget<RotationTransition>(
            find.descendant(
              of: find.byType(SyncActionButton),
              matching: find.byType(RotationTransition),
            ),
          )
          .turns
          .value,
      0,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.byTooltip('크롤링'), findsOneWidget);
    await pump(false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<RotationTransition>(
            find.descendant(
              of: find.byType(SyncActionButton),
              matching: find.byType(RotationTransition),
            ),
          )
          .turns
          .value,
      isNot(0),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
