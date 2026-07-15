import '../../domain/entities/exam_result.dart';

class ExamResultModel extends ExamResult {
  const ExamResultModel({
    required super.id,
    super.subject,
    super.exam,
    super.className,
    super.mark,
    super.grade,
    super.gradePoint,
    super.behaviour,
    super.effort,
    super.note,
    super.absent,
  });

  /// Matches one entry of a group's `results` array:
  /// `{ "id": 66, "subject": "English", "exam": "Formative 1",
  ///    "class": "Class Group 7", "mark": "88.00", "grade": "A",
  ///    "grade_point": 0, "behaviour": null, "effort": null,
  ///    "note": null, "absent": false }`
  factory ExamResultModel.fromJson(Map<String, dynamic> json) =>
      ExamResultModel(
        id: _asInt(json['id']),
        subject: _asString(json['subject']),
        exam: _asString(json['exam']),
        // The server field is `class`; renamed to avoid the Dart keyword.
        className: _asString(json['class']),
        mark: _asString(json['mark']),
        grade: _asString(json['grade']),
        gradePoint: _asNum(json['grade_point']),
        behaviour: _asString(json['behaviour']),
        effort: _asString(json['effort']),
        note: _asString(json['note']),
        absent: json['absent'] == true,
      );

  /// `id` arrives as an int, but a JSON-encoded string is cheap to tolerate.
  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static num? _asNum(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '');

  /// The API sends `null` for missing values; empty strings mean the same.
  /// Numeric marks (`85`) survive as their string form.
  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
