import '../../domain/entities/tuition_child.dart';
import 'tuition_json.dart';

class TuitionChildModel extends TuitionChild {
  const TuitionChildModel({
    super.studentId,
    super.name,
    super.balance,
    super.selected,
  });

  /// Matches one entry of the `children` array.
  factory TuitionChildModel.fromJson(Map<String, dynamic> json) =>
      TuitionChildModel(
        studentId: asIntOrNull(json['student_id']),
        name: asString(json['name']),
        balance: asDouble(json['balance']),
        selected: asBool(json['selected']),
      );
}
