import '../../../../core/utils/json_coerce.dart';
import '../../domain/entities/tuition_payment.dart';

class TuitionPaymentModel extends TuitionPayment {
  const TuitionPaymentModel({
    required super.id,
    super.date,
    super.method,
    super.methodLabel,
    super.amount,
    super.status,
    super.statusLabel,
    super.reason,
  });

  /// Matches one entry of the `payments` array.
  factory TuitionPaymentModel.fromJson(Map<String, dynamic> json) =>
      TuitionPaymentModel(
        id: asInt(json['id']),
        date: asDate(json['date']),
        method: asString(json['method']),
        methodLabel: asString(json['method_label']),
        amount: asDouble(json['amount']),
        status: _status(asString(json['status'])),
        statusLabel: asString(json['status_label']),
        reason: asString(json['reason']),
      );

  static TuitionPaymentStatus _status(String? raw) =>
      switch (raw?.toLowerCase()) {
        'paid' => TuitionPaymentStatus.paid,
        'initiated' => TuitionPaymentStatus.initiated,
        'failed' => TuitionPaymentStatus.failed,
        'refunded' => TuitionPaymentStatus.refunded,
        _ => TuitionPaymentStatus.other,
      };
}
