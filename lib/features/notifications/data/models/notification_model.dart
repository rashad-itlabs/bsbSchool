import '../../domain/entities/notification_item.dart';

class NotificationModel extends NotificationItem {
  const NotificationModel({
    required super.id,
    super.sendType,
    super.title,
    super.message,
    super.className,
    super.sender,
    super.file,
    super.date,
  });

  /// Matches one entry of the `data` array returned by `GET /notifications`.
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: _asInt(json['id']),
        sendType: _asString(json['send_type']) ?? 'student',
        title: _asString(json['title']) ?? '',
        message: _asString(json['message']) ?? '',
        className: _asString(json['class_name']),
        sender: _asString(json['sender']),
        file: _asString(json['file']),
        date: _asDate(json['date']),
      );

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  /// The API sends `null` for missing values; empty strings mean the same.
  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Dates come as ISO-8601 (`2026-07-11T10:38:44.000000Z`); a bad value
  /// degrades to null, not a crash.
  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
