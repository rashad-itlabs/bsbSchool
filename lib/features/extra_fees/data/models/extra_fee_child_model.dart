import '../../../../core/utils/json_coerce.dart';
import '../../domain/entities/extra_fee_child.dart';

class ExtraFeeChildModel extends ExtraFeeChild {
  const ExtraFeeChildModel({
    super.studentId,
    super.name,
    super.outstanding,
    super.selected,
  });

  /// Matches one entry of the `children` array.
  factory ExtraFeeChildModel.fromJson(Map<String, dynamic> json) =>
      ExtraFeeChildModel(
        studentId: asIntOrNull(json['student_id']),
        name: asString(json['name']),
        outstanding: asDouble(json['outstanding']),
        selected: asBool(json['selected']),
      );
}
