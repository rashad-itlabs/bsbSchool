import '../../../../core/utils/json_coerce.dart';
import '../../domain/entities/extra_fee.dart';

class ExtraFeeModel extends ExtraFee {
  const ExtraFeeModel({
    required super.id,
    super.feeId,
    super.title,
    super.description,
    super.dueDate,
    super.classId,
    super.amount,
    super.paid,
    super.remaining,
    super.status,
    super.statusLabel,
    super.isOverdue,
    super.isPayable,
    super.lastPayment,
  });

  /// Matches one entry of the `fees` array.
  factory ExtraFeeModel.fromJson(Map<String, dynamic> json) => ExtraFeeModel(
    id: asInt(json['id']),
    feeId: asIntOrNull(json['fee_id']),
    title: asString(json['title']),
    description: asString(json['description']),
    dueDate: asDate(json['due_date']),
    classId: asIntOrNull(json['class_id']),
    amount: asDouble(json['amount']),
    paid: asDouble(json['paid']),
    remaining: asDouble(json['remaining']),
    status: _status(asString(json['status'])),
    statusLabel: asString(json['status_label']),
    isOverdue: asBool(json['is_overdue']),
    isPayable: asBool(json['is_payable']),
    // Always null so far. A bare date string is read; were it ever to arrive
    // as an object, it degrades to null instead of showing a broken date.
    lastPayment: asDate(json['last_payment']),
  );

  /// An unrecognised status stays [ExtraFeeStatus.other] rather than being
  /// forced into `unpaid`: the UI then shows the server's own label and does
  /// not claim money is owed.
  static ExtraFeeStatus _status(String? raw) => switch (raw?.toLowerCase()) {
    'unpaid' => ExtraFeeStatus.unpaid,
    'partial' => ExtraFeeStatus.partial,
    'paid' => ExtraFeeStatus.paid,
    _ => ExtraFeeStatus.other,
  };
}
