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
  ///
  /// The past tab reads newest deadline first: what just closed is what the
  /// parent comes looking for, not what ran out months ago. The active tab
  /// keeps the order the API sent.
  List<Homework> get tabHomeworks {
    final now = DateTime.now();
    final inTab = homeworks.where((hw) {
      final expired = isExpired(hw, now);
      return tab == HomeworkTab.active ? !expired : expired;
    }).toList();

    return tab == HomeworkTab.past ? _newestFirst(inTab) : inTab;
  }

  /// Whether [hw] belongs to the inactive tab at [now].
  ///
  /// The server's `archive_at` (deadline day, 08:00 school time — the same
  /// moment the website archives it) decides, compared with the actual clock.
  /// A server without that field (before 13.10.2026) falls back to the old
  /// rule: inactive from the day after the deadline. No deadline at all
  /// stays active.
  static bool isExpired(Homework hw, DateTime now) {
    final archiveAt = hw.archiveAt;
    if (archiveAt != null) return !now.isBefore(archiveAt);

    final date = hw.submitDate;
    if (date == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).isBefore(today);
  }

  /// Latest deadline first — the date the card shows. On the same deadline
  /// the more recently assigned one leads, and anything still level keeps
  /// the API's order: `List.sort` is not stable, so that is spelled out.
  static List<Homework> _newestFirst(List<Homework> list) {
    final sorted = list.indexed.toList()
      ..sort((a, b) {
        final byDue = _compareNewestFirst(a.$2.submitDate, b.$2.submitDate);
        if (byDue != 0) return byDue;
        final byAssigned =
            _compareNewestFirst(a.$2.homeworkDate, b.$2.homeworkDate);
        if (byAssigned != 0) return byAssigned;
        return a.$1.compareTo(b.$1);
      });
    return [for (final (_, hw) in sorted) hw];
  }

  /// Later dates first; a missing date sorts after every known one.
  static int _compareNewestFirst(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      if (a == b) return 0;
      return a == null ? 1 : -1;
    }
    return b.compareTo(a);
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
