import 'dart:convert';

import 'package:bsbschool/features/tuition/data/models/tuition_content_model.dart';
import 'package:bsbschool/features/tuition/domain/entities/tuition_charge.dart';
import 'package:bsbschool/features/tuition/domain/entities/tuition_payment.dart';
import 'package:bsbschool/features/tuition/presentation/bloc/tuition_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real `GET /tuition` response, trimmed to the rows that matter here:
/// one partly paid instalment, two open ones, and a ledger covering every
/// payment status the API sends.
const _tuitionBody = '''
{
    "success": true,
    "student_id": 2570,
    "student_name": "Fakhraddin  Alizade",
    "class_id": 96,
    "class_name": "Class Group 9",
    "currency": "AZN",
    "summary": {
        "balance": 15678,
        "balance_minor": 1567800,
        "due_now": 0,
        "due_now_minor": 0,
        "late_fee": 78,
        "late_fee_minor": 7800,
        "credit": 0,
        "credit_minor": 0,
        "suggested": 15678,
        "suggested_minor": 1567800
    },
    "charges": [
        {
            "id": 44,
            "due_date": "2026-11-05",
            "type": "tuition",
            "type_label": "Tuition",
            "amount": 1600,
            "amount_minor": 160000,
            "status": "open",
            "status_label": "Unpaid",
            "is_overdue": false
        },
        {
            "id": 42,
            "due_date": "2026-09-05",
            "type": "tuition",
            "type_label": "Tuition",
            "amount": 1600,
            "amount_minor": 160000,
            "status": "partial",
            "status_label": "Partly paid",
            "is_overdue": false
        },
        {
            "id": 41,
            "due_date": "2026-08-05",
            "type": "tuition",
            "type_label": "Tuition",
            "amount": 1600,
            "amount_minor": 160000,
            "status": "paid",
            "status_label": "Paid",
            "is_overdue": false
        }
    ],
    "payments": [
        {
            "id": 30,
            "date": "2026-08-08 13:42:50",
            "method": "online_card",
            "method_label": "Ecom - Card",
            "amount": 122,
            "amount_minor": 12200,
            "status": "paid",
            "status_label": "Paid",
            "reason": null
        },
        {
            "id": 23,
            "date": "2026-08-06 02:22:16",
            "method": "online_card",
            "method_label": "Ecom - Card",
            "amount": 100,
            "amount_minor": 10000,
            "status": "failed",
            "status_label": "Failed",
            "reason": "Declined: not enough money on the card"
        },
        {
            "id": 20,
            "date": "2026-08-06 02:17:54",
            "method": "online_card",
            "method_label": "Ecom - Card",
            "amount": 100,
            "amount_minor": 10000,
            "status": "initiated",
            "status_label": "Started",
            "reason": null
        },
        {
            "id": 16,
            "date": "2026-08-06 01:17:43",
            "method": "online_card",
            "method_label": "Ecom - Card",
            "amount": 15499,
            "amount_minor": 1549900,
            "status": "refunded",
            "status_label": "Refunded",
            "reason": "Approved"
        }
    ],
    "children": [
        {
            "student_id": 2570,
            "name": "Fakhraddin  Alizade",
            "balance": 15678,
            "balance_minor": 1567800,
            "selected": true
        }
    ]
}
''';

TuitionContentModel _parse(String body) =>
    TuitionContentModel.fromJson(jsonDecode(body) as Map<String, dynamic>);

TuitionState _stateOf(TuitionContentModel content) => TuitionState(
  status: TuitionStatus.loaded,
  studentId: content.studentId,
  currency: content.currency,
  summary: content.summary,
  charges: content.charges,
  payments: content.payments,
  children: content.children,
);

void main() {
  test('parses the student, the totals and every collection', () {
    final content = _parse(_tuitionBody);

    expect(content.studentId, 2570);
    expect(content.className, 'Class Group 9');
    expect(content.currency, 'AZN');
    expect(content.summary.balance, 15678);
    expect(content.summary.suggested, 15678);
    expect(content.charges, hasLength(3));
    expect(content.payments, hasLength(4));
    expect(content.children.single.selected, isTrue);
  });

  test('maps charge and payment statuses onto their enums', () {
    final content = _parse(_tuitionBody);

    expect(
      content.charges.map((c) => c.status),
      [
        TuitionChargeStatus.open,
        TuitionChargeStatus.partial,
        TuitionChargeStatus.paid,
      ],
    );
    expect(
      content.payments.map((p) => p.status),
      [
        TuitionPaymentStatus.paid,
        TuitionPaymentStatus.failed,
        TuitionPaymentStatus.initiated,
        TuitionPaymentStatus.refunded,
      ],
    );
  });

  test('reads both date shapes the payload uses', () {
    final content = _parse(_tuitionBody);

    expect(content.charges.first.dueDate, DateTime(2026, 11, 5));
    expect(content.payments.first.date, DateTime(2026, 8, 8, 13, 42, 50));
  });

  test('principal is the balance without the interest on top', () {
    final summary = _parse(_tuitionBody).summary;

    expect(summary.lateFee, 78);
    expect(summary.principal, 15600);
    expect(summary.hasLateFee, isTrue);
  });

  test('orders the schedule by due date and counts only settled instalments',
      () {
    final state = _stateOf(_parse(_tuitionBody));

    expect(state.schedule.map((c) => c.id), [41, 42, 44]);
    // Partly paid still owes money, so it is not counted as done.
    expect(state.paidCount, 1);
    expect(state.totalCharges, 3);
    expect(state.progress, closeTo(1 / 3, 0.0001));
  });

  test('next charge is the earliest one still owing', () {
    final state = _stateOf(_parse(_tuitionBody));

    expect(state.nextCharge?.id, 42);
    expect(state.nextCharge?.status, TuitionChargeStatus.partial);
  });

  test('payment sheet opens on the suggested amount', () {
    final state = _stateOf(_parse(_tuitionBody));

    expect(state.payableAmount, 15678);
  });

  test('ledger comes back newest first', () {
    final state = _stateOf(_parse(_tuitionBody));

    expect(state.recentPayments.map((p) => p.id), [30, 23, 20, 16]);
  });

  test('survives a payload with nothing in it', () {
    final content = _parse('{"success": true}');
    final state = _stateOf(content);

    expect(content.currency, 'AZN');
    expect(content.summary.balance, 0);
    expect(state.charges, isEmpty);
    expect(state.nextCharge, isNull);
    expect(state.progress, 0);
    expect(state.payableAmount, 0);
  });
}
