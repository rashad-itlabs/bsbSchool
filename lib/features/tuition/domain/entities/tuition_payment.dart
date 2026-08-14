import 'package:equatable/equatable.dart';

/// How a payment attempt ended. `initiated` is a checkout the parent started
/// but never finished, so it is neither money in nor a failure.
enum TuitionPaymentStatus { paid, initiated, failed, refunded, other }

/// One entry of the payment ledger — an attempt to pay, whatever came of it.
class TuitionPayment extends Equatable {
  final int id;

  /// When the attempt was made (`date`, `yyyy-MM-dd HH:mm:ss`).
  final DateTime? date;

  /// Machine name of the channel, e.g. `online_card`.
  final String? method;

  /// Server-rendered name of [method], e.g. `Ecom - Card`.
  final String? methodLabel;

  /// Amount in major units (AZN).
  final double amount;

  final TuitionPaymentStatus status;

  /// Server-rendered status text, e.g. `Refunded`.
  final String? statusLabel;

  /// Why it ended this way — the bank's decline text, or `Approved` on a
  /// refund. Null on a clean payment.
  final String? reason;

  const TuitionPayment({
    required this.id,
    this.date,
    this.method,
    this.methodLabel,
    this.amount = 0,
    this.status = TuitionPaymentStatus.other,
    this.statusLabel,
    this.reason,
  });

  bool get isPaid => status == TuitionPaymentStatus.paid;

  /// Only a settled payment moved money; started and failed ones did not.
  bool get affectedBalance =>
      status == TuitionPaymentStatus.paid ||
      status == TuitionPaymentStatus.refunded;

  @override
  List<Object?> get props => [
    id,
    date,
    method,
    methodLabel,
    amount,
    status,
    statusLabel,
    reason,
  ];
}
