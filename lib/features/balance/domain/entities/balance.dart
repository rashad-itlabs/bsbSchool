import 'package:equatable/equatable.dart';

class Balance extends Equatable {
  final double amount; // AZN

  const Balance(this.amount);

  @override
  List<Object?> get props => [amount];
}
