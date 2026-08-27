import 'package:equatable/equatable.dart';

/// The `summary` object of `GET /extra_fees` — the totals the server has
/// already tallied across every extra fee billed to the student.
///
/// Amounts are in major units (AZN); the payload's `*_minor` twins carry the
/// same figures in qəpik and are the ones to reach for if an amount ever has
/// to be sent back.
class ExtraFeeSummary extends Equatable {
  /// Everything ever billed as an extra fee.
  final double total;

  /// How much of [total] has been settled.
  final double paid;

  /// What is still owed.
  final double outstanding;

  /// How many fees still carry a balance.
  final int unpaidCount;

  /// How many of those are already past their due date.
  final int overdueCount;

  const ExtraFeeSummary({
    this.total = 0,
    this.paid = 0,
    this.outstanding = 0,
    this.unpaidCount = 0,
    this.overdueCount = 0,
  });

  bool get hasOutstanding => outstanding > 0;

  bool get hasOverdue => overdueCount > 0;

  /// Settled share of [total], as 0..1 for a progress ring. Clamped because a
  /// refund can leave `paid` above `total` for a moment.
  double get progress {
    if (total <= 0) return 0;
    return (paid / total).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    total,
    paid,
    outstanding,
    unpaidCount,
    overdueCount,
  ];
}
