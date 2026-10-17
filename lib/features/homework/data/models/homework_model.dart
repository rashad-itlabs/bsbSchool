import '../../domain/entities/homework.dart';
import '../../domain/entities/homework_status_info.dart';
import '../../domain/entities/homework_submission.dart';

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
    super.createdAt,
    super.archiveAt,
    super.documentUrl,
    super.classId,
    super.subjectId,
    super.submission,
    super.status,
    super.statusCode,
    super.statusLabel,
    super.statusInfo,
  });

  /// Matches one entry of the `data` array returned by `GET /homework`.
  /// [statuses] — the response's `statuses` dictionary by code
  /// (`HomeworkContentModel` reads it); this entry's one is attached.
  factory HomeworkModel.fromJson(
    Map<String, dynamic> json, {
    Map<int, HomeworkStatusInfo> statuses = const {},
  }) {
    final code = _asNullableInt(json['status_code']);
    return HomeworkModel(
      id: _asInt(json['id']),
      name: _asString(json['homework_name']) ?? 'Adsız tapşırıq',
      description: _asString(json['description']) ?? '',
      subject: _asString(json['subject']),
      section: _asString(json['section']),
      teacher: _asString(json['teacher']),
      homeworkDate: _asDate(json['homework_date']),
      submitDate: _asDate(json['submit_date']),
      evaluationDate: _asDate(json['evaluation_date']),
      createdAt: _asDate(json['created_at']),
      archiveAt: _asDate(json['archive_at']),
      documentUrl: _asString(json['document']),
      classId: _asNullableInt(json['class_id']),
      subjectId: _asNullableInt(json['subject_id']),
      submission: _asSubmission(json['submission']),
      status: _asString(json['status']),
      statusCode: code,
      statusLabel: _asString(json['status_label']),
      statusInfo: code == null ? null : statuses[code],
    );
  }

  /// One entry of the `statuses` dictionary; null when it has no usable code.
  static HomeworkStatusInfo? statusInfoFromJson(dynamic value) {
    if (value is! Map) return null;
    final code = _asNullableInt(value['code']);
    final key = _asString(value['key']);
    if (code == null || key == null) return null;
    return HomeworkStatusInfo(
      code: code,
      key: key,
      label: _asString(value['label']) ?? key,
      labels: _asTexts(value['labels']),
      color: _asColor(value['color']),
      hint: _asString(value['hint']),
      hints: _asTexts(value['hints']),
    );
  }

  /// `{"az": "...", "en": "...", "ru": null}` → the non-empty ones.
  static Map<String, String> _asTexts(dynamic value) {
    if (value is! Map) return const {};
    return {
      for (final e in value.entries)
        if (_asString(e.value) != null) e.key.toString(): _asString(e.value)!,
    };
  }

  /// `#RRGGBB` → opaque ARGB; anything else → null.
  static int? _asColor(dynamic value) {
    final text = _asString(value);
    if (text == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(text)) {
      return null;
    }
    return 0xFF000000 | int.parse(text.substring(1), radix: 16);
  }

  /// `submission` is `null` until the work is handed in, then an object.
  static HomeworkSubmission? _asSubmission(dynamic value) {
    if (value is! Map) return null;
    return HomeworkSubmission(
      markedAt: _asDate(value['marked_at']),
      notes: _asString(value['notes']),
      documentUrl: _asString(value['document']),
      originalName: _asString(value['original_name']),
      grade: _asString(value['grade']),
      teacherComment: _asString(value['teacher_comment']),
    );
  }

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

  /// Dates come as `yyyy-MM-dd` (`marked_at` and `created_at` add
  /// ` HH:mm:ss`, read as school wall-clock time; `archive_at` is ISO 8601
  /// with the `+04:00` offset, so it is a real instant); a bad value degrades
  /// to null, not a crash.
  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
