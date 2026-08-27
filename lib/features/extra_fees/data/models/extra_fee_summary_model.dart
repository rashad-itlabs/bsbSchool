import '../../../../core/utils/json_coerce.dart';
import '../../domain/entities/extra_fee_summary.dart';

class ExtraFeeSummaryModel extends ExtraFeeSummary {
  const ExtraFeeSummaryModel({
    super.total,
    super.paid,
    super.outstanding,
    super.unpaidCount,
    super.overdueCount,
  });

  /// Matches the `summary` object of `GET /extra_fees`. The `*_minor` twins are
  /// deliberately ignored — the app displays money, it does not re-derive it.
  factory ExtraFeeSummaryModel.fromJson(Map<String, dynamic> json) =>
      ExtraFeeSummaryModel(
        total: asDouble(json['total']),
        paid: asDouble(json['paid']),
        outstanding: asDouble(json['outstanding']),
        unpaidCount: asInt(json['unpaid_count']),
        overdueCount: asInt(json['overdue_count']),
      );
}
