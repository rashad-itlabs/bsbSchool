import '../../../../core/utils/json_coerce.dart';
import '../../domain/entities/extra_fees_content.dart';
import 'extra_fee_child_model.dart';
import 'extra_fee_model.dart';
import 'extra_fee_summary_model.dart';

class ExtraFeesContentModel extends ExtraFeesContent {
  const ExtraFeesContentModel({
    super.studentId,
    super.studentName,
    super.classId,
    super.className,
    super.currency,
    super.summary,
    super.fees,
    super.children,
  });

  /// Matches the whole `GET /extra_fees` body:
  /// `{ "student_id": 2570, "currency": "AZN", "summary": { ... },
  ///    "fees": [ ... ], "children": [ ... ] }`
  factory ExtraFeesContentModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];

    return ExtraFeesContentModel(
      studentId: asIntOrNull(json['student_id']),
      studentName: asString(json['student_name']),
      classId: asIntOrNull(json['class_id']),
      className: asString(json['class_name']),
      currency: asString(json['currency']) ?? 'AZN',
      summary: summary is Map
          ? ExtraFeeSummaryModel.fromJson(Map<String, dynamic>.from(summary))
          : const ExtraFeeSummaryModel(),
      fees: asList(json['fees'], ExtraFeeModel.fromJson),
      children: asList(json['children'], ExtraFeeChildModel.fromJson),
    );
  }
}
