import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/l10n/l10n.dart';
import 'package:bsbschool/dr/screens/notifications_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/notifications/data/models/notification_model.dart';
import 'package:bsbschool/features/notifications/data/models/notifications_content_model.dart';
import 'package:bsbschool/features/notifications/data/services/notifications_service.dart';
import 'package:bsbschool/features/notifications/presentation/notifications_feed_signal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A teacher's message and a school announcement — on purpose with the same
/// id: they come from two tables on the server, and a tap on push 21 must open
/// the announcement, never the teacher's message.
const _teacher = {
  'id': 21,
  'send_type': 'student',
  'title': 'Riyaziyyat',
  'message': 'Sabah kiçik test olacaq.',
  'sender': 'Aysel Məmmədova',
  'date': '2026-10-14T08:00:00.000000Z',
};
const _announcement = {
  'id': 21,
  'send_type': 'school',
  'source': 'push',
  'title': 'Valideyn iclası',
  'message': 'Cümə günü saat 18:00-da akt zalında valideyn iclası keçiriləcək.',
  'class_name': null,
  'sender': null,
  'file': null,
  'date': '2026-10-15T09:30:00.000000Z',
};

class _FakeService implements NotificationsService {
  int calls = 0;

  @override
  Future<NotificationsContentModel> getNotifications({int? classId}) async {
    calls++;
    return NotificationsContentModel.fromJson({
      'data': [_teacher, _announcement],
    });
  }
}

Widget _app() => MaterialApp(
      theme: DrTheme.dark,
      locale: const Locale('az'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) {
        L.current = AppL10n.of(context);
        return child!;
      },
      home: const NotificationsScreen(),
    );

void main() {
  late _FakeService service;
  final signal = NotificationsFeedSignal.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
    service = _FakeService();
    sl.unregister<NotificationsService>();
    sl.registerLazySingleton<NotificationsService>(() => service);
    signal.takeOpenPushId();
  });

  group('the model', () {
    test('reads the source of an admin push', () {
      final item = NotificationModel.fromJson(_announcement);
      expect(item.source, 'push');
      expect(item.isSchoolPush, isTrue);
      expect(item.isForClass, isFalse);
    });

    test('a teacher message — no source — is not one', () {
      final item = NotificationModel.fromJson(_teacher);
      expect(item.source, isNull);
      expect(item.isSchoolPush, isFalse);
    });

    test('send_type alone is enough', () {
      expect(
          NotificationModel.fromJson({'id': 1, 'send_type': 'School'})
              .isSchoolPush,
          isTrue);
    });
  });

  testWidgets('an announcement is told apart from a teacher message',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('📣'), findsOneWidget);
    expect(find.textContaining('Məktəb rəhbərliyi'), findsOneWidget);
    expect(find.textContaining('Aysel Məmmədova'), findsOneWidget);
  });

  testWidgets('tapping a row opens it in full and the button closes it',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Valideyn iclası'));
    await tester.pumpAndSettle();

    expect(find.text('Valideyn iclası'), findsNWidgets(2));
    expect(find.byType(SelectableText), findsOneWidget);
    expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        _announcement['message']);

    await tester.tap(find.text('Bağla'));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('a push asks for the feed again; a tapped one opens itself',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(service.calls, 1);

    // Arrived in the foreground: refetch, open nothing.
    signal.pushReceived();
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    expect(find.byType(SelectableText), findsNothing);

    // Tapped: refetch and open the announcement — not the teacher's 21.
    signal.pushReceived(openPushId: 21);
    await tester.pumpAndSettle();
    expect(service.calls, 3);
    expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        _announcement['message']);
    expect(signal.hasPendingOpen, isFalse);
  });

  testWidgets('a tap that started the app opens it after the first load',
      (tester) async {
    signal.pushReceived(openPushId: 21); // before the tab exists
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).data,
        _announcement['message']);
  });

  testWidgets('an id the feed does not have opens nothing and is dropped',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    signal.pushReceived(openPushId: 999);
    await tester.pumpAndSettle();

    expect(find.byType(SelectableText), findsNothing);
    expect(signal.hasPendingOpen, isFalse);
  });
}
