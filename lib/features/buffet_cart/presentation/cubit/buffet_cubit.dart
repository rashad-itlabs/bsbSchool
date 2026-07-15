import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/place_order.dart';

part 'buffet_state.dart';

class BuffetCubit extends Cubit<BuffetState> {
  final GetProducts getProducts;
  final PlaceOrder placeOrder;

  BuffetCubit({required this.getProducts, required this.placeOrder})
      : super(const BuffetState());

  Future<void> loadProducts() async {
    emit(state.copyWith(status: BuffetStatus.loading));
    final result = await getProducts(const NoParams());
    result.fold(
      (f) => emit(state.copyWith(status: BuffetStatus.error, message: f.message)),
      (products) =>
          emit(state.copyWith(status: BuffetStatus.loaded, products: products)),
    );
  }

  void addToCart(Product product) {
    final cart = Map<String, CartItem>.from(state.cart);
    final existing = cart[product.id];
    cart[product.id] = existing == null
        ? CartItem(product: product, quantity: 1)
        : existing.copyWith(quantity: existing.quantity + 1);
    emit(state.copyWith(cart: cart, clearMessage: true));
  }

  void removeOne(String productId) {
    final cart = Map<String, CartItem>.from(state.cart);
    final existing = cart[productId];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      cart.remove(productId);
    } else {
      cart[productId] = existing.copyWith(quantity: existing.quantity - 1);
    }
    emit(state.copyWith(cart: cart, clearMessage: true));
  }

  void clearCart() => emit(state.copyWith(cart: {}, clearMessage: true));

  Future<void> checkout() async {
    if (state.cart.isEmpty) return;
    emit(state.copyWith(status: BuffetStatus.processing));
    final result = await placeOrder(state.cart.values.toList());
    result.fold(
      (f) => emit(state.copyWith(
        status: BuffetStatus.loaded,
        message: f.message,
      )),
      (newBalance) => emit(state.copyWith(
        status: BuffetStatus.orderPlaced,
        cart: {},
        newBalance: newBalance,
        message: 'Sifariş təsdiqləndi ✓',
      )),
    );
  }
}
