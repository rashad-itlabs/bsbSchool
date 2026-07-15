part of 'balance_cubit.dart';

enum BalanceStatus { initial, loading, loaded, error }

class BalanceState extends Equatable {
  final BalanceStatus status;
  final double amount;
  final String? message;

  const BalanceState({
    this.status = BalanceStatus.initial,
    this.amount = 0,
    this.message,
  });

  BalanceState copyWith({
    BalanceStatus? status,
    double? amount,
    String? message,
  }) =>
      BalanceState(
        status: status ?? this.status,
        amount: amount ?? this.amount,
        message: message,
      );

  @override
  List<Object?> get props => [status, amount, message];
}
