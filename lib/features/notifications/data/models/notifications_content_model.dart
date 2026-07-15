import '../../domain/entities/notifications_content.dart';
import 'notification_model.dart';

class NotificationsContentModel extends NotificationsContent {
  const NotificationsContentModel({
    super.studentId,
    super.classId,
    super.items,
  });

  /// Matches the whole `GET /notifications` body:
  /// `{ "student_id": 3132, "class_id": 94, "data": [ ... ] }`
  factory NotificationsContentModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <NotificationModel>[];

    return NotificationsContentModel(
      studentId: _asInt(json['student_id']),
      classId: _asInt(json['class_id']),
      items: items,
    );
  }

  static int? _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}
