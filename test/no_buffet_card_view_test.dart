import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/dr/screens/food_card_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/buffet_cart/data/models/buffet_card_content_model.dart';
import 'package:bsbschool/features/buffet_cart/data/services/buffet_card_service.dart';
import 'package:bsbschool/features/buffet_cart/presentation/widgets/no_buffet_card_view.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bsbschool/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A student the school hasn't issued a card to: `card` comes back empty.
class _NoCardService implements BuffetCardService {
  var calls = 0;

  @override
  Future<BuffetCardContentModel> getBuffetCard({int? studentId}) async {
    calls++;
    return BuffetCardContentModel.fromJson({'card': [], 'incoming': []});
  }
}

Widget _app(Locale locale, ThemeData theme, double textScale) => MaterialApp(
      theme: theme,
      locale: locale,
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      // The app provides AuthBloc at its root; the tab reads the active
      // child's section from it.
      home: BlocProvider<AuthBloc>(
        create: (_) => sl<AuthBloc>(),
        child: const FoodCardScreen(),
      ),
    );

void main() {
  late _NoCardService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
    service = _NoCardService();
    sl.unregister<BuffetCardService>();
    sl.registerLazySingleton<BuffetCardService>(() => service);
  });

  final themes = {'dark': DrTheme.dark, 'light': DrTheme.light};

  for (final locale in AppL10n.supportedLocales) {
    for (final theme in themes.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
            'no-card view fits a phone: $locale, ${theme.key}, text ×$scale',
            (tester) async {
          tester.view.physicalSize = const Size(360, 780) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(_app(locale, theme.value, scale));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(NoBuffetCardView), findsOneWidget);
          final l10n = lookupAppL10n(locale);
          expect(find.text(l10n.foodCardNoneTitle), findsOneWidget);
          expect(find.text(l10n.foodCardNoneText), findsOneWidget);
        });
      }
    }
  }

  testWidgets('refresh asks the server again', (tester) async {
    tester.view.physicalSize = const Size(360, 780) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const Locale('az'), DrTheme.dark, 1));
    await tester.pumpAndSettle();
    expect(service.calls, 1);

    await tester.tap(find.text('Yenilə'));
    await tester.pumpAndSettle();
    expect(service.calls, 2);
    // Still no card, so the same view comes back.
    expect(find.byType(NoBuffetCardView), findsOneWidget);
  });
}
