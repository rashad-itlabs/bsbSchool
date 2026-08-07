part of 'payment_cubit.dart';

enum PaymentStage {
  /// Nothing in flight.
  idle,

  /// Asking the server for a checkout link.
  starting,

  /// The bank page is open; the app is only waiting.
  atBank,

  /// The bank page closed and the outcome is being read from the API.
  checking,

  /// A settled (or still pending) [PaymentResult] is in [PaymentState.result].
  done,
}

class PaymentState extends Equatable {
  final PaymentStage stage;

  /// The attempt in flight, kept so a retry can re-check the same reference.
  final PaymentSession? session;

  /// Outcome of the last status check.
  final PaymentResult? result;

  /// Why the last step failed; null when nothing went wrong.
  final String? errorMessage;

  const PaymentState({
    this.stage = PaymentStage.idle,
    this.session,
    this.result,
    this.errorMessage,
  });

  /// True while the parent should not be able to start a second top-up.
  bool get isBusy =>
      stage == PaymentStage.starting || stage == PaymentStage.checking;

  @override
  List<Object?> get props => [stage, session, result, errorMessage];
}
