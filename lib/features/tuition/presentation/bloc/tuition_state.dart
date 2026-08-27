part of 'tuition_bloc.dart';

enum TuitionStatus { initial, loading, loaded, error }

class TuitionState extends Equatable {
  final TuitionStatus status;

  final int? studentId;
  final String? studentName;
  final String? className;

  /// ISO code the amounts are in, e.g. `AZN`.
  final String currency;

  final TuitionSummary summary;
  final List<TuitionCharge> charges;
  final List<TuitionPayment> payments;
  final List<TuitionChild> children;

  final String? errorMessage;

  const TuitionState({
    this.status = TuitionStatus.initial,
    this.studentId,
    this.studentName,
    this.className,
    this.currency = 'AZN',
    this.summary = const TuitionSummary(),
    this.charges = const [],
    this.payments = const [],
    this.children = const [],
    this.errorMessage,
  });

  bool get isLoading => status == TuitionStatus.loading;

  bool get hasData => charges.isNotEmpty || summary.balance > 0;

  /// The schedule in due-date order — dated instalments first, undated ones
  /// last so a missing date cannot push a row to the top.
  List<TuitionCharge> get schedule {
    final sorted = [...charges];
    sorted.sort((a, b) {
      final ad = a.dueDate, bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return sorted;
  }

  /// Tuition instalments only. Anything else the endpoint bills lives on its
  /// own `/extra_fees` tab, so it must not be counted twice here.
  List<TuitionCharge> get tuitionSchedule =>
      schedule.where((c) => c.isTuition).toList();

  int get paidCount => charges.where((c) => c.isPaid).length;

  int get totalCharges => charges.length;

  /// How far through the schedule the account is, as 0..1 for the donut.
  double get progress {
    if (totalCharges == 0) return 0;
    return paidCount / totalCharges;
  }

  /// The instalment the parent is due to pay next: the earliest one still
  /// carrying a balance. Null once everything is settled.
  TuitionCharge? get nextCharge {
    for (final charge in schedule) {
      if (charge.isOutstanding) return charge;
    }
    return null;
  }

  /// True when an instalment is already past its due date.
  bool get hasOverdue => charges.any((c) => c.isOverdue);

  /// The ledger, newest first.
  List<TuitionPayment> get recentPayments {
    final sorted = [...payments];
    sorted.sort((a, b) {
      final ad = a.date, bd = b.date;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return sorted;
  }

  /// What the payment sheet opens on: the server's suggestion, falling back to
  /// the outstanding balance when it has none to offer.
  double get payableAmount {
    if (summary.suggested > 0) return summary.suggested;
    if (summary.dueNow > 0) return summary.dueNow;
    return summary.balance;
  }

  TuitionState copyWith({
    TuitionStatus? status,
    int? studentId,
    String? studentName,
    String? className,
    String? currency,
    TuitionSummary? summary,
    List<TuitionCharge>? charges,
    List<TuitionPayment>? payments,
    List<TuitionChild>? children,
    String? errorMessage,
  }) {
    return TuitionState(
      status: status ?? this.status,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      currency: currency ?? this.currency,
      summary: summary ?? this.summary,
      charges: charges ?? this.charges,
      payments: payments ?? this.payments,
      children: children ?? this.children,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    studentId,
    studentName,
    className,
    currency,
    summary,
    charges,
    payments,
    children,
    errorMessage,
  ];
}
