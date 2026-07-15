import 'package:flutter/material.dart';

/// Brand / categorical colors — identical across light & dark themes.
class DrColors {
  DrColors._();

  // Accent
  static const Color accentGreen = Color(0xFFB1FF29);
  static Color accentGreenGlow = const Color(0xFFB1FF29).withValues(alpha: 0.4);
  static Color accentGreenSoft = const Color(0xFFB1FF29).withValues(alpha: 0.1);

  // Categorical accents used by icons / tags across screens
  static const Color orange = Color(0xFFFF9F43);
  static const Color teal = Color(0xFF00D2D3);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color red = Color(0xFFFF6B6B);
  static const Color redStrong = Color(0xFFFF4757);
  static const Color green = Color(0xFF2ECC71);
}

/// Surface / text tokens that differ between light and dark. Exposed as a
/// [ThemeExtension] so widgets recolor reactively via `Theme.of(context)` when
/// the theme mode changes. Access through the [DrPaletteX.dr] getter, e.g.
/// `context.dr.bgSurface`.
@immutable
class DrPalette extends ThemeExtension<DrPalette> {
  final Color bgDark;
  final Color bgSurface;
  final Color bgSurfaceLight;
  final Color border;
  final Color nav;
  final Color textMain;
  final Color textMuted;

  const DrPalette({
    required this.bgDark,
    required this.bgSurface,
    required this.bgSurfaceLight,
    required this.border,
    required this.nav,
    required this.textMain,
    required this.textMuted,
  });

  /// Dark tokens ported 1:1 from `theme_dr/style.css` (Leo-bank style dark UI).
  static const DrPalette dark = DrPalette(
    bgDark: Color(0xFF0F0F11),
    bgSurface: Color(0xFF1C1C1F),
    bgSurfaceLight: Color(0xFF28282C),
    border: Color(0xFF2C2C30),
    nav: Color(0xE61C1C1F), // rgba(28,28,31,0.9)
    textMain: Color(0xFFFFFFFF),
    textMuted: Color(0xA6FFFFFF), // white @ 65%
  );

  /// Light counterpart of [dark].
  static const DrPalette light = DrPalette(
    bgDark: Color(0xFFF4F5F7),
    bgSurface: Color(0xFFFFFFFF),
    bgSurfaceLight: Color(0xFFEDEEF1),
    border: Color(0xFFE3E5EA),
    nav: Color(0xE6FFFFFF), // rgba(255,255,255,0.9)
    textMain: Color(0xFF121316),
    textMuted: Color(0x8C121316), // near-black @ ~55%
  );

  @override
  DrPalette copyWith({
    Color? bgDark,
    Color? bgSurface,
    Color? bgSurfaceLight,
    Color? border,
    Color? nav,
    Color? textMain,
    Color? textMuted,
  }) {
    return DrPalette(
      bgDark: bgDark ?? this.bgDark,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurfaceLight: bgSurfaceLight ?? this.bgSurfaceLight,
      border: border ?? this.border,
      nav: nav ?? this.nav,
      textMain: textMain ?? this.textMain,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  DrPalette lerp(covariant ThemeExtension<DrPalette>? other, double t) {
    if (other is! DrPalette) return this;
    return DrPalette(
      bgDark: Color.lerp(bgDark, other.bgDark, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurfaceLight: Color.lerp(bgSurfaceLight, other.bgSurfaceLight, t)!,
      border: Color.lerp(border, other.border, t)!,
      nav: Color.lerp(nav, other.nav, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

/// Convenience accessor: `context.dr.bgSurface`.
extension DrPaletteX on BuildContext {
  DrPalette get dr =>
      Theme.of(this).extension<DrPalette>() ?? DrPalette.dark;
}
