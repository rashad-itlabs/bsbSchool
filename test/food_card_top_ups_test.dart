import 'dart:convert';

import 'package:bsbschool/core/di/injection_container.dart';
import 'package:bsbschool/dr/screens/food_card_screen.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/features/buffet_cart/data/models/buffet_card_content_model.dart';
import 'package:bsbschool/features/buffet_cart/data/services/buffet_card_service.dart';
import 'package:bsbschool/features/buffet_cart/presentation/widgets/top_up_receipt_sheet.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves the `GET /getBuffetCart` body the school's API actually returns, so
/// the screen is exercised end to end without a network.
class _FakeCardService implements BuffetCardService {
  @override
  Future<BuffetCardContentModel> getBuffetCard({int? studentId}) async =>
      BuffetCardContentModel.fromJson(
        jsonDecode(_body) as Map<String, dynamic>,
      );
}

/// Noon today: the purchases list opens filtered to today, so the fixture's
/// purchase has to fall on the day the test runs.
final _todayNoon = () {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 12).toIso8601String();
}();

final _body = '''
{
  "user_id": 3789,
  "card": [
    {
      "id": 1398,
      "firstname": "Said",
      "lastname": "Aliyev",
      "class_name": "Year 6",
      "card_id_1": "0010480724",
      "money_balance": "46.00",
      "usage": "2",
      "fixed_usage": 2
    }
  ],
  "incoming": [
    {
      "purpose": "Balans artımı",
      "ampunt": "1.00",
      "created_balance": "2026-09-16 15:41:34",
      "payload": "{\\"pan\\": \\"424242******0017\\", \\"rrn\\": \\"625915189514\\", \\"code\\": 0, \\"approval\\": \\"052500\\", \\"message\\": \\"OK (No error)\\"}"
    },
    {
      "purpose": "Balans artımı",
      "ampunt": "5.00",
      "created_balance": "2026-09-16 23:44:17",
      "payload": "{\\"pan\\": \\"424242******0017\\", \\"rrn\\": \\"625923308378\\", \\"code\\": 0, \\"approval\\": \\"681638\\", \\"message\\": \\"OK (No error)\\"}"
    }
  ],
  "transactions": {
    "data": [
      {"id": 14415, "amount": "1.00", "created_at": "$_todayNoon"}
    ],
    "current_page": 1,
    "last_page": 1,
    "total": 1
  }
}
''';

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
      home: const FoodCardScreen(),
    );

/// The screen is a lazy [ListView] and the section sits below the card, so a
/// row only exists once it has been scrolled to.
Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
    sl.unregister<BuffetCardService>();
    sl.registerLazySingleton<BuffetCardService>(_FakeCardService.new);
  });

  testWidgets('the card screen lists the top-ups that funded it',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Purchases stay where they were, above the new section.
    expect(find.text('- 1.00 ₼'), findsOneWidget);

    // Credits read as additions, purchases as deductions.
    await _scrollTo(tester, find.text('+ 5.00 ₼'));
    expect(find.text('Balans artımları'), findsOneWidget);
    expect(find.text('+ 5.00 ₼'), findsOneWidget);
    expect(find.text('+ 1.00 ₼'), findsOneWidget);
  });

  testWidgets('tapping a top-up opens its receipt', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('+ 5.00 ₼'));
    await tester.tap(find.text('+ 5.00 ₼'));
    await tester.pumpAndSettle();

    expect(find.byType(TopUpReceiptSheet), findsOneWidget);
    expect(find.text('681638'), findsOneWidget);
    expect(find.text('Qəbzi PDF yüklə'), findsOneWidget);
  });
}
