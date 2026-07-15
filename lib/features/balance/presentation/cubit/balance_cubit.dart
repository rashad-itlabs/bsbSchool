import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/add_balance.dart';
import '../../domain/usecases/get_balance.dart';

part 'balance_state.dart';

class BalanceCubit extends Cubit<BalanceState> {
  final GetBalance getBalance;
  final AddBalance addBalance;

  BalanceCubit({required this.getBalance, required this.addBalance})
      : super(const BalanceState());

  Future<void> loadBalance() async {
    emit(state.copyWith(status: BalanceStatus.loading));
    final result = await getBalance(const NoParams());
    result.fold(
      (f) => emit(state.copyWith(status: BalanceStatus.error, message: f.message)),
      (b) => emit(state.copyWith(status: BalanceStatus.loaded, amount: b.amount)),
    );
  }

  Future<void> topUp(double amount) async {
    emit(state.copyWith(status: BalanceStatus.loading));
    final result = await addBalance(amount);
    result.fold(
      (f) => emit(state.copyWith(status: BalanceStatus.error, message: f.message)),
      (b) => emit(state.copyWith(
        status: BalanceStatus.loaded,
        amount: b.amount,
        message: '+${amount.toStringAsFixed(2)} AZN əlavə edildi',
      )),
    );
  }

  /// Called by the buffet feature after a successful checkout to keep the
  /// displayed balance in sync.
  void syncAmount(double amount) =>
      emit(state.copyWith(status: BalanceStatus.loaded, amount: amount));
}
