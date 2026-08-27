import 'package:equatable/equatable.dart';

/// Where one extra fee stands. Anything the server invents beyond these lands
/// on [other], which the UI renders with the server's own label rather than
/// guessing.
enum ExtraFeeStatus { unpaid, partial, paid, other }

/// One billed extra — a book set, a trip, an exam entry. Unlike a tuition
/// instalment it carries its own title and a per-fee remaining balance, so it
/// can be paid on its own.
class ExtraFee extends Equatable {
  /// Row id of this student's charge.
  final int id;

  /// Id of the fee definition the charge was raised from. Shared by every
  /// student billed for the same thing.
  final int? feeId;

  final String? title;
  final String? description;

  /// When it falls due (`due_date`, `yyyy-MM-dd`).
  final DateTime? dueDate;

  /// The class the fee was raised for — not necessarily the student's current
  /// one, which is why it is kept rather than assumed.
  final int? classId;

  /// What was billed, in major units (AZN).
  final double amount;

  /// How much of [amount] is settled.
  final double paid;

  /// What is still owed on this fee — the amount a per-fee payment starts on.
  final double remaining;

  final ExtraFeeStatus status;

  /// Server-rendered status text, e.g. `Unpaid`.
  final String? statusLabel;

  /// True once the due date has passed with money still owing.
  final bool isOverdue;

  /// The server's own verdict on whether this fee may be paid right now — a
  /// closed or already settled fee comes back false, and the UI hides its
  /// pay button rather than second-guessing why.
  final bool isPayable;

  /// When money last landed on this fee. Only a date string is understood; any
  /// other shape degrades to null rather than guessing.
  final DateTime? lastPayment;

  const ExtraFee({
    required this.id,
    this.feeId,
    this.title,
    this.description,
    this.dueDate,
    this.classId,
    this.amount = 0,
    this.paid = 0,
    this.remaining = 0,
    this.status = ExtraFeeStatus.unpaid,
    this.statusLabel,
    this.isOverdue = false,
    this.isPayable = false,
    this.lastPayment,
  });

  bool get isPaid => status == ExtraFeeStatus.paid;

  /// Money is still owed on it — the flag the lists and totals filter on.
  bool get isOutstanding => remaining > 0;

  /// Part-paid: something landed, but not all of it.
  bool get isPartial =>
      status == ExtraFeeStatus.partial || (paid > 0 && remaining > 0);

  /// Settled share of this fee, as 0..1.
  double get progress {
    if (amount <= 0) return 0;
    return (paid / amount).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    id,
    feeId,
    title,
    description,
    dueDate,
    classId,
    amount,
    paid,
    remaining,
    status,
    statusLabel,
    isOverdue,
    isPayable,
    lastPayment,
  ];
}
