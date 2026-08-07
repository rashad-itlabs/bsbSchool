import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/school_event.dart';
import '../../domain/usecases/get_events.dart';

part 'events_event.dart';
part 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final GetEvents getEvents;

  EventsBloc({required this.getEvents}) : super(const EventsState()) {
    on<EventsFetched>(_onFetched);
    on<EventsRefreshed>(_onFetched);
  }

  Future<void> _onFetched(EventsEvent event, Emitter<EventsState> emit) async {
    // A retry keeps the calendar on screen while it reloads; the first load has
    // nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: EventsStatus.loading));

    final result = await getEvents(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: EventsStatus.error,
        errorMessage: failure.message,
      )),
      // Built fresh rather than via copyWith so an emptied calendar actually
      // clears the previous entries.
      (events) => emit(EventsState(
        status: EventsStatus.loaded,
        events: events,
      )),
    );
  }
}
