part of 'weekly_plan_cubit.dart';

enum WeeklyPlanStatus { initial, loading, loaded, error }

class WeeklyPlanState extends Equatable {
  final WeeklyPlanStatus status;
  final List<DayPlan> days;
  final String? message;

  const WeeklyPlanState({
    this.status = WeeklyPlanStatus.initial,
    this.days = const [],
    this.message,
  });

  WeeklyPlanState copyWith({
    WeeklyPlanStatus? status,
    List<DayPlan>? days,
    String? message,
  }) =>
      WeeklyPlanState(
        status: status ?? this.status,
        days: days ?? this.days,
        message: message,
      );

  @override
  List<Object?> get props => [status, days, message];
}
