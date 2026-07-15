part of 'homework_bloc.dart';

enum HomeworkStatus { initial, loading, loaded, error }

class HomeworkState extends Equatable {
  /// Sentinel for "no subject filter" — also the label of the first pill.
  static const String allSubjects = 'Hamısı';

  final HomeworkStatus status;

  /// Everything the API returned, unfiltered.
  final List<Homework> homeworks;

  final int? classId;
  final String? className;

  final String subject;

  final String? errorMessage;

  const HomeworkState({
    this.status = HomeworkStatus.initial,
    this.homeworks = const [],
    this.classId,
    this.className,
    this.subject = allSubjects,
    this.errorMessage,
  });

  bool get isLoading => status == HomeworkStatus.loading;

  /// The student has no class session, so there is nothing to show.
  bool get hasNoClass => status == HomeworkStatus.loaded && classId == null;

  /// Pill labels: "Hamısı" plus every subject present in [homeworks].
  List<String> get subjects {
    final unique = <String>{
      for (final hw in homeworks)
        if (hw.subject != null) hw.subject!,
    }.toList()..sort();
    return [allSubjects, ...unique];
  }

  /// What the list renders: [homeworks] narrowed by [subject].
  List<Homework> get visibleHomeworks {
    if (subject == allSubjects) return homeworks;
    return homeworks.where((hw) => hw.subject == subject).toList();
  }

  HomeworkState copyWith({
    HomeworkStatus? status,
    List<Homework>? homeworks,
    int? classId,
    String? className,
    String? subject,
    String? errorMessage,
  }) {
    return HomeworkState(
      status: status ?? this.status,
      homeworks: homeworks ?? this.homeworks,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, homeworks, classId, className, subject, errorMessage];
}
