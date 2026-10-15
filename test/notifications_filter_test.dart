import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/l10n/l10n.dart';
import 'package:bsbschool/dr/screens/notifications_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/dr/widgets/dr_widgets.dart';
import 'package:bsbschool/features/notifications/data/models/notification_model.dart';
import 'package:bsbschool/features/notifications/data/models/notifications_content_model.dart';
import 'package:bsbschool/features/notifications/data/services/notifications_service.dart';
import 'package:bsbschool/features/notifications/domain/entities/notification_item.dart';
import 'package:bsbschool/features/notifications/presentation/notifications_feed_signal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One entry per source the feed has today, plus one the server will start
/// sending later (attendance).
const _teacher = {
  'id': 1,
  'send_type': 'class',
  'category': 'teacher',
  'title': 'Riyaziyyat',
  'message': 'Sabah kiçik test olacaq.',
  'class_name': '7A',
  'date': '2026-10-14T08:00:00.000000Z',
};
const _homework = {
  'id': 2,
  'send_type': 'student',
  'category': 'homework',
  'title': 'Yeni ev tapşırığı',
  'message': 'Fizika: 3.2 Sürət',
  'date': '2026-10-14T09:00:00.000000Z',
};
const _announcement = {
  'id': 3,
  'send_type': 'school',
  'source': 'push',
  'category': 'system',
  'title': 'Valideyn iclası',
  'message': 'Cümə günü saat 18:00-da.',
  'date': '2026-10-15T09:30:00.000000Z',
};
const _attendance = {
  'id': 4,
  'send_type': 'student',
  'category': 'attendance',
  'title': 'Gecikmə',
  'message': 'Uşaq 08:42-də gəlib.',
  'date': '2026-10-15T08:42:00.000000Z',
};

class _FakeService implements NotificationsService {
  int calls = 0;

  @override
  Future<NotificationsContentModel> getNotifications({int? classId}) async {
    calls++;
    return NotificationsContentModel.fromJson({
      'data': [_teacher, _homework, _announcement, _attendance],
    });
  }
}

/// Picks [label] the way a tap on it does. A pill on screen is tapped for
/// real. The bar is a lazy horizontal list, so the last pills are not built
/// until it is scrolled — on a phone too — and scrolling it in a test drags
/// the page's own list along; those are picked through the bar's callback,
/// which is what the tap calls.
Future<void> _tapPill(WidgetTester tester, String label) async {
  final pill = find.text(label).hitTestable();
  if (pill.evaluate().isNotEmpty) {
    await tester.tap(pill);
  } else {
    final bar = tester.widget<DrChipBar>(find.byType(DrChipBar));
    bar.onSelected(bar.labels.indexOf(label));
  }
  await tester.pumpAndSettle();
}

Widget _app({bool forStudent = false}) => MaterialApp(
  theme: DrTheme.dark,
  locale: const Locale('az'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) {
    L.current = AppL10n.of(context);
    return child!;
  },
  home: NotificationsScreen(forStudent: forStudent),
);

void main() {
  late _FakeService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
    service = _FakeService();
    sl.unregister<NotificationsService>();
    sl.registerLazySingleton<NotificationsService>(() => service);
    NotificationsFeedSignal.instance.takeOpenPushId();
  });

  group('the category', () {
    NotificationCategory of(Map<String, dynamic> json) =>
        NotificationModel.fromJson(json).category;

    test('is what the server says', () {
      expect(of(_homework), NotificationCategory.homework);
      expect(of(_attendance), NotificationCategory.attendance);
      expect(of({'id': 9, 'category': 'exam'}), NotificationCategory.exam);
      expect(
        of({'id': 9, 'category': 'Bufet'}),
        NotificationCategory.cafeteria,
      );
    });

    test(
      'an older server: an announcement is still system, the rest teacher',
      () {
        expect(
          of({'id': 9, 'send_type': 'school', 'source': 'push'}),
          NotificationCategory.system,
        );
        expect(
          of({'id': 9, 'send_type': 'class'}),
          NotificationCategory.teacher,
        );
      },
    );

    test('a value this build does not know falls back the same way', () {
      expect(
        of({'id': 9, 'category': 'weather'}),
        NotificationCategory.teacher,
      );
      expect(
        of({'id': 9, 'category': 'weather', 'source': 'push'}),
        NotificationCategory.system,
      );
    });
  });

  testWidgets('every pill is there, in a fixed order, empty ones too', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Read off the bar itself: it is a lazy horizontal list, so the pills
    // past the screen edge are not built until it is scrolled.
    // Homework and teachers' messages have no pill (owner, 15.10.2026).
    expect(tester.widget<DrChipBar>(find.byType(DrChipBar)).labels, [
      'Hamısı',
      'Davamiyyət',
      'İmtahan',
      'Bufet',
      'Sistem',
    ]);
  });

  testWidgets('a pill narrows the list to its entries', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Valideyn iclası'), findsOneWidget);
    expect(find.text('Riyaziyyat'), findsOneWidget);

    await _tapPill(tester, 'Sistem');
    expect(find.text('Valideyn iclası'), findsOneWidget);
    expect(find.text('Riyaziyyat'), findsNothing);
    expect(find.text('Yeni ev tapşırığı'), findsNothing);

    await _tapPill(tester, 'Davamiyyət');
    expect(find.text('Gecikmə'), findsOneWidget);
    expect(find.text('Valideyn iclası'), findsNothing);

    await _tapPill(tester, 'Hamısı');
    for (final title in [
      'Riyaziyyat',
      'Yeni ev tapşırığı',
      'Valideyn iclası',
      'Gecikmə',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('homework and teachers\' messages are listed under "all" only',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Yeni ev tapşırığı'), findsOneWidget);
    expect(find.text('📝'), findsOneWidget); // its emoji still follows it
    expect(find.text('Riyaziyyat'), findsOneWidget);

    for (final pill in ['Davamiyyət', 'İmtahan', 'Bufet', 'Sistem']) {
      await _tapPill(tester, pill);
      expect(find.text('Yeni ev tapşırığı'), findsNothing, reason: pill);
      expect(find.text('Riyaziyyat'), findsNothing, reason: pill);
    }
  });

  testWidgets('an empty pill says so, not "no notifications at all"', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await _tapPill(tester, 'İmtahan');
    expect(find.text('Bu bölmədə hələ bildiriş yoxdur.'), findsOneWidget);
    expect(find.text('Hələ bildiriş yoxdur.'), findsNothing);
  });

  testWidgets('the pill survives a refetch a push triggers', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await _tapPill(tester, 'Davamiyyət');
    expect(find.text('Gecikmə'), findsOneWidget);

    NotificationsFeedSignal.instance.pushReceived();
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    expect(find.text('Gecikmə'), findsOneWidget);
    expect(find.text('Riyaziyyat'), findsNothing);
  });

  group('a student signed in', () {
    testWidgets('gets their own pills: all, homework, system', (tester) async {
      await tester.pumpWidget(_app(forStudent: true));
      await tester.pumpAndSettle();

      expect(tester.widget<DrChipBar>(find.byType(DrChipBar)).labels, [
        'Hamısı',
        'Ev tapşırığı',
        'Sistem',
      ]);
    });

    testWidgets('homework narrows to homework, system to announcements', (
      tester,
    ) async {
      await tester.pumpWidget(_app(forStudent: true));
      await tester.pumpAndSettle();

      await _tapPill(tester, 'Ev tapşırığı');
      expect(find.text('Yeni ev tapşırığı'), findsOneWidget);
      expect(find.text('Valideyn iclası'), findsNothing);
      expect(find.text('Riyaziyyat'), findsNothing);

      await _tapPill(tester, 'Sistem');
      expect(find.text('Valideyn iclası'), findsOneWidget);
      expect(find.text('Yeni ev tapşırığı'), findsNothing);

      // A teacher's message has no pill here either — "all" lists it.
      await _tapPill(tester, 'Hamısı');
      expect(find.text('Riyaziyyat'), findsOneWidget);
    });
  });
}
