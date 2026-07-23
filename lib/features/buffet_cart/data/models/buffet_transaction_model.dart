import '../../domain/entities/buffet_transaction.dart';

class BuffetTransactionModel extends BuffetTransaction {
  const BuffetTransactionModel({
    super.id,
    super.title,
    super.amount,
    super.date,
    super.note,
  });

  /// Matches one entry of `transactions.data` from `GET /getBuffetCart`.
  ///
  /// The sample page was empty, so we probe the field names the buffet backend
  /// is most likely to use and degrade gracefully when one is absent.
  factory BuffetTransactionModel.fromJson(Map<String, dynamic> json) =>
      BuffetTransactionModel(
        id: _asInt(json['id']),
        title: _asString(json['product']) ??
            _asString(json['product_name']) ??
            _asString(json['name']) ??
            _asString(json['title']) ??
            _asString(json['note']),
        amount: _asNum(json['amount']) ??
            _asNum(json['price']) ??
            _asNum(json['money']) ??
            _asNum(json['total']),
        date: _asDate(json['created_at']) ??
            _asDate(json['date']) ??
            _asDate(json['transaction_date']),
        note: _asString(json['note']),
      );

  static int? _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  static num? _asNum(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '');

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
