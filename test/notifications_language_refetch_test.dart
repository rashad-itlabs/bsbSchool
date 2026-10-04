import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/core/l10n/l10n.dart';
import 'package:bsbschool/dr/screens/notifications_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/notifications/data/models/notifications_content_model.dart';
import 'package:bsbschool/features/notifications/data/services/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the language each request named, the way the real service reads
/// it (from [L]).
class _RecordingService implements NotificationsService {
  final languages = <String>[];

  @override
  Future<NotificationsContentModel> getNotifications({int? classId}) async {
    languages.add(L.s.localeName);
    return NotificationsContentModel.fromJson({'data': []});
  }
}

/// Mirrors the app root: [L] follows the active locale, set above the tabs.
Widget _app(Locale locale) => MaterialApp(
      theme: DrTheme.dark,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) {
        L.current = AppL10n.of(context);
        return child!;
      },
      home: const NotificationsScreen(),
    );

void main() {
  late _RecordingService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
    service = _RecordingService();
    sl.unregister<NotificationsService>();
    sl.registerLazySingleton<NotificationsService>(() => service);
  });

  testWidgets('switching the language asks for the feed again in it',
      (tester) async {
    await tester.pumpWidget(_app(const Locale('az')));
    await tester.pumpAndSettle();
    expect(service.languages, ['az']);

    // Same tab, still mounted, new language.
    await tester.pumpWidget(_app(const Locale('ru')));
    await tester.pumpAndSettle();
    expect(service.languages, ['az', 'ru']);

    // A rebuild that doesn't change the language doesn't refetch.
    await tester.pumpWidget(_app(const Locale('ru')));
    await tester.pumpAndSettle();
    expect(service.languages, ['az', 'ru']);
  });
}
