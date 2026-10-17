import 'package:equatable/equatable.dart';

/// One entry of the `statuses` dictionary in `GET /homework` (server
/// 16.10.2026, `HomeworkStatuses` on the backend): what a homework status is
/// called and painted. The website owns the words — it renamed «Принято» to
/// «Выполнено» on 16.10 — so the app shows these instead of its own.
///
/// Codes (`data[].status_code`): 4 assigned, 1 submitted («done»),
/// 3 not_submitted («not done»), 5 teacher_missed, 6 absent.
class HomeworkStatusInfo extends Equatable {
  final int code;

  /// Stable key: `assigned`, `submitted`, `not_submitted`, `teacher_missed`,
  /// `absent`.
  final String key;

  /// The label in the language the request asked for (`?lang=`).
  final String label;

  /// The label in every app language (`az`, `en`, `ru`), so switching the app
  /// language needs no reload.
  final Map<String, String> labels;

  /// ARGB, from the server's `#RRGGBB`; null when it sent none or a bad one.
  final int? color;

  /// A longer explanation (only `teacher_missed` has one), request language
  /// and every language.
  final String? hint;
  final Map<String, String> hints;

  const HomeworkStatusInfo({
    required this.code,
    required this.key,
    required this.label,
    this.labels = const {},
    this.color,
    this.hint,
    this.hints = const {},
  });

  /// The label in [language] (`az` / `en` / `ru`), else the request one.
  String labelFor(String language) => labels[language] ?? label;

  String? hintFor(String language) => hints[language] ?? hint;

  @override
  List<Object?> get props => [code, key, label, labels, color, hint, hints];
}
