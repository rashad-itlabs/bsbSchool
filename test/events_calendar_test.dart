import 'package:bsbschool/features/events/data/models/school_event_model.dart';
import 'package:bsbschool/features/events/presentation/widgets/events_calendar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bsbschool/dr/theme/dr_colors.dart';
import 'package:bsbschool/core/l10n/l10n.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A slice of the real `GET /getEvent` payload.
const _payload = [
  {
    "id": 17,
    "title": "Staff returns",
    "description": null,
    "event_time": "10:00",
    "color": "#25a194",
    "event_date": "2026-09-01",
    "end_date": null,
    "class_id": null,
  },
  {
    "id": 25,
    "title": "Students arrive and autumn term begins",
    "description": "2025-2026 Awards' Ceremony (whole school)\nOrientation day",
    "event_time": "10:00",
    "color": "#dc3545",
    "event_date": "2026-09-08",
    "end_date": null,
    "class_id": null,
  },
  {
    "id": 22,
    "title": "Students arrive and autumn term begins",
    "description": null,
    "event_time": "10:00",
    "color": "#fd7e14",
    "event_date": "2026-09-08",
    "end_date": null,
    "class_id": null,
  },
  {
    "id": 69,
    "title": "Black January (public holiday)",
    "description": null,
    "event_time": "10:00",
    "color": "#000000",
    "event_date": "2027-01-20",
    "end_date": null,
    "class_id": null,
  },
  // Multi-day, to exercise the range expansion.
  {
    "id": 999,
    "title": "Mid-term break",
    "description": null,
    "event_time": null,
    "color": "#0d6efd",
    "event_date": "2026-09-21",
    "end_date": "2026-09-24",
    "class_id": null,
  },
  // Starts in August, ends in September: belongs to both months' lists.
  {
    "id": 1000,
    "title": "Summer camp",
    "description": null,
    "event_time": null,
    "color": "#198754",
    "event_date": "2026-08-28",
    "end_date": "2026-09-02",
    "class_id": null,
  },
];

/// One busy day: a long, translated entry plus six more, so the "+N" shows.
const _longTitleAz =
    'Valideyn-müəllim görüşü və ilin sonu mükafatlandırma mərasimi (bütün məktəb, akt zalı)';
const _longTitleEn =
    'Parent-teacher meeting and end-of-year awards ceremony (whole school, assembly hall)';
const _busyPayload = [
  {
    "id": 501,
    "title": _longTitleEn,
    "description": "Doors open 09:00\nParents please bring ID",
    "translations": {
      "az": {"title": _longTitleAz, "description": "Qapılar 09:00-da açılır\nValideynlər şəxsiyyət vəsiqəsi gətirsin"},
      "en": {"title": _longTitleEn, "description": "Doors open 09:00\nParents please bring ID"},
      "ru": {"title": "Родительское собрание", "description": "Двери открываются в 09:00"},
    },
    "event_time": "09:30",
    "color": "#0d6efd",
    "event_date": "2026-11-04",
    "end_date": "2026-11-06",
    "class_id": null,
  },
  {"id": 502, "title": "Second", "event_time": "10:00", "color": "#198754", "event_date": "2026-11-04"},
  {"id": 503, "title": "Third", "event_time": "11:00", "color": "#fd7e14", "event_date": "2026-11-04"},
  {"id": 504, "title": "Fourth", "event_time": "12:00", "color": "#6f42c1", "event_date": "2026-11-04"},
  {"id": 505, "title": "Fifth", "event_time": "13:00", "color": "#d63384", "event_date": "2026-11-04"},
  {"id": 506, "title": "Sixth", "event_time": "14:00", "color": "#25a194", "event_date": "2026-11-04"},
  {"id": 507, "title": "Seventh", "event_time": "15:00", "color": "#6c757d", "event_date": "2026-11-04"},
];

Widget _host(Widget child, {String locale = 'az'}) => MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: const [DrPalette.dark],
      ),
      // The widgets under test read their copy from AppL10n, so the delegates
      // have to be in the tree the same way the real app installs them.
      locale: Locale(locale),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

/// The calendar words its months and weekday heads through `intl`, so the
/// expectations are built the same way rather than hard-coded — otherwise the
/// test pins one language's spelling.
String _month(int month) =>
    DateFormat.MMMM('az').format(DateTime(2024, month));
String _weekdayHead(int weekday) =>
    DateFormat.E('az').format(DateTime(2024, 1, weekday));
String _dayMonth(DateTime date) => DateFormat.MMMMd('az').format(date);

/// The header writes the month as a heading (`AppDates.monthTitle`): capitalised,
/// with az's dotted `İ` for "iyun"/"iyul".
String _monthTitle(int month) {
  final m = _month(month);
  return (m.startsWith('i') ? 'İ' : m[0].toUpperCase()) + m.substring(1);
}

/// Steps the calendar from the current month to [year]-[month] with the arrows,
/// in whichever direction that lies — the tests must not depend on today.
Future<void> _goTo(WidgetTester tester, int year, int month) async {
  final now = DateTime.now();
  final diff = (year - now.year) * 12 + (month - now.month);
  final arrow = find.byIcon(
    diff > 0 ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
  );
  for (var i = 0; i < diff.abs(); i++) {
    await tester.tap(arrow);
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(initializeDateFormatting);

  final events = _payload
      .map((e) => SchoolEventModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();

  test('model parses the real payload', () {
    final e = events.first;
    expect(e.id, 17);
    expect(e.title, 'Staff returns');
    expect(e.description, '');
    expect(e.time, '10:00');
    expect(e.colorHex, '#25a194');
    expect(e.date, DateTime(2026, 9, 1));
    expect(e.endDate, isNull);
    expect(e.lastDay, DateTime(2026, 9, 1));
    expect(e.isMultiDay, isFalse);
  });

  test('multi-day event covers its whole range, ends included', () {
    final range = events.firstWhere((e) => e.id == 999);
    expect(range.isMultiDay, isTrue);
    expect(range.covers(DateTime(2026, 9, 20)), isFalse);
    expect(range.covers(DateTime(2026, 9, 21)), isTrue);
    expect(range.covers(DateTime(2026, 9, 23)), isTrue);
    expect(range.covers(DateTime(2026, 9, 24)), isTrue);
    expect(range.covers(DateTime(2026, 9, 25)), isFalse);
  });

  testWidgets('eventColor parses hex and resolves against the theme',
      (tester) async {
    late BuildContext darkCtx;
    await tester.pumpWidget(_host(Builder(builder: (c) {
      darkCtx = c;
      return const SizedBox();
    })));

    expect(eventColor(darkCtx, '#25a194'), const Color(0xFF25A194));
    expect(eventColor(darkCtx, '#fd7e14'), const Color(0xFFFD7E14));
    // Pure black would vanish on the dark palette.
    expect(eventColor(darkCtx, '#000000'), isNot(const Color(0xFF000000)));
    expect(eventColor(darkCtx, null), DrColors.accentGreen);
    expect(eventColor(darkCtx, 'nonsense'), DrColors.accentGreen);

    // On the light theme the fallback darkens so it stays readable.
    late BuildContext lightCtx;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: const [DrPalette.light]),
        home: Builder(builder: (c) {
          lightCtx = c;
          return const SizedBox();
        }),
      ),
    );
    // MaterialApp lerps between themes, so the palette is still mid-transition
    // on the frame right after the swap.
    await tester.pumpAndSettle();

    expect(eventColor(lightCtx, null), DrColors.accentGreenDark);
    expect(eventColor(lightCtx, '#25a194'), const Color(0xFF25A194));
  });

  testWidgets('renders the month grid and the selected day panel',
      (tester) async {
    await tester.pumpWidget(_host(EventsCalendarCard(events: events)));
    await tester.pumpAndSettle();

    // Weekday header.
    expect(find.text(_weekdayHead(DateTime.monday)), findsOneWidget);
    expect(find.text(_weekdayHead(DateTime.sunday)), findsOneWidget);

    // Opens on the current month.
    final now = DateTime.now();
    expect(find.text(_monthTitle(now.month)), findsOneWidget);
    expect(find.text('${now.year}'), findsOneWidget);

    // Every day of the month has a cell.
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    expect(find.text('$daysInMonth'), findsWidgets);

    expect(tester.takeException(), isNull);
  });

  testWidgets('the list under the grid is the whole month on screen',
      (tester) async {
    await tester.pumpWidget(_host(EventsCalendarCard(events: events)));
    await tester.pumpAndSettle();

    // September 2026 — backwards or forwards from today, whichever it is.
    await _goTo(tester, 2026, DateTime.september);
    expect(find.text(_monthTitle(DateTime.september)), findsOneWidget);

    // Every entry of the month, without tapping a day; the multi-day break
    // once, not once per day.
    expect(find.text('Staff returns'), findsOneWidget);
    expect(
      find.text('Students arrive and autumn term begins'),
      findsNWidgets(2),
    );
    expect(find.text('Mid-term break'), findsOneWidget);
    // An entry that began in August is still part of September…
    expect(find.text('Summer camp'), findsOneWidget);
    // …and each row says its days.
    expect(find.text(_dayMonth(DateTime(2026, 9, 1))), findsOneWidget);
    expect(find.text('21–24 ${_month(9)}'), findsOneWidget);
    expect(
      find.text('${_dayMonth(DateTime(2026, 8, 28))} – '
          '${_dayMonth(DateTime(2026, 9, 2))}'),
      findsOneWidget,
    );

    // In calendar order: the August start first, the break last.
    final camp = tester.getTopLeft(find.text('Summer camp')).dy;
    final staff = tester.getTopLeft(find.text('Staff returns')).dy;
    final pause = tester.getTopLeft(find.text('Mid-term break')).dy;
    expect(camp, lessThan(staff));
    expect(staff, lessThan(pause));

    // August lists the camp too; October has nothing and says so.
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Summer camp'), findsOneWidget);
    expect(find.text('Staff returns'), findsNothing);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
    }
    expect(find.text(_monthTitle(DateTime.october)), findsOneWidget);
    expect(find.text('Bu ay tədbir yoxdur'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a day narrows the list to it; again, back to the month',
      (tester) async {
    await tester.pumpWidget(_host(EventsCalendarCard(events: events)));
    await tester.pumpAndSettle();
    await _goTo(tester, 2026, DateTime.september);

    // The 8th: its two events with their descriptions, under its header.
    await tester.tap(find.text('8').first);
    await tester.pumpAndSettle();
    expect(find.text(_dayMonth(DateTime(2026, 9, 8))), findsOneWidget);
    expect(
      find.text('Students arrive and autumn term begins'),
      findsNWidgets(2),
    );
    expect(find.text('Staff returns'), findsNothing);
    // The description keeps its line breaks (it used to be folded into " • "
    // and cut to one line).
    expect(
      find.text("2025-2026 Awards' Ceremony (whole school)\nOrientation day"),
      findsOneWidget,
    );

    // The same day again widens it back to the month.
    await tester.tap(find.text('8').first);
    await tester.pumpAndSettle();
    expect(find.text('Staff returns'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    // A day inside the multi-day break resolves to that event.
    await tester.tap(find.text('23'));
    await tester.pumpAndSettle();
    expect(find.text('Mid-term break'), findsOneWidget);
    expect(find.text('Staff returns'), findsNothing);

    // The header's × closes it too.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Staff returns'), findsOneWidget);

    // An empty day says so rather than showing a stale list.
    await tester.tap(find.text('29'));
    await tester.pumpAndSettle();
    expect(find.text('Bu gün üçün tədbir yoxdur'), findsOneWidget);

    // Paging drops the day: the next month's list, whole.
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Summer camp'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    expect(tester.takeException(), isNull);
  });

  group('red entries tint their date', () {
    test('the panel\'s red counts; its pink and orange don\'t', () {
      expect(isRedEventColor(const Color(0xFFDC3545)), isTrue);
      expect(isRedEventColor(const Color(0xFFFF0000)), isTrue);
      expect(isRedEventColor(const Color(0xFFD63384)), isFalse);
      expect(isRedEventColor(const Color(0xFFFD7E14)), isFalse);
      expect(isRedEventColor(DrColors.accentGreen), isFalse);
      expect(isRedEventColor(Colors.white), isFalse);
    });

    Color? cellFill(WidgetTester tester, String day) {
      final circle = tester.widget<Container>(
        find
            .ancestor(of: find.text(day), matching: find.byType(Container))
            .first,
      );
      return (circle.decoration as BoxDecoration).color;
    }

    testWidgets('a day with a red entry is filled red, translucent',
        (tester) async {
      await tester.pumpWidget(_host(EventsCalendarCard(events: events)));
      await tester.pumpAndSettle();
      await _goTo(tester, 2026, DateTime.september);

      // The 8th carries #dc3545 (next to an orange one).
      expect(
        cellFill(tester, '8'),
        const Color(0xFFDC3545).withValues(alpha: 0.25),
      );
      // Teal, blue and empty days stay clear.
      expect(cellFill(tester, '1'), Colors.transparent);
      expect(cellFill(tester, '22'), Colors.transparent);
      expect(cellFill(tester, '15'), Colors.transparent);

      // Selected, the green pill wins.
      await tester.tap(find.text('8').first);
      await tester.pumpAndSettle();
      expect(cellFill(tester, '8'), DrColors.accentGreen);
    });
  });

  group('titles in full, in the app language', () {
    final busy = _busyPayload
        .map((e) => SchoolEventModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    /// A phone-sized screen, so a long title really has to wrap.
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    test('model reads translations; a missing one falls back', () {
      final e = busy.first;
      expect(e.titleIn('az'), _longTitleAz);
      expect(e.titleIn('ru'), 'Родительское собрание');
      expect(e.descriptionIn('az'), contains('\n'));
      // No `translations` at all (older backend) → the request-language text.
      expect(busy[1].titleIn('az'), 'Second');
      expect(busy[1].translations, isEmpty);
    });

    testWidgets('row shows the whole title and description, no ellipsis',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(_host(EventsCalendarCard(events: busy)));
      await tester.pumpAndSettle();
      await _goTo(tester, 2026, DateTime.november);
      await tester.tap(find.text('4').first);
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text(_longTitleAz));
      expect(title.maxLines, isNull);
      expect(title.overflow, isNot(TextOverflow.ellipsis));
      // Wraps onto more than one line at phone width.
      expect(tester.getSize(find.text(_longTitleAz)).height, greaterThan(20));
      expect(
        find.text('Qapılar 09:00-da açılır\nValideynlər şəxsiyyət vəsiqəsi gətirsin'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the language comes from the app, not the request',
        (tester) async {
      await tester.pumpWidget(
        _host(EventsCalendarCard(events: busy), locale: 'ru'),
      );
      await tester.pumpAndSettle();
      await _goTo(tester, 2026, DateTime.november);
      await tester.tap(find.text('4').first);
      await tester.pumpAndSettle();

      expect(find.text('Родительское собрание'), findsOneWidget);
      expect(find.text(_longTitleEn), findsNothing);
    });

    testWidgets('"+N" is translated and opens the rest of the list',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(_host(EventsCalendarCard(events: busy)));
      await tester.pumpAndSettle();
      await _goTo(tester, 2026, DateTime.november);

      // The month: seven entries, six shown — the latest one waits.
      expect(find.text('Sixth'), findsOneWidget);
      expect(find.text('Seventh'), findsNothing);
      // az: "və daha {count} tədbir" — the row used to hard-code "ve daha".
      await tester.tap(find.text('və daha 1 tədbir'));
      await tester.pumpAndSettle();
      expect(find.text('Seventh'), findsOneWidget);
      expect(find.text('və daha 1 tədbir'), findsNothing);

      // Narrowing to a day collapses the list again.
      await tester.tap(find.text('4').first);
      await tester.pumpAndSettle();
      expect(find.text('Seventh'), findsNothing);
      expect(find.text('və daha 1 tədbir'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping an entry opens it in full: days, time, text',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(_host(EventsCalendarCard(events: busy)));
      await tester.pumpAndSettle();
      await _goTo(tester, 2026, DateTime.november);
      await tester.tap(find.text('4').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text(_longTitleAz));
      await tester.pumpAndSettle();

      // Row + sheet.
      expect(find.text(_longTitleAz), findsNWidgets(2));
      // 4–6 November, said once, plus the time.
      expect(find.textContaining('09:30'), findsWidgets);
      expect(find.textContaining('4–6'), findsOneWidget);
      expect(find.text('Description:'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('loading and error states replace the grid', (tester) async {
    await tester.pumpWidget(
      _host(const EventsCalendarCard(events: [], loading: true)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(_weekdayHead(DateTime.monday)), findsNothing);

    var retried = false;
    await tester.pumpWidget(
      _host(
        EventsCalendarCard(
          events: const [],
          errorMessage: 'Tədbirlər yüklənmədi',
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tədbirlər yüklənmədi'), findsOneWidget);

    await tester.tap(find.text('Yenidən cəhd et'));
    expect(retried, isTrue);
    expect(tester.takeException(), isNull);
  });
}
