import '../../domain/entities/exam_group.dart';
import 'exam_result_model.dart';

class ExamGroupModel extends ExamGroup {
  const ExamGroupModel({
    super.id,
    super.name,
    super.results,
  });

  /// Matches one entry of the `data` array:
  /// `{ "exam_group_id": null, "group_name": null, "results": [ ... ] }`
  factory ExamGroupModel.fromJson(Map<String, dynamic> json) {
    final raw = json['results'];
    final results = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => ExamResultModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ExamResultModel>[];

    return ExamGroupModel(
      id: _asNullableInt(json['exam_group_id']),
      name: _asNullableString(json['group_name']),
      results: results,
    );
  }

  static int? _asNullableInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  static String? _asNullableString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
