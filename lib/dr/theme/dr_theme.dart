import 'package:flutter/material.dart';

import 'dr_colors.dart';

/// Light & dark themes matching the `theme_dr` HTML mockups.
class DrTheme {
  DrTheme._();

  static ThemeData get dark => _build(Brightness.dark, DrPalette.dark);

  static ThemeData get light => _build(Brightness.light, DrPalette.light);

  static ThemeData _build(Brightness brightness, DrPalette palette) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = (isDark
            ? const ColorScheme.dark()
            : const ColorScheme.light())
        .copyWith(
      surface: palette.bgSurface,
      primary: DrColors.accentGreen,
      onPrimary: Colors.black,
      secondary: DrColors.accentGreen,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.bgDark,
      // Inter is the design font; falls back to the platform sans-serif which
      // is visually close. No network dependency is pulled in.
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      textTheme: (isDark
              ? Typography.whiteMountainView
              : Typography.blackMountainView)
          .apply(
        bodyColor: palette.textMain,
        displayColor: palette.textMain,
      ),
      splashColor: DrColors.accentGreenSoft,
      highlightColor: Colors.transparent,
      extensions: [palette],
    );
  }
}
