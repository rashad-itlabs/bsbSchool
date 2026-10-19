import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Date wording that follows the app's language.
///
/// Month and weekday names come from ICU's own data rather than lists kept in
/// the app: three screens used to carry their own copy of the twelve months,
/// and none of them could have followed a language switch.
class AppDates {
  AppDates._();

  static String _tag(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  /// "sentyabr" / "September" / "сентябрь" — as the language writes it
  /// inside a sentence, so lower case in az and ru.
  static String month(BuildContext context, int month) =>
      DateFormat.MMMM(_tag(context)).format(DateTime(2024, month));

  /// "Sentyabr" / "September" / "Сентябрь" — [month] as a heading, capitalised
  /// in every language.
  static String monthTitle(BuildContext context, int month) =>
      _capitalized(context, AppDates.month(context, month));

  /// "Sentyabr 2026" — the heading of a month calendar, capitalised in every
  /// language (ICU writes az and ru month names in lower case).
  static String monthYear(BuildContext context, DateTime date) =>
      _capitalized(context, DateFormat.yMMMM(_tag(context)).format(date));

  /// "5 sentyabr"
  static String dayMonth(BuildContext context, DateTime date) =>
      DateFormat.MMMMd(_tag(context)).format(date);

  /// "5 sentyabr 2026"
  static String full(BuildContext context, DateTime date) =>
      DateFormat.yMMMMd(_tag(context)).format(date);

  /// A span of days, the month said once where it can be: "17–20 oktyabr",
  /// "30 sentyabr – 2 oktyabr", "October 17–20"; the years too when they
  /// differ; one day alone — [dayMonth].
  static String dayRange(BuildContext context, DateTime from, DateTime to) =>
      dayRangeIn(_tag(context), from, to);

  /// [dayRange] for a language tag, without a [BuildContext].
  static String dayRangeIn(String tag, DateTime from, DateTime to) {
    final dayMonth = DateFormat.MMMMd(tag);
    if (from.year != to.year) {
      final full = DateFormat.yMMMMd(tag);
      return '${full.format(from)} – ${full.format(to)}';
    }
    if (from.month != to.month) {
      return '${dayMonth.format(from)} – ${dayMonth.format(to)}';
    }
    if (from.day == to.day) return dayMonth.format(from);
    // Same month: its name once, where the language puts it — after the
    // day in az and ru («17–20 oktyabr»), before it in en («October 17–20»).
    final month = DateFormat.MMMM(tag).format(from);
    final monthFirst = dayMonth.format(from).startsWith(month);
    return monthFirst
        ? '$month ${from.day}–${to.day}'
        : '${from.day}–${dayMonth.format(to)}';
  }

  /// "5 sen 2026" — the compact form used in list rows.
  static String short(BuildContext context, DateTime date) =>
      DateFormat.yMMMd(_tag(context)).format(date);

  /// "5 sen 2026, 13:42"
  static String shortWithTime(BuildContext context, DateTime date) =>
      DateFormat.yMMMd(_tag(context)).add_Hm().format(date);

  /// "Bazar ertəsi" / "Monday" / "понедельник". 1 = Monday.
  static String weekday(BuildContext context, int weekday) =>
      DateFormat.EEEE(_tag(context)).format(DateTime(2024, 1, weekday));

  /// Upper-cases the first letter. Azerbaijani (like Turkish) pairs `i` with
  /// dotted `İ`, which Dart's locale-blind [String.toUpperCase] doesn't know:
  /// it would turn "iyun" into "Iyun".
  static String _capitalized(BuildContext context, String text) {
    if (text.isEmpty) return text;
    final first = text[0];
    final language = Localizations.localeOf(context).languageCode;
    final upper = first == 'i' && (language == 'az' || language == 'tr')
        ? 'İ'
        : first.toUpperCase();
    return '$upper${text.substring(1)}';
  }

  /// Two-letter weekday head for calendar strips. 1 = Monday, matching
  /// [DateTime.weekday]; 1 January 2024 was a Monday, which is what anchors it.
  static String weekdayShort(BuildContext context, int weekday) =>
      DateFormat.E(_tag(context)).format(DateTime(2024, 1, weekday));
}
