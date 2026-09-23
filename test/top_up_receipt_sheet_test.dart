import 'package:bsbschool/dr/services/receipt_pdf.dart';
import 'package:bsbschool/dr/theme/dr_theme.dart';
import 'package:bsbschool/dr/widgets/dr_widgets.dart';
import 'package:bsbschool/features/buffet_cart/domain/entities/buffet_card.dart';
import 'package:bsbschool/features/buffet_cart/domain/entities/buffet_top_up.dart';
import 'package:bsbschool/features/buffet_cart/presentation/widgets/top_up_receipt_sheet.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the real writer, which needs a file system to write to.
class _FakeWriter extends ReceiptPdf {
  _FakeWriter({this.fails = false});

  final bool fails;
  ReceiptDocument? written;

  @override
  Future<void> download(ReceiptDocument document) async {
    written = document;
    if (fails) throw Exception('no room on the phone');
  }
}

const _card = BuffetCard(
  firstname: 'Said',
  lastname: 'Aliyev',
  className: 'Year 6',
  cardId1: '0010480724',
);

final _topUp = BuffetTopUp(
  purpose: 'Balans artımı',
  amount: 5,
  date: DateTime(2026, 9, 16, 23, 44, 17),
  receipt: TopUpReceipt(
    reference: 'WEB-8b635dc0-d311-479c-bc68-0fa2f9897d6d',
    rrn: '625923308378',
    approval: '681638',
    pan: '424242******0017',
    issuer: 'Expressbank',
    system: 'Visa',
    method: 'Card',
    amount: 5,
    fee: 0,
    currency: 'AZN',
    status: '00',
    code: 0,
    message: 'OK (No error)',
    datetime: DateTime(2026, 9, 16, 23, 44, 31),
  ),
);

/// Opens the sheet the way the card screen does and keeps what it popped with.
Widget _host(TopUpReceiptSheet sheet, void Function(String?) onClosed) {
  return MaterialApp(
    theme: DrTheme.dark,
    locale: const Locale('az'),
    localizationsDelegates: const [
      AppL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppL10n.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onClosed(
            await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => sheet,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows what the gateway sent back', (tester) async {
    await tester.pumpWidget(
      _host(TopUpReceiptSheet(topUp: _topUp, card: _card, writer: _FakeWriter()),
          (_) {}),
    );
    await _open(tester);

    expect(find.text('+ 5.00 ₼'), findsOneWidget);
    expect(find.text('Said Aliyev'), findsOneWidget);
    expect(find.text('0010480724'), findsOneWidget);
    expect(find.text('424242******0017'), findsOneWidget);
    expect(find.text('681638'), findsOneWidget);
    expect(find.text('625923308378'), findsOneWidget);
    expect(find.text('OK (No error)'), findsOneWidget);
  });

  testWidgets('a payment with no payload still receipts what is known',
      (tester) async {
    await tester.pumpWidget(
      _host(
        TopUpReceiptSheet(
          topUp: const BuffetTopUp(purpose: 'Balans artımı', amount: 5),
          card: _card,
          writer: _FakeWriter(),
        ),
        (_) {},
      ),
    );
    await _open(tester);

    expect(find.text('+ 5.00 ₼'), findsOneWidget);
    expect(find.text('Bu ödəniş üçün qəbz məlumatı yoxdur'), findsOneWidget);
    expect(find.text('Qəbzi PDF yüklə'), findsOneWidget);
  });

  testWidgets('writing the PDF closes the sheet with the message to show',
      (tester) async {
    final writer = _FakeWriter();
    String? closedWith;
    await tester.pumpWidget(
      _host(TopUpReceiptSheet(topUp: _topUp, card: _card, writer: writer),
          (message) => closedWith = message),
    );
    await _open(tester);

    await tester.tap(find.byType(DrPrimaryButton));
    await tester.pumpAndSettle();

    final document = writer.written!;
    expect(document.amount, '5.00 ₼');
    // Dated, and carrying the approval code so two receipts from the same
    // minute cannot overwrite each other.
    expect(document.fileName, 'BSB-qebz-2026-09-16-2344-681638');
    expect(
      document.sections.expand((s) => s.rows).map((r) => r.$2),
      containsAll(['Said Aliyev', '0010480724', '625923308378']),
    );

    expect(find.byType(TopUpReceiptSheet), findsNothing);
    expect(closedWith, isNotNull);
  });

  testWidgets('a failed write keeps the sheet open and says so', (tester) async {
    String? closedWith;
    await tester.pumpWidget(
      _host(
        TopUpReceiptSheet(
          topUp: _topUp,
          card: _card,
          writer: _FakeWriter(fails: true),
        ),
        (message) => closedWith = message,
      ),
    );
    await _open(tester);

    await tester.tap(find.byType(DrPrimaryButton));
    await tester.pumpAndSettle();

    expect(find.byType(TopUpReceiptSheet), findsOneWidget);
    expect(find.text('Qəbz yüklənmədi'), findsOneWidget);
    expect(closedWith, isNull);
  });
}
