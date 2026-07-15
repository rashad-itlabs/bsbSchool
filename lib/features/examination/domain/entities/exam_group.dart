import 'package:equatable/equatable.dart';

import 'exam_result.dart';

/// One entry of the `data` array returned by `GET /examinations`.
///
/// Groups bundle related exams (e.g. a term's assessments). Both identifiers
/// are null for results that don't belong to a named group.
class ExamGroup extends Equatable {
  final int? id;
  final String? name;
  final List<ExamResult> results;

  const ExamGroup({
    this.id,
    this.name,
    this.results = const [],
  });

  @override
  List<Object?> get props => [id, name, results];
}
