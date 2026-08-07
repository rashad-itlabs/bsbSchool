import 'package:flutter/material.dart';

/// Brand / categorical colors — identical across light & dark themes.
class DrColors {
  DrColors._();

  // Accent.
  //
  // The neon lime is a *fill* colour: black on it reads at 17:1 on either
  // theme, so buttons, chips and badges keep it. It is NOT usable as a
  // foreground — on the light palette's white surfaces it lands at 1.2:1,
  // i.e. invisible. Text, icons, dots and thin strokes must use
  // `context.dr.accent` instead, which darkens with the light theme.
  static const Color accentGreen = Color(0xFFB1FF29);
  static Color accentGreenGlow = const Color(0xFFB1FF29).withValues(alpha: 0.4);
  static Color accentGreenSoft = const Color(0xFFB1FF29).withValues(alpha: 0.1);

  /// Readable-on-light counterpart of [accentGreen]. Hue 84° against the
  /// lime's 82°, so it still reads as the same brand green, but dark enough to
  /// clear 4.5:1 on every light surface (5.6:1 white, 5.1:1 page, 4.8:1 the
  /// tinted card fill).
  static const Color accentGreenDark = Color(0xFF467400);

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

  /// The accent as a *foreground*: links, icons, dots, rings, thin strokes and
  /// any text that must stay legible on [bgSurface] / [bgDark].
  ///
  /// Filled surfaces (buttons, active chips, badges) keep [DrColors.accentGreen]
  /// instead — black on neon lime reads fine on both themes, and swapping it
  /// would cost the design its signature.
  final Color accent;

  /// Tint used behind [accent] icons and status pills.
  final Color accentSoft;

  const DrPalette({
    required this.bgDark,
    required this.bgSurface,
    required this.bgSurfaceLight,
    required this.border,
    required this.nav,
    required this.textMain,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
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
    // The neon lime already reads at 14:1 on these surfaces.
    accent: DrColors.accentGreen,
    accentSoft: Color(0x1AB1FF29), // lime @ 10%
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
    // Same hue family as the lime, dark enough to read on white.
    accent: DrColors.accentGreenDark,
    accentSoft: Color(0x1F467400), // deep lime @ 12%
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
    Color? accent,
    Color? accentSoft,
  }) {
    return DrPalette(
      bgDark: bgDark ?? this.bgDark,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurfaceLight: bgSurfaceLight ?? this.bgSurfaceLight,
      border: border ?? this.border,
      nav: nav ?? this.nav,
      textMain: textMain ?? this.textMain,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
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
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
    );
  }
}

/// Convenience accessor: `context.dr.bgSurface`.
extension DrPaletteX on BuildContext {
  DrPalette get dr =>
      Theme.of(this).extension<DrPalette>() ?? DrPalette.dark;
}
