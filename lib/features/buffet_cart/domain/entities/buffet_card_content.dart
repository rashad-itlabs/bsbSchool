import 'package:equatable/equatable.dart';

import 'buffet_card.dart';
import 'buffet_transaction.dart';

/// The full `GET /getBuffetCart` payload: the owning [userId], the student's
/// [cards] (the API returns an array — the first is the active card), and the
/// paginated purchase [transactions].
class BuffetCardContent extends Equatable {
  final int? userId;
  final List<BuffetCard> cards;
  final List<BuffetTransaction> transactions;

  /// Paging metadata from the `transactions` block.
  final int currentPage;
  final int lastPage;
  final int total;

  const BuffetCardContent({
    this.userId,
    this.cards = const [],
    this.transactions = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  /// The card shown on the screen — the first the API returned, or null when
  /// the student has none.
  BuffetCard? get card => cards.isEmpty ? null : cards.first;

  @override
  List<Object?> get props => [
        userId,
        cards,
        transactions,
        currentPage,
        lastPage,
        total,
      ];
}
