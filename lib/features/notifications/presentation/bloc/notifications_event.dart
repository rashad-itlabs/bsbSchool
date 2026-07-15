part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the screen.
class NotificationsFetched extends NotificationsEvent {
  const NotificationsFetched();
}

/// Pull-to-refresh / retry after an error.
class NotificationsRefreshed extends NotificationsEvent {
  const NotificationsRefreshed();
}
