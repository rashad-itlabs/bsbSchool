part of 'tuition_bloc.dart';

abstract class TuitionEvent extends Equatable {
  const TuitionEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the screen.
class TuitionFetched extends TuitionEvent {
  const TuitionFetched();
}

/// Pull-to-refresh, retry after an error, or a reload once a payment settled.
class TuitionRefreshed extends TuitionEvent {
  const TuitionRefreshed();
}
