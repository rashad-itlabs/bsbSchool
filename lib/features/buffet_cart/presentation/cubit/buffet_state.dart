part of 'buffet_cubit.dart';

enum BuffetStatus { initial, loading, loaded, processing, orderPlaced, error }

class BuffetState extends Equatable {
  final BuffetStatus status;
  final List<Product> products;
  final Map<String, CartItem> cart;
  final double? newBalance; // set after a successful checkout
  final String? message;

  const BuffetState({
    this.status = BuffetStatus.initial,
    this.products = const [],
    this.cart = const {},
    this.newBalance,
    this.message,
  });

  int get cartCount =>
      cart.values.fold(0, (sum, item) => sum + item.quantity);

  double get cartTotal =>
      cart.values.fold(0.0, (sum, item) => sum + item.total);

  BuffetState copyWith({
    BuffetStatus? status,
    List<Product>? products,
    Map<String, CartItem>? cart,
    double? newBalance,
    String? message,
    bool clearMessage = false,
  }) =>
      BuffetState(
        status: status ?? this.status,
        products: products ?? this.products,
        cart: cart ?? this.cart,
        newBalance: newBalance ?? this.newBalance,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, products, cart, newBalance, message];
}
