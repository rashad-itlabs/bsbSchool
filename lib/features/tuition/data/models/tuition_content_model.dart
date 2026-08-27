import '../../../../core/utils/json_coerce.dart';
import '../../domain/entities/tuition_content.dart';
import 'tuition_charge_model.dart';
import 'tuition_child_model.dart';
import 'tuition_payment_model.dart';
import 'tuition_summary_model.dart';

class TuitionContentModel extends TuitionContent {
  const TuitionContentModel({
    super.studentId,
    super.studentName,
    super.classId,
    super.className,
    super.currency,
    super.summary,
    super.charges,
    super.payments,
    super.children,
  });

  /// Matches the whole `GET /tuition` body:
  /// `{ "student_id": 2570, "currency": "AZN", "summary": { ... },
  ///    "charges": [ ... ], "payments": [ ... ], "children": [ ... ] }`
  factory TuitionContentModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];

    return TuitionContentModel(
      studentId: asIntOrNull(json['student_id']),
      studentName: asString(json['student_name']),
      classId: asIntOrNull(json['class_id']),
      className: asString(json['class_name']),
      currency: asString(json['currency']) ?? 'AZN',
      summary: summary is Map
          ? TuitionSummaryModel.fromJson(Map<String, dynamic>.from(summary))
          : const TuitionSummaryModel(),
      charges: asList(json['charges'], TuitionChargeModel.fromJson),
      payments: asList(json['payments'], TuitionPaymentModel.fromJson),
      children: asList(json['children'], TuitionChildModel.fromJson),
    );
  }
}
