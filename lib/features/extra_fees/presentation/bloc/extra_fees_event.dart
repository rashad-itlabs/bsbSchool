part of 'extra_fees_bloc.dart';

abstract class ExtraFeesEvent extends Equatable {
  const ExtraFeesEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the tab.
class ExtraFeesFetched extends ExtraFeesEvent {
  const ExtraFeesFetched();
}

/// Pull-to-refresh, retry after an error, or a reload once a payment settled.
class ExtraFeesRefreshed extends ExtraFeesEvent {
  const ExtraFeesRefreshed();
}
