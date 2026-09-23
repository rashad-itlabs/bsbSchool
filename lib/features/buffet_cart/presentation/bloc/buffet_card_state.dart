part of 'buffet_card_bloc.dart';

enum BuffetCardStatus { initial, loading, loaded, error }

class BuffetCardState extends Equatable {
  final BuffetCardStatus status;

  final int? userId;

  /// The active card, or null while loading and when the student has none.
  final BuffetCard? card;

  /// Purchases the API returned, newest first once sorted.
  final List<BuffetTransaction> transactions;

  /// Balance top-ups the API returned, newest first once sorted.
  final List<BuffetTopUp> topUps;

  final String? errorMessage;

  const BuffetCardState({
    this.status = BuffetCardStatus.initial,
    this.userId,
    this.card,
    this.transactions = const [],
    this.topUps = const [],
    this.errorMessage,
  });

  bool get isLoading => status == BuffetCardStatus.loading;

  /// Transactions sorted newest first for the "recent" list.
  List<BuffetTransaction> get recentTransactions =>
      _newestFirst(transactions, (e) => e.date);

  /// Top-ups sorted newest first — the API sends them oldest first.
  List<BuffetTopUp> get recentTopUps => _newestFirst(topUps, (e) => e.date);

  /// Sorts a copy by date, newest first, with undated rows last.
  static List<T> _newestFirst<T>(List<T> items, DateTime? Function(T) dateOf) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final ad = dateOf(a), bd = dateOf(b);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return sorted;
  }

  BuffetCardState copyWith({
    BuffetCardStatus? status,
    int? userId,
    BuffetCard? card,
    List<BuffetTransaction>? transactions,
    List<BuffetTopUp>? topUps,
    String? errorMessage,
  }) {
    return BuffetCardState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      card: card ?? this.card,
      transactions: transactions ?? this.transactions,
      topUps: topUps ?? this.topUps,
      // Intentionally not carried over: only the state that failed shows it.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, userId, card, transactions, topUps, errorMessage];
}
