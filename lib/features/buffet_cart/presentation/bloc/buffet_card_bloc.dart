import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/buffet_card.dart';
import '../../domain/entities/buffet_transaction.dart';
import '../../domain/usecases/get_buffet_card.dart';

part 'buffet_card_event.dart';
part 'buffet_card_state.dart';

class BuffetCardBloc extends Bloc<BuffetCardEvent, BuffetCardState> {
  final GetBuffetCard getBuffetCard;

  BuffetCardBloc({required this.getBuffetCard})
      : super(const BuffetCardState()) {
    on<BuffetCardFetched>(_onFetched);
    on<BuffetCardRefreshed>(_onFetched);
  }

  Future<void> _onFetched(
    BuffetCardEvent event,
    Emitter<BuffetCardState> emit,
  ) async {
    // A pull-to-refresh keeps the current card on screen; the first load has
    // nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: BuffetCardStatus.loading));

    final result = await getBuffetCard(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: BuffetCardStatus.error,
        errorMessage: failure.message,
      )),
      // Built fresh rather than via copyWith so a now-null card actually
      // clears the previous one.
      (content) => emit(BuffetCardState(
        status: BuffetCardStatus.loaded,
        userId: content.userId,
        card: content.card,
        transactions: content.transactions,
      )),
    );
  }
}
