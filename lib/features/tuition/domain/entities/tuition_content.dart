import 'package:equatable/equatable.dart';

import 'tuition_charge.dart';
import 'tuition_child.dart';
import 'tuition_payment.dart';
import 'tuition_summary.dart';

/// The whole `GET /tuition` payload: who it is about, the tallied [summary],
/// the invoiced [charges] and the [payments] made against them.
class TuitionContent extends Equatable {
  final int? studentId;
  final String? studentName;
  final int? classId;
  final String? className;

  /// ISO code the amounts are in, e.g. `AZN`.
  final String currency;

  final TuitionSummary summary;

  /// The payment schedule, in the order the API sent it.
  final List<TuitionCharge> charges;

  /// The payment ledger, including started and failed attempts.
  final List<TuitionPayment> payments;

  /// Every student on the account with their own balance.
  final List<TuitionChild> children;

  const TuitionContent({
    this.studentId,
    this.studentName,
    this.classId,
    this.className,
    this.currency = 'AZN',
    this.summary = const TuitionSummary(),
    this.charges = const [],
    this.payments = const [],
    this.children = const [],
  });

  @override
  List<Object?> get props => [
    studentId,
    studentName,
    classId,
    className,
    currency,
    summary,
    charges,
    payments,
    children,
  ];
}
