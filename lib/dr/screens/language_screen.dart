import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/l10n/locale_controller.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// The first screen of a fresh install: pick a language, then sign in.
///
/// It sits ahead of the login form rather than inside it so the form itself
/// is already in the chosen language — and so the choice is made once, by
/// someone who may not read the language the device happened to be set to.
///
/// Tapping an option applies it immediately: the screen is written in the
/// language being previewed, which is the only honest way to show what the
/// choice does. [LocaleController.confirmChoice] is what actually closes the
/// picker, so a parent can try all three before committing.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  /// Each language named in itself. Deliberately not translated: someone who
  /// only reads Russian has to be able to find "Русский" on a screen that is
  /// currently in Azerbaijani.
  static const _names = <String, String>{
    'az': 'Azərbaycanca',
    'en': 'English',
    'ru': 'Русский',
  };

  @override
  Widget build(BuildContext context) {
    // What the app is rendering right now — the explicit pick once there is
    // one, the device's language until then. Either way it is the row the
    // parent is currently reading, so it is the one that gets the checkmark.
    final selected = LocaleController.instance.locale ??
        Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: context.dr.bgDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Same glowing badge as the login logo, so the first screen
                // already looks like the app it opens.
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.dr.accent.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: context.dr.accent.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'BSB',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: context.dr.accent,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    context.l10n.languagePickTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: context.dr.textMain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    context.l10n.languagePickSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: context.dr.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                for (final locale in LocaleController.supported) ...[
                  _LanguageOption(
                    code: locale.languageCode,
                    name: _names[locale.languageCode] ?? locale.languageCode,
                    selected: locale.languageCode == selected.languageCode,
                    onTap: () =>
                        LocaleController.instance.setLocale(locale),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 20),
                DrPrimaryButton(
                  label: context.l10n.commonContinue,
                  trailingIcon: Icons.arrow_forward_rounded,
                  onTap: () => LocaleController.instance.confirmChoice(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One language: its two-letter code as a badge, its own name, and a tick on
/// the one currently in use.
class _LanguageOption extends StatelessWidget {
  final String code;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.code,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.dr.bgSurface,
          borderRadius: BorderRadius.circular(16),
          // The accent ring marks the live choice, matching how the profile
          // rings the student the app is showing.
          border: Border.all(
            color: selected ? context.dr.accent : context.dr.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? context.dr.accentSoft
                    : context.dr.bgSurfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      selected ? context.dr.accent : context.dr.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: context.dr.textMain,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  size: 22, color: context.dr.accent)
            else
              Icon(Icons.circle_outlined,
                  size: 22, color: context.dr.border),
          ],
        ),
      ),
    );
  }
}
