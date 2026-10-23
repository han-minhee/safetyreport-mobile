import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/report_provider.dart';
import '../models/app_mode.dart';
import '../services/app_prefs_keys.dart';
import '../services/local_db_service.dart';
import '../widgets/official_account_reset_dialog.dart';
import '../services/pending_db_import_action.dart';
import '../services/standalone_auth_service.dart';
import '../theme/sr_colors.dart';
import '../widgets/sr_snack_bar.dart';
import '../theme/sr_tokens.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    this.initialMode,
    this.onModeSelected,
    this.initialNotice,
    this.accountRecovery = false,
  });

  final String? initialNotice;
  final bool accountRecovery;
  final AppMode? initialMode;
  final ValueChanged<AppMode>? onModeSelected;

  /// 테스트에서 실제 안전신문고 로그인 대신 쓰는 함수. null 이면 [StandaloneAuthService.login].
  @visibleForTesting
  static Future<void> Function(String username, String password)?
  standaloneLoginOverride;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialNotice;
  }

  @override
  void didUpdateWidget(covariant SetupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accountRecovery &&
        oldWidget.initialNotice != widget.initialNotice) {
      _errorMessage = widget.initialNotice;
    }
  }

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePw = true;
  bool _loading = false;

  /// 로그인 뒤 대기 DB 가져오기 중(버튼 문구용).
  bool _importing = false;
  String? _errorMessage;

  bool _isPlayReviewDemoLogin(
    String username,
    String password,
    String rawPhone,
  ) {
    return LocalDbService.isPlayReviewDemoLogin(
      username: username,
      password: password,
      rawPhone: rawPhone,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _enterDemo() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await LocalDbService.seedPlayReviewDemo();
      if (!mounted) return;
      final provider = context.read<ReportProvider>();
      await provider.setStandaloneConfig(
        LocalDbService.playReviewDemoUsername,
        phoneNumber: LocalDbService.playReviewDemoPhone,
        isDemoMode: true,
      );
      await provider.refreshAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppPrefsKeys.pendingDbImport);
      _finishSetup();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '데모 데이터 준비 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _finishSetup() {
    if (!mounted) return;
    // 모드 전환에서는 설정 화면 위에 SetupScreen이 push된다. 루트 흐름으로 돌아간다.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.popUntil((route) => route.isFirst);
  }

  Future<void> _loginStandalone() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final rawPhone = _phoneController.text.trim();
    final phoneNumber = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (_isPlayReviewDemoLogin(username, password, rawPhone)) {
      await _enterDemo();
      return;
    }
    // 새 설치에서도 심사용 demo/demo 입력은 카카오 없이 판별한다.
    // 실제 로그인·DB 가져오기는 기존 게이트와 권한 안내를 통과한 뒤 실행한다.
    if (widget.onModeSelected != null) {
      widget.onModeSelected!(AppMode.standalone);
      return;
    }
    if (username.isEmpty || password.isEmpty || phoneNumber.isEmpty) {
      setState(() => _errorMessage = '아이디·비밀번호·휴대폰번호를 입력해 주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final loginOverride = SetupScreen.standaloneLoginOverride;
      if (loginOverride != null) {
        await loginOverride(username, password);
      } else {
        await StandaloneAuthService.login(username, password);
      }
      if (!mounted) return;
      final provider = context.read<ReportProvider>();
      final messenger = ScaffoldMessenger.of(context);
      // 모드 전환 시 settings_screen 이 저장한 pending_db_import 를 Standalone 모드를 켜기 **전에** 적용한다
      // (Client → Standalone 의 '서버 DB 변환' 또는 '백업 파일 사용' 선택 결과, SQ-B03).
      // setStandaloneConfig 가 먼저면 루트가 곧바로 게이트 통과 흐름(drain·자동 동기화·초기화 판정)을 시작해
      // 빈 DB 에 먼저 쓰거나 가져오기를 "작업 중"으로 거절시킬 수 있다. 모드가 꺼진 동안에는 그런 작업이 없다.
      if (await PendingDbImportAction.read() != null) {
        await provider.prepareStandaloneAccount(
          username,
          confirmAccountReset: () => confirmOfficialAccountReset(context),
        );
      }
      final imported = await _applyPendingDbImport();
      if (imported.status == PendingDbImportStatus.kept) {
        // 결정을 받지 못했다(화면이 닫힘 등). 대기 작업을 남기고 모드도 켜지 않는다 — 다음 로그인에서 다시 시도.
        if (mounted) {
          setState(() => _errorMessage = 'DB 가져오기 실패. 로그인하면 다시 시도합니다.');
        }
        return;
      }
      await provider.setStandaloneConfig(
        username,
        phoneNumber: phoneNumber,
        confirmAccountReset: () => confirmOfficialAccountReset(context),
      );
      _showImportOutcome(messenger, imported);
      if (imported.status == PendingDbImportStatus.applied) {
        unawaited(provider.refreshAll());
      }
      // 설정 저장 후 루트가 다음 화면을 선택한다.
      _finishSetup();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _importing = false;
        });
      }
    }
  }

  /// `pending_db_import` 키에 저장된 [PendingDbImportAction] 을 적용한다.
  /// 성공하거나 사용자가 버릴 때만 지운다. 실패하면 남긴 채 "다시 시도 / 버리기"를 묻는다(SQ-B03).
  Future<PendingDbImportOutcome> _applyPendingDbImport() async {
    if (mounted) setState(() => _importing = true);
    return PendingDbImportAction.applyPending(
      onFailure: (action, error) async {
        if (!mounted) return null;
        return showDialog<PendingDbImportFailureChoice>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('DB 가져오기 실패'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(error.toString().replaceFirst('Exception: ', '')),
                    const SizedBox(height: 12),
                    const Text('가져올 파일'),
                    SelectableText(action.path),
                    const SizedBox(height: 12),
                    const Text(
                      '다시 시도하면 같은 파일로 다시 가져옵니다. '
                      '버리면 빈 DB 로 시작하고, 파일은 위 위치에 그대로 남습니다.',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, PendingDbImportFailureChoice.discard),
                  child: const Text('버리고 빈 DB로 시작'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, PendingDbImportFailureChoice.retry),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 가져오기 결과 안내. 모드를 켠 뒤 이 화면이 사라져도 보이도록 미리 잡아 둔 [messenger] 로 띄운다.
  void _showImportOutcome(
    ScaffoldMessengerState messenger,
    PendingDbImportOutcome outcome,
  ) {
    if (!messenger.mounted) return;
    switch (outcome.status) {
      case PendingDbImportStatus.applied:
        final message = outcome.message;
        if (message == null) return;
        showSrSnackOn(
          messenger,
          message,
          kind: SrSnackKind.success,
          duration: const Duration(seconds: 4),
        );
      case PendingDbImportStatus.discarded:
        showSrSnackOn(
          messenger,
          'DB 가져오기를 버리고 빈 DB 로 시작합니다. 파일: ${outcome.action?.path}',
          kind: SrSnackKind.warning,
          duration: const Duration(seconds: 8),
        );
      case PendingDbImportStatus.none:
      case PendingDbImportStatus.kept:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.accountRecovery,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _buildStandaloneConfig(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandaloneConfig() {
    return SingleChildScrollView(
      key: const ValueKey('standaloneConfig'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('나만의 안전신문고', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('안전신문고 로그인', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Icon(
            Icons.shield_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          if (widget.onModeSelected != null)
            TextButton(
              onPressed: _loading ? null : _enterDemo,
              child: const Text('데모 보기'),
            ),
          const SizedBox(height: 28),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '아이디',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            autocorrect: false,
            textInputAction: TextInputAction.next,
            enabled: !_loading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: '비밀번호',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePw ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                tooltip: _obscurePw ? '비밀번호 보기' : '비밀번호 숨기기',
                onPressed: () => setState(() => _obscurePw = !_obscurePw),
              ),
            ),
            obscureText: _obscurePw,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _loading ? null : _loginStandalone(),
            enabled: !_loading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: '휴대폰번호',
              helperText: '별점 사유 조회용 · 숫자만 입력',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            autocorrect: false,
            enabled: !_loading,
          ),
          _buildError(),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: _loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Icon(Icons.login, size: 18),
            label: Text(
              _importing ? 'DB 가져오는 중...' : (_loading ? '로그인 중...' : '로그인'),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _loading ? null : _loginStandalone,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.sr.surfaceAlt,
              borderRadius: BorderRadius.circular(SrRadius.lg),
              border: Border.all(color: context.sr.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: context.sr.textSecondary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '비밀번호는 RSA 암호화해 전송하고, 자동 로그인용으로 기기에 암호화해 저장합니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.sr.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.tone(SrTone.danger).background,
          borderRadius: BorderRadius.circular(SrRadius.lg),
          border: Border.all(color: context.tone(SrTone.danger).border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
