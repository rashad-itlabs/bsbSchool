import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/day_plan.dart';
import '../../domain/usecases/get_weekly_plan.dart';

part 'weekly_plan_state.dart';

class WeeklyPlanCubit extends Cubit<WeeklyPlanState> {
  final GetWeeklyPlan getWeeklyPlan;

  WeeklyPlanCubit({required this.getWeeklyPlan})
      : super(const WeeklyPlanState());

  Future<void> loadPlan() async {
    emit(state.copyWith(status: WeeklyPlanStatus.loading));
    final result = await getWeeklyPlan(const NoParams());
    result.fold(
      (f) => emit(
          state.copyWith(status: WeeklyPlanStatus.error, message: f.message)),
      (days) =>
          emit(state.copyWith(status: WeeklyPlanStatus.loaded, days: days)),
    );
  }
}
