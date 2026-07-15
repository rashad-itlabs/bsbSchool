part of 'timetable_bloc.dart';

enum TimetableStatus { initial, loading, loaded, error }

/// A weekday tab: its ISO number, its display name, and the lessons on it.
class TimetableTab extends Equatable {
  final int dayOfWeek;
  final String name;
  final List<TimetableLesson> lessons;

  const TimetableTab({
    required this.dayOfWeek,
    required this.name,
    this.lessons = const [],
  });

  @override
  List<Object?> get props => [dayOfWeek, name, lessons];
}

class TimetableState extends Equatable {
  /// Fallback names for the five weekday tabs, used when the API returns no
  /// row for a day (so the tab still shows with an empty schedule).
  static const _fallbackNames = {
    1: 'Bazar ertəsi',
    2: 'Çərşənbə axşamı',
    3: 'Çərşənbə',
    4: 'Cümə axşamı',
    5: 'Cümə',
  };

  final TimetableStatus status;

  final int? classId;
  final String? className;

  /// The days the API returned (only those with lessons are present).
  final List<TimetableDay> days;

  /// The selected weekday tab: 1 (Mon) … 5 (Fri).
  final int selectedDay;

  final String? errorMessage;

  const TimetableState({
    this.status = TimetableStatus.initial,
    this.classId,
    this.className,
    this.days = const [],
    this.selectedDay = 1,
    this.errorMessage,
  });

  bool get isLoading => status == TimetableStatus.loading;

  /// The student has no class session, so there is nothing to show.
  bool get hasNoClass => status == TimetableStatus.loaded && classId == null;

  /// Always five tabs (Mon–Fri), each carrying that day's lessons. Names prefer
  /// the server's [TimetableDay.dayName], falling back to a static label.
  List<TimetableTab> get tabs {
    return [
      for (var d = 1; d <= 5; d++)
        TimetableTab(
          dayOfWeek: d,
          name: _nameFor(d),
          lessons: _lessonsFor(d),
        ),
    ];
  }

  /// Lessons for the currently selected tab.
  List<TimetableLesson> get selectedLessons => _lessonsFor(selectedDay);

  String _nameFor(int dayOfWeek) {
    for (final day in days) {
      if (day.dayOfWeek == dayOfWeek && day.dayName.isNotEmpty) {
        return day.dayName;
      }
    }
    return _fallbackNames[dayOfWeek] ?? '';
  }

  List<TimetableLesson> _lessonsFor(int dayOfWeek) {
    for (final day in days) {
      if (day.dayOfWeek == dayOfWeek) return day.lessons;
    }
    return const [];
  }

  TimetableState copyWith({
    TimetableStatus? status,
    int? classId,
    String? className,
    List<TimetableDay>? days,
    int? selectedDay,
    String? errorMessage,
  }) {
    return TimetableState(
      status: status ?? this.status,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      days: days ?? this.days,
      selectedDay: selectedDay ?? this.selectedDay,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, classId, className, days, selectedDay, errorMessage];
}
