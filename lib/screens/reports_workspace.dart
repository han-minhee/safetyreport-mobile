import 'package:flutter/material.dart';
import '../navigation/main_tabs.dart';
import '../widgets/sr_surface.dart';
import '../widgets/sr_app_bar_actions.dart';
import 'report_list_screen.dart';
import 'rating_management_panel.dart';
import 'watchlist_screen.dart';
import 'duplicate_management_screen.dart';
import 'data_editor_screen.dart';

class ReportsWorkspace extends StatefulWidget {
  const ReportsWorkspace({super.key});
  @override
  State<ReportsWorkspace> createState() => _ReportsWorkspaceState();
}

class _ReportsWorkspaceState extends State<ReportsWorkspace> {
  bool _management = false;
  MainTabController? _tabs;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabs = MainTabScope.maybeOf(context);
    if (identical(tabs, _tabs)) return;
    _tabs?.removeListener(_request);
    _tabs = tabs;
    _tabs?.addListener(_request);
    _request();
  }

  void _request() {
    final management = _tabs?.takeSubTab(MainTabs.management);
    final history = _tabs?.takeSubTab(MainTabs.reports);
    if (management == null && history == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _management = management != null);
      if (management != null) _openTool(management.clamp(0, 3));
    });
  }

  void _openTool(int index) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ManagementToolScreen(index: index)),
  );
  @override
  void dispose() {
    _tabs?.removeListener(_request);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigation = SrWorkspaceSwitch(
      management: _management,
      textScaler: MediaQuery.textScalerOf(context),
      onChanged: (value) => setState(() => _management = value),
    );
    return IndexedStack(
      index: _management ? 1 : 0,
      children: [
        TickerMode(
          enabled: !_management,
          child: ReportListScreen(workspaceNavigation: navigation),
        ),
        TickerMode(
          enabled: _management,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('신고'),
              actions: const [SettingsActionButton()],
              bottom: navigation,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SrSectionHeader(title: '관리 도구'),
                SrSurface(
                  child: Column(
                    children: [
                      for (
                        var i = 0;
                        i < ManagementToolScreen.labels.length;
                        i++
                      ) ...[
                        if (i > 0)
                          const Divider(height: 1, indent: 56, endIndent: 16),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(ManagementToolScreen.icons[i]),
                          title: Text(ManagementToolScreen.labels[i]),
                          subtitle: Text(ManagementToolScreen.descriptions[i]),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openTool(i),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ManagementToolScreen extends StatelessWidget {
  const ManagementToolScreen({super.key, required this.index});
  final int index;
  static const labels = ['별점', '감시 목록', '중복 신고', '데이터 수정'];
  static const descriptions = [
    '처리 결과 평가',
    '관심 신고의 변경 확인',
    '연결된 신고 확인',
    '저장된 신고 정보 관리',
  ];
  static const icons = [
    Icons.star_outline,
    Icons.visibility_outlined,
    Icons.copy_all_outlined,
    Icons.edit_outlined,
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(labels[index]),
      actions: [
        if (index == 0 || index == 3)
          IconButton(
            tooltip: '검색 및 필터',
            icon: const Icon(Icons.tune),
            onPressed: () => index == 0
                ? openRatingFilterSheet(context)
                : openDataEditorFilterSheet(context),
          ),
        const SettingsActionButton(),
      ],
    ),
    body: const [
      RatingManagementPanel(),
      WatchlistPanel(),
      DuplicateManagementPanel(),
      DataEditorPanel(),
    ][index],
  );
}
