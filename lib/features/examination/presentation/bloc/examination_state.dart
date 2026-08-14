part of 'examination_bloc.dart';

enum ExaminationStatus { initial, loading, loaded, error }

class ExaminationState extends Equatable {
  /// Sentinel for "this filter is off" — also the label of its first chip.
  static const String any = 'Hamısı';

  /// Kept as the subject filter's own name for readability at call sites.
  static const String allSubjects = any;

  final ExaminationStatus status;

  /// Everything the API returned, unfiltered, in server order.
  final List<ExamGroup> groups;

  final int? studentId;

  /// Exam group name (`Autumn Exam`, ...) or [any].
  final String examGroup;

  /// Exam name (`Formative 1`, `Mid Term`, ...) or [any].
  final String exam;

  final String subject;

  final String? errorMessage;

  const ExaminationState({
    this.status = ExaminationStatus.initial,
    this.groups = const [],
    this.studentId,
    this.examGroup = any,
    this.exam = any,
    this.subject = allSubjects,
    this.errorMessage,
  });

  bool get isLoading => status == ExaminationStatus.loading;

  /// The account has no student session, so there is nothing to show.
  bool get hasNoStudent =>
      status == ExaminationStatus.loaded && studentId == null;

  /// Chip labels for the exam group filter, in server order — the API already
  /// lists the groups the way the school orders its terms.
  List<String> get examGroupOptions {
    final unique = <String>{
      for (final g in groups)
        if (g.name != null && g.name!.isNotEmpty) g.name!,
    };
    return [any, ...unique];
  }

  /// Chip labels for the exam filter, narrowed to the selected group so the
  /// sheet never offers an exam that would yield nothing.
  List<String> get examOptions {
    final unique = <String>{
      for (final r in _resultsInSelectedGroups)
        if (r.exam != null && r.exam!.isNotEmpty) r.exam!,
    }.toList()
      ..sort(_byExamOrder);
    return [any, ...unique];
  }

  /// Chip labels for the subject filter, narrowed to the group + exam above.
  List<String> get subjects {
    final unique = <String>{
      for (final r in _resultsInSelectedGroups)
        if (_matchesExam(r) && r.subject != null) r.subject!,
    }.toList()
      ..sort();
    return [allSubjects, ...unique];
  }

  /// How many filters are narrowing the list — drives the "Filtr" badge.
  int get activeFilterCount => [
        examGroup,
        exam,
        subject,
      ].where((v) => v != any).length;

  /// The active filters as `(label, value)` pairs, for the summary chips.
  List<MapEntry<String, String>> get activeFilters => [
        if (examGroup != any) MapEntry('group', examGroup),
        if (exam != any) MapEntry('exam', exam),
        if (subject != allSubjects) MapEntry('subject', subject),
      ];

  /// The groups the list renders, each narrowed to the selected filters.
  /// Groups left with no matching results are dropped.
  List<ExamGroup> get visibleGroups {
    final result = <ExamGroup>[];
    for (final g in groups) {
      if (!_matchesGroup(g)) continue;
      final results =
          g.results.where((r) => _matchesExam(r) && _matchesSubject(r)).toList();
      if (results.isEmpty) continue;
      result.add(ExamGroup(id: g.id, name: g.name, results: results));
    }
    return result;
  }

  /// Number of results the current filters leave — shown on the sheet's button.
  int get visibleResultCount =>
      visibleGroups.fold(0, (sum, g) => sum + g.results.length);

  bool _matchesGroup(ExamGroup g) => examGroup == any || g.name == examGroup;
  bool _matchesExam(ExamResult r) => exam == any || r.exam == exam;
  bool _matchesSubject(ExamResult r) =>
      subject == allSubjects || r.subject == subject;

  /// Every result of the groups the exam-group filter leaves.
  List<ExamResult> get _resultsInSelectedGroups => [
        for (final g in groups)
          if (_matchesGroup(g)) ...g.results,
      ];

  ExaminationState copyWith({
    ExaminationStatus? status,
    List<ExamGroup>? groups,
    int? studentId,
    String? examGroup,
    String? exam,
    String? subject,
    String? errorMessage,
  }) {
    return ExaminationState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      studentId: studentId ?? this.studentId,
      examGroup: examGroup ?? this.examGroup,
      exam: exam ?? this.exam,
      subject: subject ?? this.subject,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, groups, studentId, examGroup, exam, subject, errorMessage];
}

/// The school's exam sequence, so the chips read like the term does instead of
/// alphabetically ("End of Term" first). Names outside the list sort last.
const List<String> _examOrder = [
  'formative 1',
  'mid term',
  'formative 2',
  'end of term',
  'one period',
];

int _byExamOrder(String a, String b) {
  int rank(String name) {
    // `Formative1` and `Formative 1` are the same exam as far as ordering goes.
    final key = name
        .toLowerCase()
        .replaceAllMapped(RegExp(r'([a-z])(\d)'), (m) => '${m[1]} ${m[2]}')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final i = _examOrder.indexOf(key);
    return i == -1 ? _examOrder.length : i;
  }

  final diff = rank(a) - rank(b);
  return diff != 0 ? diff : a.compareTo(b);
}
