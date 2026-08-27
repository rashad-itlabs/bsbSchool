import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// `context.l10n.homeTitle` — the shorthand every widget uses.
extension AppL10nX on BuildContext {
  AppL10n get l10n => AppL10n.of(this);

  /// Filter lists carry a sentinel entry meaning "no filter", stored as a
  /// fixed string so comparisons hold in any language. Only its wording is
  /// translated, and only here.
  String filterLabel(String value) =>
      value == kAllFilterSentinel ? l10n.commonAll : value;
}

/// The "no filter" entry shared by the subject filters. Never shown as-is —
/// see [AppL10nX.filterLabel].
const String kAllFilterSentinel = 'Hamısı';

/// Translations for layers that have no [BuildContext] — services and
/// repositories that produce a message for the user (a failed request, a
/// declined payment).
///
/// The app root keeps [current] in step with the active locale, so a language
/// switch reaches those layers too. Before the first frame, and in unit tests
/// that never build a widget, it falls back to Azerbaijani rather than
/// throwing: a message in the wrong language beats a crash.
class L {
  L._();

  static AppL10n? _current;

  static AppL10n get s => _current ??= lookupAppL10n(_fallback);

  static set current(AppL10n value) => _current = value;

  /// The school's own language. Spelled out here rather than imported from
  /// `LocaleController` so a service does not drag `shared_preferences` in.
  static const _fallback = Locale('az');
}
