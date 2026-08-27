part of 'homework_bloc.dart';

enum HomeworkStatus { initial, loading, loaded, error }

/// Which half of the list the tabs show: deadlines still ahead, or behind.
enum HomeworkTab { active, past }

class HomeworkState extends Equatable {
  /// Sentinel for "no subject filter" — also the label of the first pill.
  static const String allSubjects = kAllFilterSentinel;

  final HomeworkStatus status;

  /// Everything the API returned, unfiltered.
  final List<Homework> homeworks;

  final int? classId;
  final String? className;

  final String subject;

  /// Selected tab — the screen opens on [HomeworkTab.active].
  final HomeworkTab tab;

  final String? errorMessage;

  const HomeworkState({
    this.status = HomeworkStatus.initial,
    this.homeworks = const [],
    this.classId,
    this.className,
    this.subject = allSubjects,
    this.tab = HomeworkTab.active,
    this.errorMessage,
  });

  bool get isLoading => status == HomeworkStatus.loading;

  /// The student has no class session, so there is nothing to show.
  bool get hasNoClass => status == HomeworkStatus.loaded && classId == null;

  /// Homeworks of the selected [tab]. A missing deadline counts as active —
  /// nothing has expired yet.
  List<Homework> get tabHomeworks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return homeworks.where((hw) {
      final date = hw.submitDate;
      if (date == null) return tab == HomeworkTab.active;
      final due = DateTime(date.year, date.month, date.day);
      final expired = due.isBefore(today);
      return tab == HomeworkTab.active ? !expired : expired;
    }).toList();
  }

  /// Pill labels: "Hamısı" plus every subject present in the selected tab.
  List<String> get subjects {
    final unique = <String>{
      for (final hw in tabHomeworks)
        if (hw.subject != null) hw.subject!,
    }.toList()..sort();
    return [allSubjects, ...unique];
  }

  /// What the list renders: [tabHomeworks] narrowed by [subject].
  List<Homework> get visibleHomeworks {
    if (subject == allSubjects) return tabHomeworks;
    return tabHomeworks.where((hw) => hw.subject == subject).toList();
  }

  HomeworkState copyWith({
    HomeworkStatus? status,
    List<Homework>? homeworks,
    int? classId,
    String? className,
    String? subject,
    HomeworkTab? tab,
    String? errorMessage,
  }) {
    return HomeworkState(
      status: status ?? this.status,
      homeworks: homeworks ?? this.homeworks,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      tab: tab ?? this.tab,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, homeworks, classId, className, subject, tab, errorMessage];
}
