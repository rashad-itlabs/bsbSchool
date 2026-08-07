import 'package:bsbschool/features/events/data/models/school_event_model.dart';
import 'package:bsbschool/features/events/presentation/widgets/events_calendar_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bsbschool/dr/theme/dr_colors.dart';

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
];

Widget _host(Widget child) => MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: const [DrPalette.dark],
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
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
    expect(find.text('Be'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    // Opens on the current month.
    final now = DateTime.now();
    const months = [
      'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'İyun',
      'İyul', 'Avqust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
    ];
    expect(find.text(months[now.month - 1]), findsOneWidget);
    expect(find.text('${now.year}'), findsOneWidget);

    // Every day of the month has a cell.
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    expect(find.text('$daysInMonth'), findsWidgets);

    expect(tester.takeException(), isNull);
  });

  testWidgets('navigating to a month with events lists them', (tester) async {
    await tester.pumpWidget(_host(EventsCalendarCard(events: events)));
    await tester.pumpAndSettle();

    // Step forward from today (2026-08 at time of writing) until September 2026
    // is on screen; the arrow is the second icon button.
    final forward = find.byIcon(Icons.chevron_right_rounded);
    expect(forward, findsOneWidget);

    for (var i = 0; i < 24; i++) {
      if (find.text('Sentyabr').evaluate().isNotEmpty &&
          find.text('2026').evaluate().isNotEmpty) {
        break;
      }
      await tester.tap(forward);
      await tester.pumpAndSettle();
    }
    expect(find.text('Sentyabr'), findsOneWidget);

    // Day 1 is auto-selected on a month the user navigated to.
    expect(find.text('1 Sentyabr'), findsOneWidget);
    expect(find.text('Staff returns'), findsOneWidget);

    // Tapping the 8th shows both of that day's events with their descriptions.
    await tester.tap(find.text('8').first);
    await tester.pumpAndSettle();
    expect(find.text('8 Sentyabr'), findsOneWidget);
    expect(
      find.text('Students arrive and autumn term begins'),
      findsNWidgets(2),
    );
    expect(
      find.text("2025-2026 Awards' Ceremony (whole school) • Orientation day"),
      findsOneWidget,
    );

    // A day inside the multi-day break resolves to that event.
    await tester.tap(find.text('23'));
    await tester.pumpAndSettle();
    expect(find.text('Mid-term break'), findsOneWidget);

    // An empty day says so rather than showing a stale list.
    await tester.tap(find.text('29'));
    await tester.pumpAndSettle();
    expect(find.text('Bu gün üçün tədbir yoxdur'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and error states replace the grid', (tester) async {
    await tester.pumpWidget(
      _host(const EventsCalendarCard(events: [], loading: true)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Be'), findsNothing);

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
