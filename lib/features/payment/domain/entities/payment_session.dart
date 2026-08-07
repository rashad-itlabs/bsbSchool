import 'package:equatable/equatable.dart';

/// One checkout attempt, as minted by `POST /payment/topup`.
///
/// The gateway link is per-order and signed on the server, so the app never
/// builds it: it opens [paymentUrl] and watches for the browser to come back to
/// [successReturnUrl] / [failReturnUrl]. Those two are only a *signal* that the
/// bank is done — the real outcome is always re-read from `/payment/status`
/// with [reference].
class PaymentSession extends Equatable {
  /// `MOB-<uuid>`; identifies the transaction in every later call.
  final String reference;

  /// Requested top-up in AZN, echoed back by the API.
  final double amount;

  final String currency;

  /// The bank's hosted checkout page.
  final Uri paymentUrl;

  /// Where the bank sends the browser when the card form is done. The gateway
  /// appends the reference (and sometimes its own query), so these are matched
  /// as prefixes, never compared for equality.
  final String successReturnUrl;
  final String failReturnUrl;

  const PaymentSession({
    required this.reference,
    required this.amount,
    required this.currency,
    required this.paymentUrl,
    required this.successReturnUrl,
    required this.failReturnUrl,
  });

  @override
  List<Object?> get props => [
        reference,
        amount,
        currency,
        paymentUrl,
        successReturnUrl,
        failReturnUrl,
      ];
}
