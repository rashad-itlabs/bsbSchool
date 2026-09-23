import 'dart:convert';

import 'package:bsbschool/features/buffet_cart/data/models/buffet_card_content_model.dart';
import 'package:bsbschool/features/buffet_cart/presentation/bloc/buffet_card_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real `GET /getBuffetCart` response once the endpoint began sending
/// `incoming`: three top-ups (one from the app, two from the web site) and two
/// purchases. Trimmed of the fields the app never reads.
const _body = '''
{
    "user_id": 3789,
    "card": [
        {
            "id": 1398,
            "user_id": 3789,
            "firstname": "Said",
            "lastname": "Aliyev",
            "class_name": "Year 6",
            "card_id_1": "0010480724",
            "card_id_2": null,
            "balance": null,
            "money_balance": "46.00",
            "balance_created": "2026-09-16 23:44:33",
            "usage": "2",
            "fixed_usage": 2,
            "monthly_limit": "unlimited",
            "status": 2,
            "category": "secondary",
            "payment_type": "money"
        }
    ],
    "incoming": [
        {
            "purpose": "Balans artımı",
            "ampunt": "1.00",
            "created_balance": "2026-09-16 15:41:34",
            "payload": "{\\"fee\\": 0, \\"pan\\": \\"424242******0017\\", \\"rrn\\": \\"625915189514\\", \\"code\\": 0, \\"type\\": \\"SMS\\", \\"extra\\": [{\\"name\\": \\"userid\\", \\"value\\": \\"3789\\"}], \\"amount\\": 1, \\"biller\\": \\"BLR0001\\", \\"expiry\\": \\"0130\\", \\"issuer\\": \\"Expressbank\\", \\"method\\": \\"Card\\", \\"offset\\": 0, \\"refund\\": [], \\"status\\": \\"00\\", \\"system\\": \\"Visa\\", \\"message\\": \\"OK (No error)\\", \\"approval\\": \\"052500\\", \\"currency\\": \\"AZN\\", \\"datetime\\": \\"2026-09-16T15:42:21.000\\", \\"reference\\": \\"MOB-1dc5a89f-60bb-48b5-a5cb-9d235e639a92\\", \\"transactionList\\": []}"
        },
        {
            "purpose": "Balans artımı",
            "ampunt": "5.00",
            "created_balance": "2026-09-16 23:44:17",
            "payload": "{\\"fee\\": 0, \\"pan\\": \\"424242******0017\\", \\"rrn\\": \\"625923308378\\", \\"code\\": 0, \\"amount\\": 5, \\"issuer\\": \\"Expressbank\\", \\"method\\": \\"Card\\", \\"status\\": \\"00\\", \\"system\\": \\"Visa\\", \\"message\\": \\"OK (No error)\\", \\"approval\\": \\"681638\\", \\"currency\\": \\"AZN\\", \\"datetime\\": \\"2026-09-16T23:44:31.000\\", \\"reference\\": \\"WEB-8b635dc0-d311-479c-bc68-0fa2f9897d6d\\"}"
        }
    ],
    "transactions": {
        "data": [
            {
                "id": 14415,
                "main_id": 1398,
                "amount": "1.00",
                "created_at": "2026-09-16T08:13:19.000000Z"
            },
            {
                "id": 14328,
                "main_id": 1398,
                "amount": "3.00",
                "created_at": "2026-09-15T08:12:00.000000Z"
            }
        ],
        "current_page": 1,
        "per_page": 20,
        "total": 2,
        "last_page": 1
    }
}
''';

BuffetCardContentModel _parse([String body = _body]) =>
    BuffetCardContentModel.fromJson(jsonDecode(body) as Map<String, dynamic>);

void main() {
  group('incoming', () {
    test('reads the row, including the API\'s "ampunt" spelling', () {
      final content = _parse();

      expect(content.topUps, hasLength(2));
      final first = content.topUps.first;
      expect(first.purpose, 'Balans artımı');
      expect(first.amount, 1);
      expect(first.date, DateTime(2026, 9, 16, 15, 41, 34));
    });

    test('parses the gateway payload out of its JSON string', () {
      final receipt = _parse().topUps.first.receipt!;

      expect(receipt.pan, '424242******0017');
      expect(receipt.rrn, '625915189514');
      expect(receipt.approval, '052500');
      expect(receipt.reference, 'MOB-1dc5a89f-60bb-48b5-a5cb-9d235e639a92');
      expect(receipt.issuer, 'Expressbank');
      expect(receipt.system, 'Visa');
      expect(receipt.method, 'Card');
      expect(receipt.amount, 1);
      expect(receipt.fee, 0);
      expect(receipt.currency, 'AZN');
      expect(receipt.message, 'OK (No error)');
      expect(receipt.datetime, DateTime(2026, 9, 16, 15, 42, 21));
      expect(receipt.isSuccess, isTrue);
    });

    test('an unusable payload costs the row its receipt, not the response', () {
      final content = _parse('''
{
  "user_id": 1,
  "card": [],
  "incoming": [
    {"purpose": "Balans artımı", "ampunt": "2.00", "payload": "not json"},
    {"purpose": "Balans artımı", "ampunt": "3.00", "payload": null},
    {"purpose": "Balans artımı", "ampunt": "4.00", "payload": "{}"}
  ]
}
''');

      expect(content.topUps, hasLength(3));
      expect(content.topUps.map((e) => e.receipt), everyElement(isNull));
      expect(content.topUps.map((e) => e.amount), [2, 3, 4]);
    });

    test('a response without the block simply has no top-ups', () {
      final content = _parse('{"user_id": 1, "card": [], "transactions": {}}');

      expect(content.topUps, isEmpty);
      expect(content.transactions, isEmpty);
    });

    test('a failed payment is reported as one', () {
      final content = _parse('''
{
  "user_id": 1,
  "card": [],
  "incoming": [
    {"purpose": "Balans artımı", "ampunt": "5.00",
     "payload": "{\\"code\\": 116, \\"status\\": \\"116\\", \\"message\\": \\"Not enough funds\\", \\"rrn\\": \\"1\\"}"}
  ]
}
''');

      expect(content.topUps.single.receipt!.isSuccess, isFalse);
    });
  });

  group('state', () {
    test('sorts top-ups newest first, undated ones last', () {
      final content = _parse();
      final state = BuffetCardState(
        status: BuffetCardStatus.loaded,
        topUps: content.topUps,
      );

      // The API sends them oldest first.
      expect(content.topUps.first.amount, 1);
      expect(state.recentTopUps.map((e) => e.amount), [5, 1]);
    });

    test('still sorts purchases newest first', () {
      final state = BuffetCardState(transactions: _parse().transactions);

      expect(state.recentTransactions.first.id, 14415);
    });
  });
}
