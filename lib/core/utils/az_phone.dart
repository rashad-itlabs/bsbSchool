import 'package:flutter/services.dart';

/// Azerbaijani phone numbers, as the app shows and sends them.
///
/// One national format everywhere — `+994 50 123 45 67` — so the country code
/// is never something to type or remember, and whatever the parent enters (or
/// the database already holds: `0501234567`, `994501234567`, a number with
/// brackets) reaches the backend in the same shape.
class AzPhone {
  AzPhone._();

  static const String countryCode = '994';

  /// What a focused but still empty field shows, before the first digit.
  static const String prefix = '+$countryCode ';

  /// Operator code (2) + subscriber number (7).
  static const int nationalLength = 9;

  /// How the national part is grouped: `50 123 45 67`.
  static const List<int> _groups = [2, 3, 2, 2];

  /// The national digits of [raw], whatever shape it arrived in. Everything
  /// that isn't a digit is dropped, then the trunk zero and the country code
  /// with it — `0501234567`, `+994 50 123 45 67` and `00994501234567` all
  /// come back as `501234567`.
  ///
  /// Anything past [nationalLength] is cut: a pasted number with a stray
  /// digit is better trimmed than silently mangled.
  static String digitsOf(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    // `00` international prefix, or the trunk `0` of a local number.
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.startsWith(countryCode)) {
      digits = digits.substring(countryCode.length);
      // `+994 050 ...` — typed by someone covering both bases.
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }
    return digits.length <= nationalLength
        ? digits
        : digits.substring(0, nationalLength);
  }

  /// `+994 50 123 45 67` — what the field shows while it is being typed.
  ///
  /// Empty in, empty out: the prefix appears with the first digit and goes
  /// away with the last, so a parent who wants no phone at all can clear the
  /// field completely.
  static String format(String raw) {
    final digits = digitsOf(raw);
    if (digits.isEmpty) return '';

    final buffer = StringBuffer('+$countryCode');
    var index = 0;
    for (final size in _groups) {
      if (index >= digits.length) break;
      final end = (index + size).clamp(0, digits.length);
      buffer.write(' ${digits.substring(index, end)}');
      index = end;
    }
    return buffer.toString();
  }

  /// `+994501234567` — the one shape the backend is ever sent. Empty when no
  /// digits were entered, which is how an optional phone is cleared.
  static String e164(String raw) {
    final digits = digitsOf(raw);
    return digits.isEmpty ? '' : '+$countryCode$digits';
  }

  static bool isEmpty(String raw) => digitsOf(raw).isEmpty;

  /// True once every digit is in. An empty field is not complete — callers
  /// that allow no phone at all check [isEmpty] first.
  static bool isComplete(String raw) => digitsOf(raw).length == nationalLength;
}

/// Keeps a phone field in [AzPhone.format] as it is typed: digits go in, the
/// `+994` and the spacing appear on their own.
///
/// The caret is held at the end rather than tracked through the inserted
/// spaces — a phone number is typed and corrected from its end, and the
/// alternative is an offset that drifts every time a group closes.
class AzPhoneInputFormatter extends TextInputFormatter {
  const AzPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = AzPhone.format(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
