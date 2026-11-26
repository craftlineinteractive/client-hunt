import 'package:flutter/material.dart';

/// The complete monochrome color system for ClientHunt.
///
/// Every role below is taken from the approved mockups (`code.html`), never
/// from `DESIGN.md` (whose indigo/teal palette is obsolete). Widgets must read
/// colors from this extension — `AppColors.of(context)` — and must never
/// hard-code a [Color].
///
/// The palette is strictly neutral: black, white and gray. There is no hue
/// anywhere, including for errors, success or warnings; those states are
/// communicated with icons and text weight instead.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.background,
    required this.canvas,
    required this.surface,
    required this.card,
    required this.cardSubtle,
    required this.border,
    required this.divider,
    required this.dividerSubtle,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.disabled,
    required this.disabledForeground,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.shadow,
    required this.overlayHover,
    required this.overlayPressed,
    required this.overlayFocus,
    required this.overlayScrim,
  });

  /// Light theme. Background white, primary near-black.
  static const AppColors light = AppColors(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    canvas: Color(0xFFFAFAFA),
    surface: Color(0xFFF5F5F5),
    card: Color(0xFFFFFFFF),
    cardSubtle: Color(0xFFFAFAFA),
    border: Color(0xFFE5E5E5),
    divider: Color(0xFFE5E5E5),
    dividerSubtle: Color(0xFFF0F0F0),
    primary: Color(0xFF111111),
    onPrimary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF525252),
    textMuted: Color(0xFF8A8A8A),
    disabled: Color(0xFFD4D4D4),
    disabledForeground: Color(0xFFB0B0B0),
    inverseSurface: Color(0xFF111111),
    onInverseSurface: Color(0xFFFAFAFA),
    shadow: Color(0x0D000000),
    overlayHover: Color(0x0A000000),
    overlayPressed: Color(0x14000000),
    overlayFocus: Color(0x1F000000),
    overlayScrim: Color(0x66000000),
  );

  /// Dark theme. Background near-black, primary near-white.
  static const AppColors dark = AppColors(
    brightness: Brightness.dark,
    background: Color(0xFF0A0A0A),
    canvas: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    card: Color(0xFF171717),
    cardSubtle: Color(0xFF141414),
    border: Color(0xFF2A2A2A),
    divider: Color(0xFF262626),
    dividerSubtle: Color(0xFF1F1F1F),
    primary: Color(0xFFFAFAFA),
    onPrimary: Color(0xFF111111),
    textPrimary: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA3A3A3),
    textMuted: Color(0xFF737373),
    disabled: Color(0xFF404040),
    disabledForeground: Color(0xFF525252),
    inverseSurface: Color(0xFFFAFAFA),
    onInverseSurface: Color(0xFF111111),
    shadow: Color(0x00000000),
    overlayHover: Color(0x0FFFFFFF),
    overlayPressed: Color(0x1AFFFFFF),
    overlayFocus: Color(0x24FFFFFF),
    overlayScrim: Color(0x99000000),
  );

  /// Convenience lookup. Falls back to the light palette if the extension is
  /// missing (only possible in a widget test that builds a bare [MaterialApp]).
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  final Brightness brightness;

  /// Screen background. `#FFFFFF` light, `#0A0A0A` dark.
  final Color background;

  /// List/filter/export/settings body background. `#FAFAFA` light.
  final Color canvas;

  /// Recessed surface: grouped inputs, unselected chips, segmented tracks.
  final Color surface;

  /// Card fill. `#FFFFFF` light, `#171717` dark.
  final Color card;

  /// Slightly recessed card fill used for plan rows, reviews and fact tiles.
  final Color cardSubtle;

  /// 1 px outline for cards, inputs, chips and bars.
  final Color border;

  /// Row divider.
  final Color divider;

  /// Hairline divider used inside dense lists.
  final Color dividerSubtle;

  /// Filled buttons, selected chips, active navigation pill.
  final Color primary;

  /// Content placed on [primary].
  final Color onPrimary;

  /// Headings and values.
  final Color textPrimary;

  /// Supporting labels and row icons.
  final Color textSecondary;

  /// Captions, placeholders, metadata.
  final Color textMuted;

  /// Disabled control fill and off switch track.
  final Color disabled;

  /// Disabled icon/label color.
  final Color disabledForeground;

  /// Inverted surfaces: selection bar, Pro card, tooltips, snackbars.
  final Color inverseSurface;

  /// Content placed on [inverseSurface].
  final Color onInverseSurface;

  /// Soft shadow color in light mode; fully transparent in dark mode.
  final Color shadow;

  /// Hover overlay layered on a surface.
  final Color overlayHover;

  /// Pressed overlay layered on a surface.
  final Color overlayPressed;

  /// Focus wash layered on a surface.
  final Color overlayFocus;

  /// Modal scrim behind bottom sheets and dialogs.
  final Color overlayScrim;

  /// True when this palette belongs to the dark theme.
  bool get isDark => brightness == Brightness.dark;

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? canvas,
    Color? surface,
    Color? card,
    Color? cardSubtle,
    Color? border,
    Color? divider,
    Color? dividerSubtle,
    Color? primary,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? disabled,
    Color? disabledForeground,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? shadow,
    Color? overlayHover,
    Color? overlayPressed,
    Color? overlayFocus,
    Color? overlayScrim,
  }) {
    return AppColors(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardSubtle: cardSubtle ?? this.cardSubtle,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      dividerSubtle: dividerSubtle ?? this.dividerSubtle,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      disabled: disabled ?? this.disabled,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      onInverseSurface: onInverseSurface ?? this.onInverseSurface,
      shadow: shadow ?? this.shadow,
      overlayHover: overlayHover ?? this.overlayHover,
      overlayPressed: overlayPressed ?? this.overlayPressed,
      overlayFocus: overlayFocus ?? this.overlayFocus,
      overlayScrim: overlayScrim ?? this.overlayScrim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: mix(background, other.background),
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      card: mix(card, other.card),
      cardSubtle: mix(cardSubtle, other.cardSubtle),
      border: mix(border, other.border),
      divider: mix(divider, other.divider),
      dividerSubtle: mix(dividerSubtle, other.dividerSubtle),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      disabled: mix(disabled, other.disabled),
      disabledForeground: mix(disabledForeground, other.disabledForeground),
      inverseSurface: mix(inverseSurface, other.inverseSurface),
      onInverseSurface: mix(onInverseSurface, other.onInverseSurface),
      shadow: mix(shadow, other.shadow),
      overlayHover: mix(overlayHover, other.overlayHover),
      overlayPressed: mix(overlayPressed, other.overlayPressed),
      overlayFocus: mix(overlayFocus, other.overlayFocus),
      overlayScrim: mix(overlayScrim, other.overlayScrim),
    );
  }
}
