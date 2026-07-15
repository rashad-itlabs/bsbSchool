import 'package:equatable/equatable.dart';

import 'exam_group.dart';
import 'exam_result.dart';

/// The full `GET /examinations` payload: the student the results belong to plus
/// the exam groups scoped to them. [studentId] is null when the account has no
/// active student session yet.
class ExaminationContent extends Equatable {
  final int? studentId;
  final List<ExamGroup> groups;

  const ExaminationContent({
    this.studentId,
    this.groups = const [],
  });

  /// Every result across every group, in server order — handy for the flat
  /// list and the subject filter.
  List<ExamResult> get allResults =>
      [for (final g in groups) ...g.results];

  @override
  List<Object?> get props => [studentId, groups];
}
