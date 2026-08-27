import 'package:equatable/equatable.dart';

/// Where one scheduled instalment stands. Anything the server invents beyond
/// these lands on [other], which the UI renders with the server's own label
/// rather than guessing.
enum TuitionChargeStatus { open, partial, paid, other }

/// One row of the payment schedule — an instalment the school has invoiced.
class TuitionCharge extends Equatable {
  final int id;

  /// When the instalment falls due (`due_date`, `yyyy-MM-dd`).
  final DateTime? dueDate;

  /// Machine name of the charge kind, e.g. `tuition`.
  final String? type;

  /// Server-rendered name of [type], e.g. `Tuition`.
  final String? typeLabel;

  /// Instalment amount in major units (AZN).
  final double amount;

  final TuitionChargeStatus status;

  /// Server-rendered status text, e.g. `Partly paid`.
  final String? statusLabel;

  /// True once the due date has passed with the charge still open.
  final bool isOverdue;

  const TuitionCharge({
    required this.id,
    this.dueDate,
    this.type,
    this.typeLabel,
    this.amount = 0,
    this.status = TuitionChargeStatus.open,
    this.statusLabel,
    this.isOverdue = false,
  });

  bool get isPaid => status == TuitionChargeStatus.paid;

  /// True for an instalment of the tuition schedule itself. Anything the API
  /// tags with another [type] — books, trips, exam entries — is an extra fee.
  /// A missing type stays with tuition: that is the schedule's own default.
  bool get isTuition => type == null || type!.toLowerCase() == 'tuition';

  /// Partly paid still counts as outstanding — there is money left on it.
  bool get isOutstanding => !isPaid;

  @override
  List<Object?> get props => [
    id,
    dueDate,
    type,
    typeLabel,
    amount,
    status,
    statusLabel,
    isOverdue,
  ];
}
