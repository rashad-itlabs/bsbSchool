import 'package:equatable/equatable.dart';

/// One entry of the `card` array from `GET /getBuffetCart` — the student's
/// physical buffet card with its balances and daily-usage limits.
class BuffetCard extends Equatable {
  final int? id;
  final int? userId;
  final String? firstname;
  final String? lastname;
  final String? className;

  /// Printed card numbers; [cardId1] is the primary one shown as a barcode.
  final String? cardId1;
  final String? cardId2;

  /// Remaining daily meal allowance (a whole-meal count, not money).
  final num? balance;

  /// Money loaded on the card, in AZN. `null` for meal-only cards.
  final num? moneyBalance;

  final DateTime? balanceCreated;

  /// Meals used today.
  final int? usage;

  /// Meals allowed per day.
  final int? fixedUsage;

  final int? monthlyLimit;
  final String? note;
  final int? status;
  final String? stStatus;
  final String? category;

  const BuffetCard({
    this.id,
    this.userId,
    this.firstname,
    this.lastname,
    this.className,
    this.cardId1,
    this.cardId2,
    this.balance,
    this.moneyBalance,
    this.balanceCreated,
    this.usage,
    this.fixedUsage,
    this.monthlyLimit,
    this.note,
    this.status,
    this.stStatus,
    this.category,
  });

  /// `"Firstname Lastname"`, skipping whichever half is missing.
  String get fullName => [
        firstname,
        lastname,
      ].where((e) => e != null && e.trim().isNotEmpty).join(' ');

  @override
  List<Object?> get props => [
        id,
        userId,
        firstname,
        lastname,
        className,
        cardId1,
        cardId2,
        balance,
        moneyBalance,
        balanceCreated,
        usage,
        fixedUsage,
        monthlyLimit,
        note,
        status,
        stStatus,
        category,
      ];
}
