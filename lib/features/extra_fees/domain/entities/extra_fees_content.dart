import 'package:equatable/equatable.dart';

import 'extra_fee.dart';
import 'extra_fee_child.dart';
import 'extra_fee_summary.dart';

/// The whole `GET /extra_fees` payload: who it is about, the tallied [summary]
/// and every extra fee billed to them.
class ExtraFeesContent extends Equatable {
  final int? studentId;
  final String? studentName;
  final int? classId;
  final String? className;

  /// ISO code the amounts are in, e.g. `AZN`.
  final String currency;

  final ExtraFeeSummary summary;

  /// The fees, in the order the API sent them.
  final List<ExtraFee> fees;

  /// Every student on the account with their own outstanding total.
  final List<ExtraFeeChild> children;

  const ExtraFeesContent({
    this.studentId,
    this.studentName,
    this.classId,
    this.className,
    this.currency = 'AZN',
    this.summary = const ExtraFeeSummary(),
    this.fees = const [],
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
    fees,
    children,
  ];
}
