import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sr_colors.dart';
import 'sr_tokens.dart';

/// 앱 공통 테마. 두 실행 모드가 같은 primary 를 쓰고(D-03), 모드는 `ModeBadge` 로 따로 표시한다.
/// 글꼴은 기기 기본(D-04)이라 fontFamily 를 지정하지 않는다.
class AppTheme {
  AppTheme._();

  /// 라이트 primary. 토큰 `#0D6EFD` 는 흰 글자 대비가 4.50:1 경계라 한 단계 어둡게 쓴다(5.84:1).
  static const lightPrimary = Color(0xFF0B5ED7);

  /// 다크 primary(글자·아이콘 역할). 웹 `--sr-primary-text` 와 같은 값 — 딥 다크 바탕 위 7.7:1, onPrimary 는 어두운 글자.
  static const darkPrimary = Color(0xFF60A5FA);

  /// 다크 채움(버튼·선택 탭 바탕, 흰 글자 5.17:1). 웹 `--sr-primary` 와 같은 값. 라이트는 [lightPrimary] 가 채움도 맡는다.
  static const darkPrimaryFill = Color(0xFF2563EB);

  /// 앱이 쓰는 테마는 한 번만 만든다(SQ-P01). ThemeData 안의 `WidgetStateProperty.resolveWith` 는 `==` 가 없어
  /// 새로 만든 테마는 늘 "다른 테마"로 판정되고, MaterialApp 의 AnimatedTheme 이 200ms 보간으로 전체를 다시 그린다.
  static final ThemeData _light = build(Brightness.light);
  static final ThemeData _dark = build(Brightness.dark);

  static ThemeData light() => _light;
  static ThemeData dark() => _dark;

  /// 바텀시트 위 모서리 반경. 시트마다 따로 주지 않고 테마로 맞춘다(SQ-U07).
  /// 20 은 반경 단계 밖이라 2xl(24)로 맞췄다(SQ-U23, 2026-10-04).
  static const sheetRadius = SrRadius.xxl;

  static ThemeData build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final t = isDark ? SrColors.dark : SrColors.light;
    final primary = isDark ? darkPrimary : lightPrimary;
    final onPrimary = isDark ? t.background : Colors.white;
    // 채움(버튼·선택 탭)은 웹과 같게 진한 파랑 + 흰 글자. 글자·아이콘은 primary.
    final fill = isDark ? darkPrimaryFill : lightPrimary;
    const onFill = Colors.white;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: t.brandSoft,
      onPrimaryContainer: isDark
          ? const Color(0xFFDBEAFE)
          : const Color(0xFF0B3C8C),
      secondary: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0E7490),
      onSecondary: isDark ? t.background : Colors.white,
      // FilledButton.tonal 등이 쓰는 컨테이너. 지정하지 않으면 secondary 원색으로 칠해져 튄다.
      secondaryContainer: t.brandSoft,
      onSecondaryContainer: isDark
          ? const Color(0xFFDBEAFE)
          : const Color(0xFF0B3C8C),
      tertiary: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7156A8),
      onTertiary: isDark ? t.background : Colors.white,
      tertiaryContainer: t.surfaceAlt,
      onTertiaryContainer: t.textPrimary,
      errorContainer: isDark
          ? const Color(0xFF450A0A)
          : const Color(0xFFFEE2E2),
      onErrorContainer: isDark
          ? const Color(0xFFFECACA)
          : const Color(0xFF991B1B),
      error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      onError: isDark ? t.background : Colors.white,
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.textSecondary,
      surfaceContainerLowest: isDark ? t.background : Colors.white,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.surfaceAlt,
      surfaceContainerHigh: isDark
          ? const Color(0xFF232324) // --sr-surface-3
          : const Color(0xFFEAEAED),
      surfaceContainerHighest: isDark
          ? const Color(0xFF2A2A2C)
          : const Color(0xFFE3E3E8),
      outline: isDark ? const Color(0xFF3A3A3D) : const Color(0xFFC7C7CC),
      outlineVariant: t.border,
      inverseSurface: isDark ? t.textPrimary : const Color(0xFF242426),
      onInverseSurface: isDark ? t.background : const Color(0xFFF5F5F7),
      inversePrimary: isDark ? lightPrimary : darkPrimary,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    // edge-to-edge: 아이콘 밝기만 조정하고 statusBarColor 는 싣지 않는다(docs/architecture/android-runtime.md).
    final overlayStyle = SystemUiOverlayStyle(
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(SrRadius.lg)),
      borderSide: BorderSide(color: t.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [t],
      scaffoldBackgroundColor: t.background,
      canvasColor: t.background,
      dividerColor: t.border,
      // 작은 글자 단계(spec §3 Caption 12/16). Material 기본 labelSmall(11)은 최소 크기 밑이라 올린다(SQ-U19).
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
        bodySmall: TextStyle(fontSize: SrFontSize.caption),
        labelSmall: TextStyle(fontSize: SrFontSize.caption),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: t.background,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyle,
        titleSpacing: 16,
        titleTextStyle: TextStyle(
          color: t.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        // 시안의 알약형 선택 탭. 선택/미선택 모두 배경 대비 AA 를 만족해야 한다(test/theme).
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: fill,
        dividerColor: Colors.transparent,
        labelColor: primary,
        unselectedLabelColor: t.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        splashBorderRadius: BorderRadius.circular(SrRadius.md),
        overlayColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.08)),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(SrRadius.lg)),
          side: BorderSide(color: t.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SrRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        modalBackgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        // 손잡이는 테마 하나만 그린다 — 시트가 직접 그리지 않는다(SQ-U07).
        showDragHandle: true,
        dragHandleColor: t.textDisabled,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: TextStyle(color: t.textSecondary),
        hintStyle: TextStyle(color: t.textSecondary),
        prefixIconColor: t.textSecondary,
        suffixIconColor: t.textSecondary,
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.6)),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        elevation: 0,
        height: 72,
        indicatorColor: isDark ? primary.withValues(alpha: 0.22) : t.brandSoft,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : t.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: SrFontSize.caption,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? primary
                : t.textSecondary,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.textSecondary,
        minVerticalPadding: 12,
        textColor: t.textPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceAlt,
        side: BorderSide(color: t.border),
        labelStyle: TextStyle(
          color: t.textPrimary,
          fontSize: SrFontSize.caption,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SrRadius.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: fill,
          foregroundColor: onFill,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SrRadius.lg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: t.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SrRadius.lg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SrRadius.lg),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: t.textSecondary,
        collapsedIconColor: t.textSecondary,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(t.border),
      ),
    );
  }
}
