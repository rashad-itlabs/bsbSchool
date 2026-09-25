import '../../../../core/network/api_client.dart';
import '../../domain/entities/feedback_week.dart';
import '../../domain/entities/weekly_feedback.dart';
import '../../domain/entities/weekly_feedback_content.dart';

class WeeklyFeedbackContentModel extends WeeklyFeedbackContent {
  const WeeklyFeedbackContentModel({
    super.ready,
    super.studentId,
    super.studentName,
    super.classId,
    super.className,
    super.totalWeeks,
    super.currentWeek,
    super.selectedWeek,
    super.weeks,
    super.feedback,
  });

  /// Matches the whole weekly feedback body:
  /// `{ "ready": true, "current_week": 2, "selected_week": 2,
  ///    "weeks": [ ... ], "data": [ ... ], ... }`
  factory WeeklyFeedbackContentModel.fromJson(Map<String, dynamic> json) {
    final weeks = _maps(json['weeks'])
        .map(FeedbackWeekModel.fromJson)
        .where((w) => w.week > 0)
        .toList()
      ..sort((a, b) => a.week.compareTo(b.week));

    return WeeklyFeedbackContentModel(
      ready: _asBool(json['ready'], fallback: true),
      studentId: _asInt(json['student_id']),
      studentName: _asString(json['student_name']),
      classId: _asInt(json['class_id']),
      className: _asString(json['class_name']),
      totalWeeks: _asInt(json['total_weeks']) ?? weeks.length,
      currentWeek: _asInt(json['current_week']),
      selectedWeek: _asInt(json['selected_week']),
      weeks: weeks,
      feedback: _maps(json['data']).map(WeeklyFeedbackModel.fromJson).toList(),
    );
  }
}

class FeedbackWeekModel extends FeedbackWeek {
  const FeedbackWeekModel({
    required super.week,
    super.count,
    super.hasFeedback,
    super.isCurrent,
    super.isFuture,
  });

  factory FeedbackWeekModel.fromJson(Map<String, dynamic> json) {
    final count = _asInt(json['count']) ?? 0;
    return FeedbackWeekModel(
      week: _asInt(json['week']) ?? 0,
      count: count,
      hasFeedback: _asBool(json['has_feedback'], fallback: count > 0),
      isCurrent: _asBool(json['is_current']),
      isFuture: _asBool(json['is_future']),
    );
  }
}

class WeeklyFeedbackModel extends WeeklyFeedback {
  const WeeklyFeedbackModel({
    required super.text,
    super.kind,
    super.kindLabel,
    super.teacher,
    super.subjects,
    super.files,
    super.date,
  });

  factory WeeklyFeedbackModel.fromJson(Map<String, dynamic> json) {
    final files = json['files'];
    return WeeklyFeedbackModel(
      kind: _asString(json['kind']),
      kindLabel: _asString(json['kind_label']),
      teacher: _asString(json['teacher']),
      subjects: _asString(json['subjects']),
      text: _asString(json['text']) ?? '',
      files: files is List
          ? files.map(_asAttachment).whereType<FeedbackAttachment>().toList()
          : const [],
      date: DateTime.tryParse(_asString(json['date']) ?? ''),
    );
  }

  /// The files array has only been seen empty, so both shapes a Laravel
  /// endpoint is likely to send are accepted: a bare URL string, or an object
  /// with the URL and a display name under one of the usual keys.
  static FeedbackAttachment? _asAttachment(dynamic value) {
    String? url;
    String? name;
    if (value is String) {
      url = _asString(value);
    } else if (value is Map) {
      url = _asString(value['url'] ??
          value['file'] ??
          value['path'] ??
          value['document'] ??
          value['link']);
      name = _asString(value['original_name'] ??
          value['name'] ??
          value['file_name'] ??
          value['title']);
    }
    if (url == null) return null;

    final absolute = _absoluteUrl(url);
    return FeedbackAttachment(
      name: name ?? _fileNameOf(absolute),
      url: absolute,
    );
  }

  /// A storage path without a host is resolved against the API's own host.
  static String _absoluteUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    final origin = Uri.parse(ApiClient.baseUrl).origin;
    return '$origin/${url.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static String _fileNameOf(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    return segments.isEmpty ? url : Uri.decodeComponent(segments.last);
  }
}

Iterable<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e))
    : const [];

int? _asInt(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

/// The API sends `null` for missing values; empty strings mean the same.
String? _asString(dynamic value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

/// Accepts real booleans and the `1`/`0` / `"true"` forms PHP likes to send.
bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}
