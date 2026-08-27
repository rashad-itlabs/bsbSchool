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

  /// "Sentyabr" / "September" / "сентябрь"
  static String month(BuildContext context, int month) =>
      DateFormat.MMMM(_tag(context)).format(DateTime(2024, month));

  /// "Sentyabr 2026"
  static String monthYear(BuildContext context, DateTime date) =>
      DateFormat.yMMMM(_tag(context)).format(date);

  /// "5 sentyabr"
  static String dayMonth(BuildContext context, DateTime date) =>
      DateFormat.MMMMd(_tag(context)).format(date);

  /// "5 sentyabr 2026"
  static String full(BuildContext context, DateTime date) =>
      DateFormat.yMMMMd(_tag(context)).format(date);

  /// "5 sen 2026" — the compact form used in list rows.
  static String short(BuildContext context, DateTime date) =>
      DateFormat.yMMMd(_tag(context)).format(date);

  /// "5 sen 2026, 13:42"
  static String shortWithTime(BuildContext context, DateTime date) =>
      DateFormat.yMMMd(_tag(context)).add_Hm().format(date);

  /// "Bazar ertəsi" / "Monday" / "понедельник". 1 = Monday.
  static String weekday(BuildContext context, int weekday) =>
      DateFormat.EEEE(_tag(context)).format(DateTime(2024, 1, weekday));

  /// Two-letter weekday head for calendar strips. 1 = Monday, matching
  /// [DateTime.weekday]; 1 January 2024 was a Monday, which is what anchors it.
  static String weekdayShort(BuildContext context, int weekday) =>
      DateFormat.E(_tag(context)).format(DateTime(2024, 1, weekday));
}
