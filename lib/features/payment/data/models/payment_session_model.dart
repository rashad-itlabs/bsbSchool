import '../../domain/entities/payment_session.dart';

class PaymentSessionModel extends PaymentSession {
  const PaymentSessionModel({
    required super.reference,
    required super.amount,
    required super.currency,
    required super.paymentUrl,
    required super.successReturnUrl,
    required super.failReturnUrl,
  });

  /// Matches the body of `POST /payment/topup`.
  ///
  /// Throws [FormatException] when `payment_url` or `reference` is missing —
  /// without either there is nothing to open and nothing to poll, so the
  /// service turns that into a plain error message.
  factory PaymentSessionModel.fromJson(Map<String, dynamic> json) {
    final reference = json['reference']?.toString().trim() ?? '';
    final url = Uri.tryParse(json['payment_url']?.toString().trim() ?? '');

    if (reference.isEmpty || url == null || !url.hasScheme) {
      throw const FormatException('payment_url / reference yoxdur');
    }

    final returns = json['return_urls'];
    final returnMap = returns is Map ? returns : const {};

    return PaymentSessionModel(
      reference: reference,
      amount: _asDouble(json['amount']) ?? 0,
      currency: json['currency']?.toString() ?? 'AZN',
      paymentUrl: url,
      successReturnUrl: returnMap['success']?.toString() ?? '',
      failReturnUrl: returnMap['fail']?.toString() ?? '',
    );
  }

  static double? _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().replaceAll(',', '.') ?? '');
}
