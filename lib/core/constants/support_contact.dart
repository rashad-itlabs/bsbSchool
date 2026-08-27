import '../l10n/l10n.dart';

/// Where the "contact support" action sends the user.
///
/// TODO: replace the three placeholders below with the school's real support
/// details before release — they are the only values that need changing.
class SupportContact {
  const SupportContact._();

  /// Dialled as-is. Keep the international form.
  static const String phone = '+994 12 000 00 00';

  static const String email = 'support@bsb.edu.az';

  /// Opened through wa.me, so any formatting here is stripped to digits.
  static const String whatsapp = '+994 50 000 00 00';

  /// Prefills the mail composer so support knows where the message came from.
  /// A getter, not a field: it is translated, so it is read at send time.
  static String get emailSubject => L.s.supportEmailSubject;

  /// The leading '+' is kept — dialers need it to place an international call.
  static Uri get phoneUri =>
      Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));

  static Uri get emailUri => Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=${Uri.encodeComponent(emailSubject)}',
      );

  /// A plain https link: it opens the WhatsApp app when installed and falls
  /// back to the browser when it isn't, so no custom URL scheme is involved.
  static Uri get whatsappUri =>
      Uri.parse('https://wa.me/${_digits(whatsapp)}');

  /// wa.me and tel: want bare digits — no spaces, dashes or leading '+'.
  static String _digits(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');
}
