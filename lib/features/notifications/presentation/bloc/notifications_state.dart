part of 'notifications_bloc.dart';

enum NotificationsStatus { initial, loading, loaded, error }

class NotificationsState extends Equatable {
  final NotificationsStatus status;

  final int? studentId;
  final int? classId;

  /// Every notification the API returned, newest first once sorted.
  final List<NotificationItem> items;

  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.studentId,
    this.classId,
    this.items = const [],
    this.errorMessage,
  });

  bool get isLoading => status == NotificationsStatus.loading;

  /// Items sorted newest first for the feed.
  List<NotificationItem> get recentItems {
    final sorted = [...items];
    sorted.sort((a, b) {
      final ad = a.date, bd = b.date;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return sorted;
  }

  NotificationsState copyWith({
    NotificationsStatus? status,
    int? studentId,
    int? classId,
    List<NotificationItem>? items,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      items: items ?? this.items,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, studentId, classId, items, errorMessage];
}
