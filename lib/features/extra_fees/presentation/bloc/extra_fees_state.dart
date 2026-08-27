part of 'extra_fees_bloc.dart';

enum ExtraFeesStatus { initial, loading, loaded, error }

class ExtraFeesState extends Equatable {
  final ExtraFeesStatus status;

  final int? studentId;
  final String? studentName;
  final String? className;

  /// ISO code the amounts are in, e.g. `AZN`.
  final String currency;

  final ExtraFeeSummary summary;
  final List<ExtraFee> fees;
  final List<ExtraFeeChild> children;

  final String? errorMessage;

  const ExtraFeesState({
    this.status = ExtraFeesStatus.initial,
    this.studentId,
    this.studentName,
    this.className,
    this.currency = 'AZN',
    this.summary = const ExtraFeeSummary(),
    this.fees = const [],
    this.children = const [],
    this.errorMessage,
  });

  bool get isLoading => status == ExtraFeesStatus.loading;

  bool get hasData => fees.isNotEmpty;

  /// Nothing was ever billed — a different thing from "all paid", and the two
  /// deserve different words on screen.
  bool get isEmpty => status == ExtraFeesStatus.loaded && fees.isEmpty;

  /// What a parent wants to deal with first: still owing before settled, and
  /// within each group the earliest due date first. Undated fees sort last so
  /// a missing date cannot jump the queue.
  List<ExtraFee> get sortedFees {
    final sorted = [...fees];
    sorted.sort((a, b) {
      if (a.isOutstanding != b.isOutstanding) return a.isOutstanding ? -1 : 1;
      final ad = a.dueDate, bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return sorted;
  }

  List<ExtraFee> get outstandingFees =>
      fees.where((f) => f.isOutstanding).toList();

  /// The fees the server itself says can be paid right now.
  List<ExtraFee> get payableFees =>
      fees.where((f) => f.isPayable && f.isOutstanding).toList();

  /// The badge on the tab: how many fees still need attention.
  int get pendingCount =>
      summary.unpaidCount > 0 ? summary.unpaidCount : outstandingFees.length;

  /// What the "pay everything" button opens on: the server's own outstanding
  /// total, falling back to the sum of the rows when it sends none.
  double get payableAmount {
    if (summary.outstanding > 0) return summary.outstanding;
    return outstandingFees.fold<double>(0, (sum, f) => sum + f.remaining);
  }

  ExtraFeesState copyWith({
    ExtraFeesStatus? status,
    int? studentId,
    String? studentName,
    String? className,
    String? currency,
    ExtraFeeSummary? summary,
    List<ExtraFee>? fees,
    List<ExtraFeeChild>? children,
    String? errorMessage,
  }) {
    return ExtraFeesState(
      status: status ?? this.status,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      currency: currency ?? this.currency,
      summary: summary ?? this.summary,
      fees: fees ?? this.fees,
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
    fees,
    children,
    errorMessage,
  ];
}
