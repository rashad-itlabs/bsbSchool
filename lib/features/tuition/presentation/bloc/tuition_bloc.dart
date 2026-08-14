import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/tuition_charge.dart';
import '../../domain/entities/tuition_child.dart';
import '../../domain/entities/tuition_payment.dart';
import '../../domain/entities/tuition_summary.dart';
import '../../domain/usecases/get_tuition.dart';

part 'tuition_event.dart';
part 'tuition_state.dart';

class TuitionBloc extends Bloc<TuitionEvent, TuitionState> {
  final GetTuition getTuition;

  TuitionBloc({required this.getTuition}) : super(const TuitionState()) {
    on<TuitionFetched>(_onFetched);
    on<TuitionRefreshed>(_onFetched);
  }

  Future<void> _onFetched(
    TuitionEvent event,
    Emitter<TuitionState> emit,
  ) async {
    // A pull-to-refresh keeps the current schedule on screen; the first load
    // has nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: TuitionStatus.loading));

    final result = await getTuition(const NoParams());

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TuitionStatus.error,
          errorMessage: failure.message,
        ),
      ),
      // Built fresh rather than via copyWith so the previous student's numbers
      // cannot linger behind a null.
      (content) => emit(
        TuitionState(
          status: TuitionStatus.loaded,
          studentId: content.studentId,
          studentName: content.studentName,
          className: content.className,
          currency: content.currency,
          summary: content.summary,
          charges: content.charges,
          payments: content.payments,
          children: content.children,
        ),
      ),
    );
  }
}
