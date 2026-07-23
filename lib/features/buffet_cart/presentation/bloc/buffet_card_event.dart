part of 'buffet_card_bloc.dart';

abstract class BuffetCardEvent extends Equatable {
  const BuffetCardEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the screen.
class BuffetCardFetched extends BuffetCardEvent {
  const BuffetCardFetched();
}

/// Pull-to-refresh / retry after an error.
class BuffetCardRefreshed extends BuffetCardEvent {
  const BuffetCardRefreshed();
}
