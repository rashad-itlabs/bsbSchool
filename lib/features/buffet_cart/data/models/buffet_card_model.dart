import '../../domain/entities/buffet_card.dart';

class BuffetCardModel extends BuffetCard {
  const BuffetCardModel({
    super.id,
    super.userId,
    super.firstname,
    super.lastname,
    super.className,
    super.cardId1,
    super.cardId2,
    super.balance,
    super.moneyBalance,
    super.balanceCreated,
    super.usage,
    super.fixedUsage,
    super.monthlyLimit,
    super.note,
    super.status,
    super.stStatus,
    super.category,
  });

  /// Matches one entry of the `card` array returned by `GET /getBuffetCart`.
  factory BuffetCardModel.fromJson(Map<String, dynamic> json) => BuffetCardModel(
        id: _asInt(json['id']),
        userId: _asInt(json['user_id']),
        firstname: _asString(json['firstname']),
        lastname: _asString(json['lastname']),
        className: _asString(json['class_name']),
        cardId1: _asString(json['card_id_1']),
        cardId2: _asString(json['card_id_2']),
        balance: _asNum(json['balance']),
        moneyBalance: _asNum(json['money_balance']),
        balanceCreated: _asDate(json['balance_created']),
        // The API sends `usage` as a string ("2"); coerce it like the rest.
        usage: _asInt(json['usage']),
        fixedUsage: _asInt(json['fixed_usage']),
        monthlyLimit: _asInt(json['monthly_limit']),
        note: _asString(json['note']),
        status: _asInt(json['status']),
        stStatus: _asString(json['st_status']),
        category: _asString(json['category']),
      );

  static int? _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  static num? _asNum(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '');

  /// The API sends `null` for missing values; empty strings mean the same.
  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Dates come as `yyyy-MM-dd HH:mm:ss`; a bad value degrades to null.
  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
