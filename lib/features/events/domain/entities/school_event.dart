import 'package:equatable/equatable.dart';

/// Title and text of a calendar entry in one language.
class SchoolEventText extends Equatable {
  final String title;
  final String description;

  const SchoolEventText({this.title = '', this.description = ''});

  @override
  List<Object?> get props => [title, description];
}

/// One entry of the `data` array returned by `GET /getEvent` — a single item on
/// the school calendar (term dates, holidays, assessments, celebrations).
class SchoolEvent extends Equatable {
  final int id;

  /// In the language the request was made in (`lang`).
  final String title;

  /// Free text under the title; the panel allows newlines in it.
  final String description;

  /// Every language the backend sent (`az`, `en`, `ru`), keyed by language
  /// code. The backend already fills a missing translation with the English
  /// text (the panel's base language for events). Kept so a language switch
  /// re-renders the entry without reloading it; empty when talking to a
  /// backend that predates it.
  final Map<String, SchoolEventText> translations;

  /// `HH:mm` as configured in the panel; null when the entry carries no time.
  final String? time;

  /// Category colour as a `#rrggbb` string. Kept raw so the domain layer stays
  /// framework-free — the presentation layer turns it into a `Color`.
  final String? colorHex;

  /// The day the event starts, normalised to midnight.
  final DateTime? date;

  /// Last day of a multi-day event; null when it lasts a single day.
  final DateTime? endDate;

  /// Set when the event only concerns one class; null for whole-school ones.
  final int? classId;

  const SchoolEvent({
    required this.id,
    this.title = '',
    this.description = '',
    this.translations = const {},
    this.time,
    this.colorHex,
    this.date,
    this.endDate,
    this.classId,
  });

  /// [title] in [languageCode]; falls back to the request language.
  String titleIn(String languageCode) {
    final text = translations[languageCode]?.title ?? '';
    return text.isEmpty ? title : text;
  }

  /// [description] in [languageCode]; falls back to the request language.
  String descriptionIn(String languageCode) {
    final text = translations[languageCode]?.description ?? '';
    return text.isEmpty ? description : text;
  }

  /// The last day the event covers. An absent [endDate] — or one that precedes
  /// [date], which the panel does allow — collapses to a single-day event.
  DateTime? get lastDay {
    final start = date;
    if (start == null) return null;
    final end = endDate;
    return (end == null || end.isBefore(start)) ? start : end;
  }

  bool get isMultiDay {
    final start = date;
    final last = lastDay;
    return start != null && last != null && last.isAfter(start);
  }

  /// Whether [day] falls inside the event's range, ends included.
  bool covers(DateTime day) {
    final start = date;
    final last = lastDay;
    if (start == null || last == null) return false;

    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
        !d.isAfter(DateTime(last.year, last.month, last.day));
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        translations,
        time,
        colorHex,
        date,
        endDate,
        classId,
      ];
}
