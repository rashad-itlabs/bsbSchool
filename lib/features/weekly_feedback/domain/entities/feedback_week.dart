import 'package:equatable/equatable.dart';

/// One cell of the school-year grid: an entry of the endpoint's `weeks` array.
class FeedbackWeek extends Equatable {
  /// 1-based week of the school year (`week`).
  final int week;

  /// How many feedback entries the week has (`count`).
  final int count;

  final bool hasFeedback;
  final bool isCurrent;

  /// A week that hasn't started yet — nothing can have been written for it.
  final bool isFuture;

  /// Whether the parent can open the week: any week that has started, and a
  /// later one too once a teacher has already written for it (the server can
  /// flag a week as future while its report is in).
  bool get isSelectable => !isFuture || hasFeedback;

  const FeedbackWeek({
    required this.week,
    this.count = 0,
    this.hasFeedback = false,
    this.isCurrent = false,
    this.isFuture = false,
  });

  @override
  List<Object?> get props => [week, count, hasFeedback, isCurrent, isFuture];
}
