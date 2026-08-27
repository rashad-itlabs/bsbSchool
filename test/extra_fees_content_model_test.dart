import 'dart:convert';

import 'package:bsbschool/features/extra_fees/data/models/extra_fees_content_model.dart';
import 'package:bsbschool/features/extra_fees/domain/entities/extra_fee.dart';
import 'package:bsbschool/features/extra_fees/presentation/bloc/extra_fees_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real `GET /extra_fees` response: one unpaid, already overdue fee.
const _extraFeesBody = '''
{
    "success": true,
    "student_id": 2570,
    "student_name": "Fakhraddin  Alizade",
    "class_id": 96,
    "class_name": "Class Group 9",
    "currency": "AZN",
    "summary": {
        "total": 20,
        "total_minor": 2000,
        "paid": 0,
        "paid_minor": 0,
        "outstanding": 20,
        "outstanding_minor": 2000,
        "unpaid_count": 1,
        "overdue_count": 1
    },
    "fees": [
        {
            "id": 3,
            "fee_id": 3,
            "title": "test",
            "description": "test",
            "due_date": "2026-08-20",
            "class_id": 97,
            "amount": 20,
            "amount_minor": 2000,
            "paid": 0,
            "paid_minor": 0,
            "remaining": 20,
            "remaining_minor": 2000,
            "status": "unpaid",
            "status_label": "Unpaid",
            "is_overdue": true,
            "is_payable": true,
            "last_payment": null
        }
    ],
    "children": [
        {
            "student_id": 2570,
            "name": "Fakhraddin  Alizade",
            "outstanding": 20,
            "outstanding_minor": 2000,
            "selected": true
        }
    ]
}
''';

ExtraFeesContentModel _parse(String body) =>
    ExtraFeesContentModel.fromJson(jsonDecode(body) as Map<String, dynamic>);

ExtraFeesState _stateOf(ExtraFeesContentModel content) => ExtraFeesState(
  status: ExtraFeesStatus.loaded,
  studentId: content.studentId,
  currency: content.currency,
  summary: content.summary,
  fees: content.fees,
  children: content.children,
);

void main() {
  test('parses the student, the totals and the fee', () {
    final content = _parse(_extraFeesBody);

    expect(content.studentId, 2570);
    expect(content.className, 'Class Group 9');
    expect(content.currency, 'AZN');
    expect(content.summary.total, 20);
    expect(content.summary.outstanding, 20);
    expect(content.summary.unpaidCount, 1);
    expect(content.summary.overdueCount, 1);
    expect(content.children.single.outstanding, 20);
    expect(content.children.single.selected, isTrue);
  });

  test('reads every field of a fee row', () {
    final fee = _parse(_extraFeesBody).fees.single;

    expect(fee.id, 3);
    expect(fee.feeId, 3);
    expect(fee.title, 'test');
    expect(fee.description, 'test');
    expect(fee.dueDate, DateTime(2026, 8, 20));
    // The fee was raised against another class group; kept, not assumed away.
    expect(fee.classId, 97);
    expect(fee.amount, 20);
    expect(fee.paid, 0);
    expect(fee.remaining, 20);
    expect(fee.status, ExtraFeeStatus.unpaid);
    expect(fee.statusLabel, 'Unpaid');
    expect(fee.isOverdue, isTrue);
    expect(fee.isPayable, isTrue);
    expect(fee.lastPayment, isNull);
  });

  test('an unknown status label is kept without claiming money is owed', () {
    final fee = _parse('''
{"success": true, "fees": [{"id": 9, "amount": 30, "paid": 30,
  "remaining": 0, "status": "waived", "status_label": "Waived",
  "is_payable": false}]}
''').fees.single;

    expect(fee.status, ExtraFeeStatus.other);
    expect(fee.statusLabel, 'Waived');
    expect(fee.isOutstanding, isFalse);
    expect(fee.isPaid, isFalse);
  });

  test('summary progress is the settled share, clamped', () {
    final summary = _parse('''
{"success": true, "summary": {"total": 200, "paid": 50, "outstanding": 150}}
''').summary;

    expect(summary.progress, closeTo(0.25, 0.0001));

    // A refund can leave `paid` above `total` for a moment.
    final over = _parse('''
{"success": true, "summary": {"total": 100, "paid": 180, "outstanding": 0}}
''').summary;

    expect(over.progress, 1);
    expect(over.hasOutstanding, isFalse);
  });

  test('part-paid fee reports itself as partial with its own progress', () {
    final fee = _parse('''
{"success": true, "fees": [{"id": 4, "title": "Trip", "amount": 80,
  "paid": 20, "remaining": 60, "status": "partial",
  "status_label": "Partly paid", "is_payable": true,
  "last_payment": "2026-08-01"}]}
''').fees.single;

    expect(fee.isPartial, isTrue);
    expect(fee.isOutstanding, isTrue);
    expect(fee.progress, closeTo(0.25, 0.0001));
    expect(fee.lastPayment, DateTime(2026, 8, 1));
  });

  test('sorts unpaid fees first, then by due date', () {
    final state = _stateOf(_parse('''
{
    "success": true,
    "fees": [
        {"id": 1, "title": "Paid early", "due_date": "2026-07-01",
         "amount": 10, "paid": 10, "remaining": 0, "status": "paid",
         "is_payable": false},
        {"id": 2, "title": "Later", "due_date": "2026-10-01", "amount": 10,
         "remaining": 10, "status": "unpaid", "is_payable": true},
        {"id": 3, "title": "Undated", "amount": 10, "remaining": 10,
         "status": "unpaid", "is_payable": true},
        {"id": 4, "title": "Sooner", "due_date": "2026-09-01", "amount": 10,
         "remaining": 10, "status": "unpaid", "is_payable": true}
    ]
}
'''));

    // Owing first (by due date, undated last), settled after.
    expect(state.sortedFees.map((f) => f.id), [4, 2, 3, 1]);
    expect(state.outstandingFees, hasLength(3));
    expect(state.payableFees, hasLength(3));
  });

  test('pay-all falls back to the rows when the summary sends no total', () {
    final state = _stateOf(_parse('''
{
    "success": true,
    "fees": [
        {"id": 1, "amount": 25, "remaining": 25, "status": "unpaid",
         "is_payable": true},
        {"id": 2, "amount": 15, "remaining": 5, "status": "partial",
         "is_payable": true},
        {"id": 3, "amount": 10, "remaining": 0, "status": "paid",
         "is_payable": false}
    ]
}
'''));

    expect(state.payableAmount, 30);
    // No `unpaid_count` in the payload, so the badge counts the rows.
    expect(state.pendingCount, 2);
  });

  test('summary total wins over the rows when both are present', () {
    final state = _stateOf(_parse(_extraFeesBody));

    expect(state.payableAmount, 20);
    expect(state.pendingCount, 1);
  });

  test('survives a payload with nothing in it', () {
    final state = _stateOf(_parse('{"success": true}'));

    expect(state.currency, 'AZN');
    expect(state.fees, isEmpty);
    expect(state.isEmpty, isTrue);
    expect(state.payableAmount, 0);
    expect(state.pendingCount, 0);
    expect(state.summary.progress, 0);
  });
}
