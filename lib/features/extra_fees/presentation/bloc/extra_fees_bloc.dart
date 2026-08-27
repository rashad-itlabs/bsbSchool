import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/extra_fee.dart';
import '../../domain/entities/extra_fee_child.dart';
import '../../domain/entities/extra_fee_summary.dart';
import '../../domain/usecases/get_extra_fees.dart';

part 'extra_fees_event.dart';
part 'extra_fees_state.dart';

class ExtraFeesBloc extends Bloc<ExtraFeesEvent, ExtraFeesState> {
  final GetExtraFees getExtraFees;

  ExtraFeesBloc({required this.getExtraFees}) : super(const ExtraFeesState()) {
    on<ExtraFeesFetched>(_onFetched);
    on<ExtraFeesRefreshed>(_onFetched);
  }

  Future<void> _onFetched(
    ExtraFeesEvent event,
    Emitter<ExtraFeesState> emit,
  ) async {
    // A pull-to-refresh keeps the current list on screen; the first load has
    // nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: ExtraFeesStatus.loading));

    final result = await getExtraFees(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ExtraFeesStatus.error,
          errorMessage: failure.message,
        ),
      ),
      // Built fresh rather than via copyWith so the previous student's fees
      // cannot linger behind a null.
      (content) => emit(
        ExtraFeesState(
          status: ExtraFeesStatus.loaded,
          studentId: content.studentId,
          studentName: content.studentName,
          className: content.className,
          currency: content.currency,
          summary: content.summary,
          fees: content.fees,
          children: content.children,
        ),
      ),
    );
  }
}
