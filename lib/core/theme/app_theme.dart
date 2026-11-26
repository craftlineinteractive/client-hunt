import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the two Material 3 themes for ClientHunt.
///
/// Everything is derived from [AppColors] and [AppTypography]; there are no
/// component-level color literals here beyond the palette itself. Light mode
/// uses a soft shadow; dark mode uses borders only (no shadow at all).
abstract final class AppTheme {
  /// Light theme with `#FFFFFF` background and `#111111` primary.
  static ThemeData get light => _build(AppColors.light);

  /// Dark theme with `#0A0A0A` background and `#FAFAFA` primary.
  static ThemeData get dark => _build(AppColors.dark);

  static ThemeData _build(AppColors c) {
    final bool isDark = c.isDark;
    final ColorScheme scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.surface,
      onPrimaryContainer: c.textPrimary,
      secondary: c.textSecondary,
      onSecondary: c.onPrimary,
      secondaryContainer: c.surface,
      onSecondaryContainer: c.textPrimary,
      tertiary: c.textPrimary,
      onTertiary: c.onPrimary,
      tertiaryContainer: c.surface,
      onTertiaryContainer: c.textPrimary,
      error: c.textPrimary,
      onError: c.onPrimary,
      errorContainer: c.surface,
      onErrorContainer: c.textPrimary,
      surface: c.background,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.cardSubtle,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.card,
      surfaceContainerHighest: c.divider,
      inverseSurface: c.inverseSurface,
      onInverseSurface: c.onInverseSurface,
      outline: c.border,
      outlineVariant: c.divider,
      shadow: c.shadow,
      scrim: c.overlayScrim,
      surfaceTint: const Color(0x00000000),
    );

    final TextTheme textTheme = AppTypography.textTheme.apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: textTheme,
      primaryColor: c.primary,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      applyElevationOverlayColor: false,
      extensions: <ThemeExtension<dynamic>>[c],
      iconTheme: IconThemeData(color: c.textPrimary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: AppSpacing.appBarHeight,
        titleSpacing: AppSpacing.screenPadding,
        titleTextStyle: AppTypography.titleMd.copyWith(color: c.textPrimary),
        iconTheme: IconThemeData(color: c.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: c.textPrimary, size: 22),
        shape: Border(bottom: BorderSide(color: c.border)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.bottomNavHeight,
        backgroundColor: c.background,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        indicatorColor: c.primary,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppTypography.labelMd.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                )
              : AppTypography.labelMd.copyWith(color: c.textMuted),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? c.onPrimary
                : c.textMuted,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        surfaceTintColor: const Color(0x00000000),
        shadowColor: c.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.bodyMd.copyWith(color: c.textMuted),
        labelStyle: AppTypography.labelMd.copyWith(color: c.textSecondary),
        floatingLabelStyle: AppTypography.labelMd.copyWith(
          color: c.textPrimary,
        ),
        errorStyle: AppTypography.bodySm.copyWith(
          color: c.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: AppTypography.bodySm.copyWith(color: c.textMuted),
        counterStyle: AppTypography.bodySm.copyWith(color: c.textMuted),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        border: inputBorder(c.border),
        enabledBorder: inputBorder(c.border),
        focusedBorder: inputBorder(c.textPrimary, 1.5),
        errorBorder: inputBorder(c.textPrimary),
        focusedErrorBorder: inputBorder(c.textPrimary, 1.5),
        disabledBorder: inputBorder(c.dividerSubtle),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? c.onPrimary
              : c.background,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? c.primary : c.disabled,
        ),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Color(0x00000000),
        ),
        trackOutlineWidth: const WidgetStatePropertyAll<double>(0),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.checkbox),
        ),
        side: WidgetStateBorderSide.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? BorderSide(color: c.primary, width: 1.5)
              : BorderSide(color: c.disabledForeground, width: 1.5),
        ),
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? c.primary : c.card,
        ),
        checkColor: WidgetStatePropertyAll<Color>(c.onPrimary),
        overlayColor: WidgetStatePropertyAll<Color>(c.overlayPressed),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? c.primary
              : c.disabledForeground,
        ),
        overlayColor: WidgetStatePropertyAll<Color>(c.overlayPressed),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primary,
        disabledColor: c.surface,
        surfaceTintColor: const Color(0x00000000),
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
        labelStyle: AppTypography.labelLg.copyWith(color: c.textPrimary),
        secondaryLabelStyle: AppTypography.labelLg.copyWith(color: c.onPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        showCheckmark: true,
        checkmarkColor: c.onPrimary,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) =>
                states.contains(WidgetState.selected) ? c.primary : c.card,
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) => states.contains(WidgetState.selected)
                ? c.onPrimary
                : c.textSecondary,
          ),
          side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: c.border)),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600),
          ),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppSpacing.minTapTarget, AppSpacing.minTapTarget),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: c.primary,
        inactiveTrackColor: c.disabled,
        thumbColor: c.primary,
        overlayColor: c.overlayFocus,
        valueIndicatorColor: c.primary,
        valueIndicatorTextStyle: AppTypography.monoSm.copyWith(
          color: c.onPrimary,
        ),
        thumbShape: const RoundSliderThumbShape(),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        trackShape: const RoundedRectSliderTrackShape(),
        showValueIndicator: ShowValueIndicator.never,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.inverseSurface,
        contentTextStyle: AppTypography.bodySm.copyWith(
          color: c.onInverseSurface,
        ),
        actionTextColor: c.onInverseSurface,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: const Color(0x00000000),
        modalBackgroundColor: c.card,
        modalBarrierColor: c.overlayScrim,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetTop,
          side: BorderSide(color: Color(0x00000000)),
        ),
        dragHandleColor: c.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.xxl),
        titleTextStyle: AppTypography.titleMd.copyWith(color: c.textPrimary),
        contentTextStyle: AppTypography.bodyMd.copyWith(color: c.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlAll,
          side: BorderSide(color: c.border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        circularTrackColor: c.divider,
        linearTrackColor: c.divider,
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: AppTypography.bodySm.copyWith(color: c.onInverseSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        margin: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: c.inverseSurface,
          borderRadius: AppRadius.smAll,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.15),
        selectionHandleColor: c.primary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        minVerticalPadding: AppSpacing.sm,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(c.textPrimary),
          overlayColor: WidgetStatePropertyAll<Color>(c.overlayPressed),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            AppTypography.labelLg.copyWith(fontWeight: FontWeight.w600),
          ),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppSpacing.minTapTarget, AppSpacing.minTapTarget),
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(c.textPrimary),
          backgroundColor: WidgetStatePropertyAll<Color>(c.card),
          overlayColor: WidgetStatePropertyAll<Color>(c.overlayPressed),
          side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: c.border)),
          textStyle: WidgetStatePropertyAll<TextStyle>(AppTypography.button),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppSpacing.minTapTarget, AppSpacing.buttonHeight),
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(c.onPrimary),
          backgroundColor: WidgetStatePropertyAll<Color>(c.primary),
          overlayColor: WidgetStatePropertyAll<Color>(
            isDark ? c.overlayPressed : c.overlayHover,
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(AppTypography.button),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppSpacing.minTapTarget, AppSpacing.buttonHeight),
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(c.onPrimary),
          backgroundColor: WidgetStatePropertyAll<Color>(c.primary),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Color(0x00000000),
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
          textStyle: WidgetStatePropertyAll<TextStyle>(AppTypography.button),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppSpacing.minTapTarget, AppSpacing.buttonHeight),
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        ),
      ),
    );
  }
}
