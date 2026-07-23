import '../../domain/entities/buffet_card_content.dart';
import 'buffet_card_model.dart';
import 'buffet_transaction_model.dart';

class BuffetCardContentModel extends BuffetCardContent {
  const BuffetCardContentModel({
    super.userId,
    super.cards,
    super.transactions,
    super.currentPage,
    super.lastPage,
    super.total,
  });

  /// Matches the whole `GET /getBuffetCart` body:
  /// ```json
  /// { "user_id": 2570,
  ///   "card": [ { ... } ],
  ///   "transactions": { "data": [ ... ], "current_page": 1,
  ///                     "last_page": 1, "total": 0 } }
  /// ```
  factory BuffetCardContentModel.fromJson(Map<String, dynamic> json) {
    final rawCards = json['card'];
    final cards = rawCards is List
        ? rawCards
            .whereType<Map>()
            .map((e) => BuffetCardModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <BuffetCardModel>[];

    final tx = json['transactions'];
    final txMap =
        tx is Map ? Map<String, dynamic>.from(tx) : const <String, dynamic>{};

    final rawTransactions = txMap['data'];
    final transactions = rawTransactions is List
        ? rawTransactions
            .whereType<Map>()
            .map((e) =>
                BuffetTransactionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <BuffetTransactionModel>[];

    return BuffetCardContentModel(
      userId: _asInt(json['user_id']),
      cards: cards,
      transactions: transactions,
      currentPage: _asInt(txMap['current_page']) ?? 1,
      lastPage: _asInt(txMap['last_page']) ?? 1,
      total: _asInt(txMap['total']) ?? 0,
    );
  }

  static int? _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}
