import 'package:equatable/equatable.dart';

/// One row of `incoming` from `GET /getBuffetCart` — money the parent loaded
/// onto the card, as opposed to a purchase, which is a `transactions` row.
///
/// The gateway's own answer travels along as [receipt]; it is what a parent
/// needs when a payment has to be traced with the bank.
class BuffetTopUp extends Equatable {
  /// What the money was for, in the API's words ("Balans artımı").
  final String? purpose;

  /// Amount credited, in AZN. Positive; the UI renders it as an addition.
  final num? amount;

  /// When the balance was credited.
  final DateTime? date;

  /// The gateway's receipt, or null when the row carried no usable payload.
  final TopUpReceipt? receipt;

  const BuffetTopUp({this.purpose, this.amount, this.date, this.receipt});

  @override
  List<Object?> get props => [purpose, amount, date, receipt];
}

/// The payment gateway's receipt, parsed out of the `payload` JSON string an
/// `incoming` row carries.
///
/// Every field is optional on purpose: the payload is the bank's, not ours, and
/// its shape has already changed once (the `extra` block differs between the
/// app's and the web site's payments). A missing field drops its row from the
/// receipt rather than failing the parse.
class TopUpReceipt extends Equatable {
  /// Our own order number, e.g. `MOB-1dc5a89f-…` (app) or `WEB-…` (web site).
  final String? reference;

  /// The bank's retrieval reference number, and the approval code printed on a
  /// terminal slip — the two numbers a bank asks for when tracing a payment.
  final String? rrn;
  final String? approval;

  /// Masked card number, `424242******0017`.
  final String? pan;

  /// Issuing bank, card scheme and how it was paid.
  final String? issuer;
  final String? system;
  final String? method;

  final num? amount;
  final num? fee;
  final String? currency;

  /// `"00"` and `0` mean success; [message] is the gateway's own wording.
  final String? status;
  final int? code;
  final String? message;

  /// When the gateway settled it, which can differ from the credit time.
  final DateTime? datetime;

  const TopUpReceipt({
    this.reference,
    this.rrn,
    this.approval,
    this.pan,
    this.issuer,
    this.system,
    this.method,
    this.amount,
    this.fee,
    this.currency,
    this.status,
    this.code,
    this.message,
    this.datetime,
  });

  /// True when the gateway reported the payment as taken.
  bool get isSuccess => code == 0 || status == '00';

  /// False when the payload held nothing worth showing — an empty or
  /// unparseable block still parses, it just has nothing in it.
  bool get hasDetails =>
      reference != null ||
      rrn != null ||
      approval != null ||
      pan != null ||
      issuer != null ||
      message != null ||
      datetime != null;

  @override
  List<Object?> get props => [
        reference,
        rrn,
        approval,
        pan,
        issuer,
        system,
        method,
        amount,
        fee,
        currency,
        status,
        code,
        message,
        datetime,
      ];
}
