import '../../../../core/utils/json_coerce.dart';
import '../../domain/entities/tuition_charge.dart';

class TuitionChargeModel extends TuitionCharge {
  const TuitionChargeModel({
    required super.id,
    super.dueDate,
    super.type,
    super.typeLabel,
    super.amount,
    super.status,
    super.statusLabel,
    super.isOverdue,
  });

  /// Matches one entry of the `charges` array.
  factory TuitionChargeModel.fromJson(Map<String, dynamic> json) =>
      TuitionChargeModel(
        id: asInt(json['id']),
        dueDate: asDate(json['due_date']),
        type: asString(json['type']),
        typeLabel: asString(json['type_label']),
        amount: asDouble(json['amount']),
        status: _status(asString(json['status'])),
        statusLabel: asString(json['status_label']),
        isOverdue: asBool(json['is_overdue']),
      );

  /// An unrecognised status stays [TuitionChargeStatus.other] rather than being
  /// forced into `open`: the UI then shows the server's own label and does not
  /// claim the instalment is unpaid.
  static TuitionChargeStatus _status(String? raw) =>
      switch (raw?.toLowerCase()) {
        'open' => TuitionChargeStatus.open,
        'partial' => TuitionChargeStatus.partial,
        'paid' => TuitionChargeStatus.paid,
        _ => TuitionChargeStatus.other,
      };
}
