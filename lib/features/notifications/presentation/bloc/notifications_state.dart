part of 'notifications_bloc.dart';

enum NotificationsStatus { initial, loading, loaded, error }

class NotificationsState extends Equatable {
  final NotificationsStatus status;

  final int? studentId;
  final int? classId;

  /// Every notification the API returned, newest first once sorted.
  final List<NotificationItem> items;

  final String? errorMessage;

  /// The pill picked on the tab; null is "all".
  final NotificationCategory? category;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.studentId,
    this.classId,
    this.items = const [],
    this.errorMessage,
    this.category,
  });

  bool get isLoading => status == NotificationsStatus.loading;

  /// What the list renders: [recentItems] narrowed to [category].
  List<NotificationItem> get visibleItems {
    final picked = category;
    if (picked == null) return recentItems;
    return recentItems.where((item) => item.category == picked).toList();
  }

  /// The same state with another pill picked — [copyWith] cannot clear it
  /// back to "all".
  NotificationsState withCategory(NotificationCategory? category) =>
      NotificationsState(
        status: status,
        studentId: studentId,
        classId: classId,
        items: items,
        errorMessage: errorMessage,
        category: category,
      );

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
      category: category,
    );
  }

  @override
  List<Object?> get props => [
    status,
    studentId,
    classId,
    items,
    errorMessage,
    category,
  ];
}
