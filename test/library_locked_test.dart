import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/dr/screens/library_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/library/data/models/library_content_model.dart';
import 'package:bsbschool/features/library/data/services/library_service.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `GET /library` for a child whose box «Library closed» is ticked in Student
/// Information (`ApiController::library`, QƏRAR-136 on the site).
const _locked = {
  'class_id': 95,
  'class_name': 'Class Group 8',
  'data': [],
  'locked': true,
  'locked_text': 'Kitabxana borca görə bağlıdır',
  'locked_note': 'Kitabxana ödəniş məsələsi həll olunandan sonra açılacaq.',
};

/// The same child once the box is cleared — the server omits `locked`.
const _open = {
  'class_id': 95,
  'class_name': 'Class Group 8',
  'data': [
    {
      'id': 1,
      'title': 'Oxford Reader',
      'author': 'Jane Doe',
      'subject': 'English',
      'cover': null,
      'file_url': 'https://online.bsb.edu.az/storage/books/a.pdf',
    },
  ],
};

class _FakeService implements LibraryService {
  Map<String, dynamic> body;
  _FakeService(this.body);

  @override
  Future<LibraryContentModel> getLibrary({int? classId}) async =>
      LibraryContentModel.fromJson(body);
}

Widget _app() => MaterialApp(
      theme: DrTheme.dark,
      locale: const Locale('az'),
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      home: const LibraryScreen(),
    );

void main() {
  group('LibraryContentModel.fromJson', () {
    test('reads the lock and the server texts', () {
      final m = LibraryContentModel.fromJson(Map.of(_locked));
      expect(m.locked, isTrue);
      expect(m.lockedText, 'Kitabxana borca görə bağlıdır');
      expect(m.lockedNote, startsWith('Kitabxana ödəniş'));
      expect(m.books, isEmpty);
    });

    test('an open library has no lock', () {
      final m = LibraryContentModel.fromJson(Map.of(_open));
      expect(m.locked, isFalse);
      expect(m.lockedText, isNull);
      expect(m.books, hasLength(1));
    });

    test('a loose "1" still counts as locked', () {
      final m = LibraryContentModel.fromJson({'data': [], 'locked': '1'});
      expect(m.locked, isTrue);
    });
  });

  group('LibraryScreen', () {
    late _FakeService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await sl.reset();
      await initDependencies();
      service = _FakeService(Map.of(_locked));
      sl.unregister<LibraryService>();
      sl.registerLazySingleton<LibraryService>(() => service);
    });

    testWidgets('closed library shows the server message, not «no books»',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Kitabxana borca görə bağlıdır'), findsOneWidget);
      expect(find.textContaining('Kitabxana ödəniş'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Kitab tapılmadı'), findsNothing);
      // Nothing to search in a closed library.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('falls back to the app text when the server sends none',
        (tester) async {
      service.body = {'class_id': null, 'data': [], 'locked': true};
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Locked wins over «no class».
      expect(find.text('Kitabxana borca görə bağlıdır'), findsOneWidget);
      expect(find.text('Sinif təyin edilməyib'), findsNothing);
    });

    testWidgets('pull-to-refresh after the box is cleared brings the books',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      service.body = Map.of(_open);
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Oxford Reader'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
