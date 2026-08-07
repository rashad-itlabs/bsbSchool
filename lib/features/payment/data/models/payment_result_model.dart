import '../../domain/entities/payment_result.dart';

class PaymentResultModel extends PaymentResult {
  const PaymentResultModel({
    required super.reference,
    required super.status,
    required super.amount,
    required super.currency,
    required super.message,
    super.balance,
    super.date,
  });

  /// Matches the body of `GET /payment/status`.
  factory PaymentResultModel.fromJson(Map<String, dynamic> json) {
    return PaymentResultModel(
      reference: json['reference']?.toString() ?? '',
      status: _asStatus(json['status']),
      amount: _asDouble(json['amount']) ?? 0,
      currency: json['currency']?.toString() ?? 'AZN',
      balance: _asDouble(json['balance']),
      message: json['message']?.toString() ?? '',
      date: _asDate(json['date']),
    );
  }

  /// The API normalises to `pending | success | failed`; anything unexpected
  /// counts as pending so the app keeps asking instead of claiming a failure.
  static PaymentStatus _asStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  static double? _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().replaceAll(',', '.') ?? '');

  /// `yyyy-MM-dd HH:mm:ss`; a bad value degrades to null.
  static DateTime? _asDate(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }
}
