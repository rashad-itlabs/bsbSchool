import 'package:equatable/equatable.dart';

/// The `summary` object of `GET /tuition` — the totals the server has already
/// tallied so the UI never adds money up itself.
///
/// Every field arrives twice: `balance` in major units (AZN) and
/// `balance_minor` in qəpik. The app keeps the major one for display; the minor
/// twin is the one to reach for if an amount ever has to be sent back, since it
/// carries no rounding.
class TuitionSummary extends Equatable {
  /// Everything still owed across the whole schedule.
  final double balance;

  /// The slice of [balance] whose due date has already passed.
  final double dueNow;

  /// Interest accrued on overdue charges.
  final double lateFee;

  /// Overpayment sitting on the account, already netted off [balance].
  final double credit;

  /// What the server proposes as the payment amount — the default the parent
  /// sees on the payment sheet.
  final double suggested;

  const TuitionSummary({
    this.balance = 0,
    this.dueNow = 0,
    this.lateFee = 0,
    this.credit = 0,
    this.suggested = 0,
  });

  /// The debt without the interest on top of it.
  double get principal {
    final value = balance - lateFee;
    return value < 0 ? 0 : value;
  }

  bool get hasLateFee => lateFee > 0;

  bool get isSettled => balance <= 0;

  @override
  List<Object?> get props => [balance, dueNow, lateFee, credit, suggested];
}
