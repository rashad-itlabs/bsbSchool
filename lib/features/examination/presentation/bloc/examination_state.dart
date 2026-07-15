part of 'examination_bloc.dart';

enum ExaminationStatus { initial, loading, loaded, error }

class ExaminationState extends Equatable {
  /// Sentinel for "no subject filter" — also the label of the first pill.
  static const String allSubjects = 'Hamısı';

  final ExaminationStatus status;

  /// Everything the API returned, unfiltered, in server order.
  final List<ExamGroup> groups;

  final int? studentId;

  final String subject;

  final String? errorMessage;

  const ExaminationState({
    this.status = ExaminationStatus.initial,
    this.groups = const [],
    this.studentId,
    this.subject = allSubjects,
    this.errorMessage,
  });

  bool get isLoading => status == ExaminationStatus.loading;

  /// The account has no student session, so there is nothing to show.
  bool get hasNoStudent =>
      status == ExaminationStatus.loaded && studentId == null;

  /// Every result across every group, flattened.
  List<ExamResult> get _allResults =>
      [for (final g in groups) ...g.results];

  /// Pill labels: "Hamısı" plus every subject present in the results.
  List<String> get subjects {
    final unique = <String>{
      for (final r in _allResults)
        if (r.subject != null) r.subject!,
    }.toList()..sort();
    return [allSubjects, ...unique];
  }

  /// The groups the list renders, each narrowed to the selected [subject].
  /// Groups left with no matching results are dropped.
  List<ExamGroup> get visibleGroups {
    if (subject == allSubjects) return groups;
    return [
      for (final g in groups)
        if (g.results.any((r) => r.subject == subject))
          ExamGroup(
            id: g.id,
            name: g.name,
            results:
                g.results.where((r) => r.subject == subject).toList(),
          ),
    ];
  }

  /// True once loaded with nothing to show for the current filter.
  bool get isEmpty =>
      status == ExaminationStatus.loaded &&
      visibleGroups.every((g) => g.results.isEmpty);

  ExaminationState copyWith({
    ExaminationStatus? status,
    List<ExamGroup>? groups,
    int? studentId,
    String? subject,
    String? errorMessage,
  }) {
    return ExaminationState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      studentId: studentId ?? this.studentId,
      subject: subject ?? this.subject,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, groups, studentId, subject, errorMessage];
}
