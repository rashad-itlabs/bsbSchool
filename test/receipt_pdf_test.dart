import 'package:bsbschool/dr/services/receipt_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

/// A receipt with everything the gateway can send, in the language it will
/// most often be read in.
ReceiptDocument _document({List<ReceiptSection>? sections}) => ReceiptDocument(
      title: 'Ödəniş qəbzi',
      amountLabel: 'Məbləğ',
      amount: '5.00 ₼',
      statusLine: 'Ödəniş uğurludur',
      sections: sections ??
          const [
            ReceiptSection(rows: [
              ('Şagird', 'Said Aliyev'),
              ('Sinif', 'Year 6'),
              ('Kart nömrəsi', '0010480724'),
              ('Təyinat', 'Balans artımı'),
              ('Tarix', '16 sen 2026, 23:44'),
            ]),
            ReceiptSection(title: 'Ödəniş məlumatları', rows: [
              ('Kart', '424242******0017'),
              ('Ödəniş sistemi', 'Visa'),
              ('Bank', 'Expressbank'),
              ('Təsdiq kodu', '681638'),
              ('RRN', '625923308378'),
              ('Əməliyyat nömrəsi', 'WEB-8b635dc0-d311-479c-bc68-0fa2f9897d6d'),
              ('Komissiya', '0.00 ₼'),
              ('Status', 'OK (No error)'),
            ]),
          ],
      footer: 'Bu qəbz avtomatik yaradılıb və imza tələb etmir.',
      fileName: 'BSB-qebz-2026-09-16-2344-681638',
    );

void main() {
  // `rootBundle` serves the app's fonts and crest from the test bundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a receipt as a PDF', () async {
    final bytes = await ReceiptPdf().build(_document());

    // Layout runs during save(), so a PDF coming back at all means every row
    // laid out — including the Azerbaijani letters and ₼, which the standard
    // PDF fonts cannot encode.
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('renders a receipt whose payload held nothing', () async {
    final bytes = await ReceiptPdf().build(
      _document(sections: const [
        ReceiptSection(rows: [('Təyinat', 'Balans artımı')]),
      ]),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
