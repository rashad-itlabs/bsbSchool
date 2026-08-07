part of 'events_bloc.dart';

enum EventsStatus { initial, loading, loaded, error }

class EventsState extends Equatable {
  final EventsStatus status;

  /// Every calendar entry of the school year, in the order the API returned
  /// them. The calendar groups them by day itself.
  final List<SchoolEvent> events;

  final String? errorMessage;

  const EventsState({
    this.status = EventsStatus.initial,
    this.events = const [],
    this.errorMessage,
  });

  bool get isLoading => status == EventsStatus.loading;

  /// True only once a load finished and came back empty — an in-flight first
  /// load must not be mistaken for "no events".
  bool get isEmpty => status == EventsStatus.loaded && events.isEmpty;

  /// True while the very first load is still in flight, i.e. there is nothing
  /// to show yet.
  bool get isInitialLoading => isLoading && events.isEmpty;

  EventsState copyWith({
    EventsStatus? status,
    List<SchoolEvent>? events,
    String? errorMessage,
  }) {
    return EventsState(
      status: status ?? this.status,
      events: events ?? this.events,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, errorMessage];
}
