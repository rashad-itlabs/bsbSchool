part of 'events_bloc.dart';

abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the calendar.
class EventsFetched extends EventsEvent {
  const EventsFetched();
}

/// Retry after an error / manual reload.
class EventsRefreshed extends EventsEvent {
  const EventsRefreshed();
}
