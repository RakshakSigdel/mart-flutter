import 'package:animations/animations.dart';
// Flutter 3.44 keeps the iOS slide transition in the cupertino library rather
// than exporting it from material.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles all design tokens into a Flutter [ThemeData].
///
/// This file must not define any color, size, or text value directly —
/// it only consumes them from the other token files. If you need a new value,
/// add it to `app_colors.dart` / `app_spacing.dart` / `app_typography.dart`
/// first and reference it here.
class AppTheme {
  AppTheme._();

  // ─── Shared sub-themes ──────────────────────────────────────────────────

  /// Every Material page transition routes through the `animations` package
  /// so imperative `Navigator.push` matches the go_router transitions in
  /// `core/animations/app_page_route.dart`.
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SharedAxisPageTransitionsBuilder(
        transitionType: SharedAxisTransitionType.horizontal,
      ),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeThroughPageTransitionsBuilder(),
    },
  );

  static TextTheme get _textTheme => const TextTheme(
    displayLarge: AppTypography.display,
    displayMedium: AppTypography.displaySmall,
    displaySmall: AppTypography.heading,
    headlineLarge: AppTypography.displaySmall,
    headlineMedium: AppTypography.heading,
    headlineSmall: AppTypography.title,
    titleLarge: AppTypography.title,
    titleMedium: AppTypography.subtitle,
    titleSmall: AppTypography.label,
    bodyLarge: AppTypography.body,
    bodyMedium: AppTypography.bodySmall,
    bodySmall: AppTypography.caption,
    labelLarge: AppTypography.label,
    labelMedium: AppTypography.labelSmall,
    labelSmall: AppTypography.eyebrow,
  ).apply(fontFamily: AppTypography.fontFamily);

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AppBorderRadius.radiusL,
        borderSide: BorderSide(color: color, width: width),
      );

  // ─── Light theme ────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      primaryColor: AppColors.primary,
      dividerColor: AppColors.border,
      splashColor: AppColors.pressedOverlay,
      highlightColor: AppColors.hoverOverlay,
      textTheme: _textTheme,
      pageTransitionsTheme: _pageTransitions,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // ─── Color Scheme ───────────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        // Primary is yellow — text on it must be dark, not white.
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primaryDeep,
        secondary: AppColors.accent,
        // Secondary is black — white text reads correctly on it.
        onSecondary: AppColors.textInverse,
        secondaryContainer: AppColors.accentSoft,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.textInverse,
        tertiaryContainer: AppColors.tertiarySoft,
        onTertiaryContainer: AppColors.tertiary,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        surfaceContainerLowest: AppColors.card,
        surfaceContainer: AppColors.surface,
        surfaceContainerHighest: AppColors.surfaceSunken,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.error,
        onError: AppColors.textInverse,
        errorContainer: AppColors.errorSoft,
        onErrorContainer: AppColors.error,
        outline: AppColors.border,
        outlineVariant: AppColors.borderStrong,
        scrim: AppColors.scrim,
        inverseSurface: AppColors.accent,
        onInverseSurface: AppColors.textInverse,
        inversePrimary: AppColors.primary,
      ),

      // ─── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        iconTheme: const IconThemeData(color: AppColors.iconActive, size: 22),
        actionsIconTheme: const IconThemeData(
          color: AppColors.iconActive,
          size: 22,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: AppTypography.title.copyWith(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
        ),
      ),

      // ─── Icons ──────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.iconActive, size: 22),

      // ─── Card ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusXL,
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // ─── Divider ────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Shared styling for directory, transaction and report tables.
      dataTableTheme: DataTableThemeData(
        headingRowHeight: 48,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 72,
        dividerThickness: 0.5,
        headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
        headingTextStyle: AppTypography.labelSmall,
        dataTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primarySoft;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.surface;
          }
          return AppColors.card;
        }),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: AppBorderRadius.radiusMD,
        ),
      ),

      // ─── Input / TextField ──────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodySmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textMuted,
        ),
        labelStyle: AppTypography.bodySmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: AppTypography.labelSmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.primaryDeep,
        ),
        errorStyle: AppTypography.caption.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.error,
        ),
        prefixIconColor: AppColors.iconInactive,
        suffixIconColor: AppColors.iconInactive,
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        disabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primaryDeep, width: 1.5),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 1.5),
      ),

      // ─── ElevatedButton (maps to AppButton primary) ─────────────────────
      // Yellow fill, dark text.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.btnDisabled,
          disabledForegroundColor: AppColors.btnDisabledText,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.smMd,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusL),
          textStyle: AppTypography.label.copyWith(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
          ),
        ),
      ),

      // ─── FilledButton (dark/secondary emphasis) ─────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: AppColors.btnDisabled,
          disabledForegroundColor: AppColors.btnDisabledText,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.smMd,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusL),
          textStyle: AppTypography.label.copyWith(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
          ),
        ),
      ),

      // ─── OutlinedButton (maps to AppButton secondary) ───────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.btnDisabledText,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.smMd,
          ),
          side: const BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusL),
          textStyle: AppTypography.label.copyWith(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── TextButton (ghost variant) ─────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          disabledForegroundColor: AppColors.btnDisabledText,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusL),
          textStyle: AppTypography.bodySmall.copyWith(
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── IconButton ─────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.iconActive,
          highlightColor: AppColors.pressedOverlay,
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusMD),
        ),
      ),

      // ─── FloatingActionButton ───────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusL),
      ),

      // ─── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surface,
        secondarySelectedColor: AppColors.primary,
        checkmarkColor: AppColors.textOnPrimary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smMd,
          vertical: AppSpacing.xs,
        ),
        labelStyle: AppTypography.bodySmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: AppTypography.bodySmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnPrimary,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusFull),
      ),

      // ─── BottomNavigationBar ────────────────────────────────────────────
      // Dark bar, yellow active state, white/muted labels.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textInverse,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.eyebrow.copyWith(
          fontFamily: AppTypography.fontFamily,
          letterSpacing: 0,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: AppTypography.eyebrow.copyWith(
          fontFamily: AppTypography.fontFamily,
          letterSpacing: 0,
          fontWeight: FontWeight.w500,
          color: AppColors.textInverse,
        ),
      ),

      // ─── NavigationBar (Material 3 equivalent) ──────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusFull,
        ),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.textOnPrimary
                : AppColors.textInverse,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.eyebrow.copyWith(
            fontFamily: AppTypography.fontFamily,
            letterSpacing: 0,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textInverse,
          ),
        ),
      ),

      // ─── NavigationRail (tablet / desktop) ──────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.backgroundDark,
        indicatorColor: AppColors.primary,
        selectedIconTheme: const IconThemeData(
          color: AppColors.textOnPrimary,
          size: 22,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textInverse,
          size: 22,
        ),
        selectedLabelTextStyle: AppTypography.labelSmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.primary,
        ),
        unselectedLabelTextStyle: AppTypography.labelSmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textInverse,
        ),
      ),

      // ─── TabBar ─────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTypography.label.copyWith(
          fontFamily: AppTypography.fontFamily,
        ),
        unselectedLabelStyle: AppTypography.bodySmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
        ),
        overlayColor: WidgetStatePropertyAll(AppColors.hoverOverlay),
      ),

      // ─── ListTile ───────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTypography.subtitle.copyWith(
          fontFamily: AppTypography.fontFamily,
        ),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          fontFamily: AppTypography.fontFamily,
        ),
        selectedColor: AppColors.primaryDeep,
        selectedTileColor: AppColors.primarySoft,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusMD),
      ),

      // ─── Dialog ─────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: AppColors.modalBarrier,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusXL),
        titleTextStyle: AppTypography.title.copyWith(
          fontFamily: AppTypography.fontFamily,
        ),
        contentTextStyle: AppTypography.bodySmall.copyWith(
          fontFamily: AppTypography.fontFamily,
        ),
      ),

      // ─── BottomSheet ────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.card,
        modalBarrierColor: AppColors.modalBarrier,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      // ─── SnackBar ───────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.accent,
        contentTextStyle: AppTypography.bodySmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textInverse,
        ),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusMD),
      ),

      // ─── Tooltip ────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smMd,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: AppBorderRadius.radiusSM,
        ),
        textStyle: AppTypography.caption.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textInverse,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // ─── PopupMenu ──────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusL,
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.textPrimary,
        ),
      ),

      // ─── Selection controls ─────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusXS),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.borderStrong,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.textOnPrimary
              : AppColors.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surfaceSunken,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.border),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceSunken,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.focusRing,
      ),

      // ─── Progress ───────────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceSunken,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 4,
      ),

      // ─── Misc ───────────────────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(AppRadius.full),
        thumbColor: const WidgetStatePropertyAll(AppColors.borderStrong),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.primarySoft,
        selectionHandleColor: AppColors.primary,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: AppColors.textInverse,
        textStyle: AppTypography.caption.copyWith(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textInverse,
        ),
      ),
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // In main.dart:
// MaterialApp.router(
//   theme: AppTheme.lightTheme,
//   themeMode: ThemeMode.light,
//   routerConfig: AppRouter.router,
// )
