import 'package:equatable/equatable.dart';

/// One row of `transactions.data` from `GET /getBuffetCart` — a single buffet
/// purchase. The sample payload returned an empty page, so the model parses
/// the field names defensively; this entity keeps only what the UI needs.
class BuffetTransaction extends Equatable {
  final int? id;

  /// What was bought (product name / note).
  final String? title;

  /// Amount spent, in AZN. Positive; the UI renders it as a deduction.
  final num? amount;

  final DateTime? date;
  final String? note;

  const BuffetTransaction({
    this.id,
    this.title,
    this.amount,
    this.date,
    this.note,
  });

  @override
  List<Object?> get props => [id, title, amount, date, note];
}
