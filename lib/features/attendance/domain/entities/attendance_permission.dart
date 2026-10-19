import 'package:equatable/equatable.dart';

/// One entry of the `permissions` array in `GET /attendance` (server
/// 19.10.2026): the school excused the child (QƏRAR-107, «İcazəli»).
///
/// It comes from the permission itself, not from the lesson records: since
/// 18.10 the server sends no record for a lesson that has not started yet, so
/// in the morning the records alone cannot say the child is excused today.
class AttendancePermission extends Equatable {
  final int id;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// `day` (the whole day), `leave` (leaves at [time]), `arrive` (arrives at
  /// [time]).
  final String kind;

  /// `HH:mm` for `leave` / `arrive`; null for a whole day.
  final String? time;

  /// The school days it covers (Mon–Fri of the range; the server works them
  /// out, the app does no date maths).
  final List<DateTime> dates;

  /// Ready text — «Şagird bu günə icazəlidir» — in the request language, and
  /// in every app language.
  final String label;
  final Map<String, String> labels;

  const AttendancePermission({
    required this.id,
    this.dateFrom,
    this.dateTo,
    this.kind = 'day',
    this.time,
    this.dates = const [],
    this.label = '',
    this.labels = const {},
  });

  /// The text in [language] (`az` / `en` / `ru`), else the request one.
  String labelFor(String language) => labels[language] ?? label;

  /// Whether [day] (any time of it) is one of [dates].
  bool covers(DateTime day) => dates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day);

  @override
  List<Object?> get props =>
      [id, dateFrom, dateTo, kind, time, dates, label, labels];
}
