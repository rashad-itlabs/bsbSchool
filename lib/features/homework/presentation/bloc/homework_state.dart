part of 'homework_bloc.dart';

enum HomeworkStatus { initial, loading, loaded, error }

/// Which half of the list the tabs show: deadlines still ahead, or behind.
enum HomeworkTab { active, past }

/// One section in the filter sheet: [key] is what a homework is matched by
/// ([HomeworkState.sectionKey]), [label] what the sheet says.
class HomeworkSectionOption extends Equatable {
  final String key;
  final String label;

  const HomeworkSectionOption({required this.key, required this.label});

  @override
  List<Object?> get props => [key, label];
}

class HomeworkState extends Equatable {
  final HomeworkStatus status;

  /// Everything the API returned, unfiltered.
  final List<Homework> homeworks;

  final int? classId;
  final String? className;

  /// The server's status dictionary, in its order (see [statusOptions]).
  final List<HomeworkStatusInfo> statusDictionary;

  /// Sections picked in the filter sheet, by [sectionKey]; empty is "all".
  final Set<String> sections;

  /// Statuses picked in the filter sheet, by server key; empty is "all".
  final Set<String> statuses;

  /// Selected tab — the screen opens on [HomeworkTab.active]. The filters
  /// hold across both tabs.
  final HomeworkTab tab;

  final String? errorMessage;

  const HomeworkState({
    this.status = HomeworkStatus.initial,
    this.homeworks = const [],
    this.classId,
    this.className,
    this.statusDictionary = const [],
    this.sections = const {},
    this.statuses = const {},
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

  /// What a homework is matched by in the section filter: its section, else
  /// its subject; null when it has neither (it then shows only unfiltered).
  static String? sectionKey(Homework hw) {
    for (final value in [hw.section, hw.subject]) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  /// The sections the sheet offers — from both tabs, so the list does not
  /// change under the parent when they switch. A section is called by its
  /// subject: its own name is the auto-name `Mathematics-8C2 <teacher>`.
  /// Two sections of one subject add their teacher to tell them apart.
  List<HomeworkSectionOption> get sectionOptions {
    final byKey = <String, Homework>{};
    for (final hw in homeworks) {
      final key = sectionKey(hw);
      if (key != null) byKey.putIfAbsent(key, () => hw);
    }

    String subjectOf(String key) => byKey[key]!.subject?.trim() ?? key;
    final perSubject = <String, int>{};
    for (final key in byKey.keys) {
      perSubject.update(subjectOf(key), (n) => n + 1, ifAbsent: () => 1);
    }

    final options = [
      for (final MapEntry(:key, value: hw) in byKey.entries)
        HomeworkSectionOption(
          key: key,
          label: perSubject[subjectOf(key)]! > 1 && hw.teacher != null
              ? '${subjectOf(key)} · ${hw.teacher}'
              : subjectOf(key),
        ),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return options;
  }

  /// The statuses the sheet offers: the server's dictionary, all of it, in
  /// its order. A server without one (before 16.10.2026) — the statuses the
  /// homeworks carry, in the same order; none at all hides the group.
  List<HomeworkStatusInfo> get statusOptions {
    if (statusDictionary.isNotEmpty) return statusDictionary;

    const order = [
      'assigned',
      'submitted',
      'not_submitted',
      'teacher_missed',
      'absent',
    ];
    final byKey = <String, HomeworkStatusInfo>{};
    for (final hw in homeworks) {
      final key = hw.status;
      if (key == null || byKey.containsKey(key)) continue;
      byKey[key] = hw.statusInfo ??
          HomeworkStatusInfo(
            code: hw.statusCode ?? 0,
            key: key,
            label: hw.statusLabel ?? key,
          );
    }
    int rank(String key) {
      final i = order.indexOf(key);
      return i < 0 ? order.length : i;
    }

    return byKey.values.toList()
      ..sort((a, b) => rank(a.key).compareTo(rank(b.key)));
  }

  /// [tabHomeworks] narrowed by a pick of sections and statuses; an empty
  /// set lets everything through. The tab's order is kept.
  List<Homework> filtered({
    required Set<String> sections,
    required Set<String> statuses,
  }) {
    return tabHomeworks.where((hw) {
      if (sections.isNotEmpty && !sections.contains(sectionKey(hw))) {
        return false;
      }
      if (statuses.isNotEmpty && !statuses.contains(hw.status)) return false;
      return true;
    }).toList();
  }

  /// What the list renders: [tabHomeworks] narrowed by the applied filters.
  List<Homework> get visibleHomeworks =>
      filtered(sections: sections, statuses: statuses);

  /// How many filters are on — the badge on the filter button.
  int get filterCount => sections.length + statuses.length;

  bool get isFiltered => filterCount > 0;

  /// The same state with these filters applied — [copyWith] cannot empty them.
  HomeworkState withFilters({
    required Set<String> sections,
    required Set<String> statuses,
  }) {
    return HomeworkState(
      status: status,
      homeworks: homeworks,
      classId: classId,
      className: className,
      statusDictionary: statusDictionary,
      sections: Set.unmodifiable(sections),
      statuses: Set.unmodifiable(statuses),
      tab: tab,
      errorMessage: errorMessage,
    );
  }

  HomeworkState copyWith({
    HomeworkStatus? status,
    List<Homework>? homeworks,
    int? classId,
    String? className,
    HomeworkTab? tab,
    String? errorMessage,
  }) {
    return HomeworkState(
      status: status ?? this.status,
      homeworks: homeworks ?? this.homeworks,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      statusDictionary: statusDictionary,
      sections: sections,
      statuses: statuses,
      tab: tab ?? this.tab,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        homeworks,
        classId,
        className,
        statusDictionary,
        sections,
        statuses,
        tab,
        errorMessage,
      ];
}
