import 'package:equatable/equatable.dart';

/// Where a transaction stands according to the gateway, as reported by
/// `GET /payment/status`.
enum PaymentStatus {
  /// The gateway has not settled it yet — worth asking again in a moment.
  pending,

  /// Paid, and the buffet balance has been credited (server side, once).
  success,

  /// Declined, cancelled or expired.
  failed,
}

/// The settled outcome of one [PaymentStatus] check.
class PaymentResult extends Equatable {
  final String reference;
  final PaymentStatus status;

  /// Transaction amount in AZN.
  final double amount;
  final String currency;

  /// Buffet balance in AZN *after* settlement; null when the API omitted it.
  final double? balance;

  /// Ready-to-show message from the API, already in Azerbaijani.
  final String message;

  final DateTime? date;

  const PaymentResult({
    required this.reference,
    required this.status,
    required this.amount,
    required this.currency,
    required this.message,
    this.balance,
    this.date,
  });

  bool get isPending => status == PaymentStatus.pending;
  bool get isSuccess => status == PaymentStatus.success;
  bool get isFailed => status == PaymentStatus.failed;

  @override
  List<Object?> get props => [
        reference,
        status,
        amount,
        currency,
        balance,
        message,
        date,
      ];
}
