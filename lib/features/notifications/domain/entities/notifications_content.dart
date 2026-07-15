import 'package:equatable/equatable.dart';

import 'notification_item.dart';

/// The full `GET /notifications` payload: the student and class the feed is
/// scoped to, plus the per-message [items]. Both ids are null when the student
/// has no session yet.
class NotificationsContent extends Equatable {
  final int? studentId;
  final int? classId;
  final List<NotificationItem> items;

  const NotificationsContent({
    this.studentId,
    this.classId,
    this.items = const [],
  });

  @override
  List<Object?> get props => [studentId, classId, items];
}
