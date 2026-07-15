import '../../domain/entities/homework.dart';

class HomeworkModel extends Homework {
  const HomeworkModel({
    required super.id,
    required super.name,
    super.description,
    super.subject,
    super.section,
    super.teacher,
    super.homeworkDate,
    super.submitDate,
    super.evaluationDate,
    super.documentUrl,
    super.classId,
    super.subjectId,
  });

  /// Matches one entry of the `data` array returned by `GET /homework`.
  factory HomeworkModel.fromJson(Map<String, dynamic> json) => HomeworkModel(
        id: _asInt(json['id']),
        name: _asString(json['homework_name']) ?? 'Adsız tapşırıq',
        description: _asString(json['description']) ?? '',
        subject: _asString(json['subject']),
        section: _asString(json['section']),
        teacher: _asString(json['teacher']),
        homeworkDate: _asDate(json['homework_date']),
        submitDate: _asDate(json['submit_date']),
        evaluationDate: _asDate(json['evaluation_date']),
        documentUrl: _asString(json['document']),
        classId: _asNullableInt(json['class_id']),
        subjectId: _asNullableInt(json['subject_id']),
      );

  /// `id` arrives as an int, but a JSON-encoded string is cheap to tolerate.
  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _asNullableInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  /// The API sends `null` for missing values; empty strings mean the same.
  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Dates come as `yyyy-MM-dd`; a bad value degrades to null, not a crash.
  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
