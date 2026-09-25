import 'package:equatable/equatable.dart';

import 'feedback_week.dart';
import 'weekly_feedback.dart';

/// The whole weekly feedback payload: the school-year grid, which week is
/// current and which one was answered, and that week's feedback.
class WeeklyFeedbackContent extends Equatable {
  /// False when the server has no school-year weeks to offer yet.
  final bool ready;

  final int? studentId;
  final String? studentName;
  final int? classId;
  final String? className;

  final int totalWeeks;

  /// The week today falls in, or null outside the school year.
  final int? currentWeek;

  /// The week [feedback] belongs to — the one asked for, or the current one
  /// when none was.
  final int? selectedWeek;

  final List<FeedbackWeek> weeks;

  /// Feedback for [selectedWeek] only.
  final List<WeeklyFeedback> feedback;

  const WeeklyFeedbackContent({
    this.ready = true,
    this.studentId,
    this.studentName,
    this.classId,
    this.className,
    this.totalWeeks = 0,
    this.currentWeek,
    this.selectedWeek,
    this.weeks = const [],
    this.feedback = const [],
  });

  @override
  List<Object?> get props => [
        ready,
        studentId,
        studentName,
        classId,
        className,
        totalWeeks,
        currentWeek,
        selectedWeek,
        weeks,
        feedback,
      ];
}
