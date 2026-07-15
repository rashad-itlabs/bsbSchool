import '../../domain/entities/examination_content.dart';
import 'exam_group_model.dart';

class ExaminationContentModel extends ExaminationContent {
  const ExaminationContentModel({
    super.studentId,
    super.groups,
  });

  /// Matches the whole `GET /examinations` body:
  /// `{ "student_id": 3132, "data": [ { group }, ... ] }`
  factory ExaminationContentModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final groups = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => ExamGroupModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ExamGroupModel>[];

    return ExaminationContentModel(
      studentId: _asNullableInt(json['student_id']),
      groups: groups,
    );
  }

  static int? _asNullableInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}
