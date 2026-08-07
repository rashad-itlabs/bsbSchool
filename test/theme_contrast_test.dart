import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bsbschool/dr/theme/dr_colors.dart';

/// WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colours, 1:1 .. 21:1.
double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // The regression this guards: the neon lime was used as a foreground on both
  // themes. It reads at ~1.2:1 on the light palette's white cards — invisible.
  group('accent stays legible as a foreground', () {
    const palettes = {'dark': DrPalette.dark, 'light': DrPalette.light};

    for (final entry in palettes.entries) {
      final name = entry.key;
      final p = entry.value;

      test('$name: accent passes AA on every surface', () {
        for (final surface in {
          'bgDark': p.bgDark,
          'bgSurface': p.bgSurface,
          'bgSurfaceLight': p.bgSurfaceLight,
        }.entries) {
          final ratio = _contrast(p.accent, surface.value);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$name accent on ${surface.key} is '
                '${ratio.toStringAsFixed(2)}:1, below the 4.5:1 AA floor',
          );
        }
      });

      test('$name: main and muted text pass on the card surface', () {
        expect(_contrast(p.textMain, p.bgSurface), greaterThanOrEqualTo(4.5));
        // Muted text is secondary — AA large / UI component floor.
        expect(_contrast(p.textMuted, p.bgSurface), greaterThanOrEqualTo(3.0));
      });
    }

    test('the neon lime fill keeps black content readable on it', () {
      // Buttons, chips and badges still use the brand lime as a fill, with
      // black content on top; that pairing is what makes it safe on both.
      expect(
        _contrast(const Color(0xFF000000), DrColors.accentGreen),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('dark keeps the brand lime, light darkens it', () {
      expect(DrPalette.dark.accent, DrColors.accentGreen);
      expect(DrPalette.light.accent, DrColors.accentGreenDark);
      // Same hue family, so the design still reads as the same brand.
      final lime = HSLColor.fromColor(DrColors.accentGreen);
      final deep = HSLColor.fromColor(DrColors.accentGreenDark);
      expect((lime.hue - deep.hue).abs(), lessThan(20));
    });
  });

  test('lerp and copyWith carry the accent tokens', () {
    final mid = DrPalette.dark.lerp(DrPalette.light, 0.5);
    expect(mid.accent, isNot(DrPalette.dark.accent));

    final copy = DrPalette.light.copyWith(bgDark: const Color(0xFF123456));
    expect(copy.accent, DrPalette.light.accent);
    expect(copy.accentSoft, DrPalette.light.accentSoft);
  });
}
