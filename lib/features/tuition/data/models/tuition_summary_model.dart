import '../../../../core/utils/json_coerce.dart';
import '../../domain/entities/tuition_summary.dart';

class TuitionSummaryModel extends TuitionSummary {
  const TuitionSummaryModel({
    super.balance,
    super.dueNow,
    super.lateFee,
    super.credit,
    super.suggested,
  });

  /// Matches the `summary` object of `GET /tuition`. The `*_minor` twins are
  /// deliberately ignored — the app displays money, it does not re-derive it.
  factory TuitionSummaryModel.fromJson(Map<String, dynamic> json) =>
      TuitionSummaryModel(
        balance: asDouble(json['balance']),
        dueNow: asDouble(json['due_now']),
        lateFee: asDouble(json['late_fee']),
        credit: asDouble(json['credit']),
        suggested: asDouble(json['suggested']),
      );
}
