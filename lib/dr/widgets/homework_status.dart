import 'package:flutter/material.dart';

import '../../features/homework/domain/entities/homework.dart';
import '../../features/homework/domain/entities/homework_status_info.dart';
import '../theme/dr_colors.dart';

/// How a homework's status is shown: its name in the app language, colour and
/// optional hint — from the server's `statuses` dictionary (16.10.2026), so
/// the website's words reach the app without a release.
class HomeworkStatusBadge {
  /// The server key: `assigned`, `submitted`, `not_submitted`,
  /// `teacher_missed`, `absent`.
  final String key;
  final String label;

  /// Readable on the current theme's card (see [_readable]).
  final Color color;
  final String? hint;

  const HomeworkStatusBadge({
    required this.key,
    required this.label,
    required this.color,
    this.hint,
  });

  bool get isAssigned => key == 'assigned';

  /// Null on a server without statuses (before 08.10.2026) — the caller keeps
  /// its old deadline / hand-in logic then.
  static HomeworkStatusBadge? of(BuildContext context, Homework homework) {
    final key = homework.status;
    if (key == null) return null;

    final language = Localizations.localeOf(context).languageCode;
    final info = homework.statusInfo;
    final server = info?.color;

    return HomeworkStatusBadge(
      key: key,
      // The dictionary in the app's language; then the request-language
      // label of the homework itself; then the key, never empty.
      label: info?.labelFor(language) ?? homework.statusLabel ?? key,
      color: _readable(
        context,
        server != null ? Color(server) : _fallback(context, key),
      ),
      hint: info?.hintFor(language),
    );
  }

  /// A status as the filter sheet offers it — the same words and colour a
  /// card with that status shows.
  static HomeworkStatusBadge ofInfo(
      BuildContext context, HomeworkStatusInfo info) {
    final language = Localizations.localeOf(context).languageCode;
    final server = info.color;

    return HomeworkStatusBadge(
      key: info.key,
      label: info.labelFor(language),
      color: _readable(
        context,
        server != null ? Color(server) : _fallback(context, info.key),
      ),
      hint: info.hintFor(language),
    );
  }

  /// A server older than the dictionary (08–16.10.2026) sends the key only.
  static Color _fallback(BuildContext context, String key) => switch (key) {
        'submitted' => context.dr.accent,
        'not_submitted' => DrColors.red,
        'absent' => DrColors.purple,
        'teacher_missed' => context.dr.textMuted,
        _ => context.dr.accent,
      };

  /// The website's colours are picked for its white page; `#00C31D` lands at
  /// 2.3:1 on the light theme's card. Text needs 4.5:1 (the app's rule — see
  /// `DrPalette.accent`), so a colour too weak for [DrPalette.bgSurface] is
  /// darkened (light theme) or lightened (dark theme) step by step, keeping
  /// its hue; one that already reads is left alone.
  static Color _readable(BuildContext context, Color color) {
    final surface = context.dr.bgSurface;
    var hsl = HSLColor.fromColor(color);
    for (var i = 0; i < 20 && _contrast(hsl.toColor(), surface) < 4.5; i++) {
      final lighter = surface.computeLuminance() < 0.5;
      final l = (hsl.lightness + (lighter ? 0.04 : -0.04)).clamp(0.0, 1.0);
      hsl = hsl.withLightness(l);
    }
    return hsl.toColor();
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }
}
