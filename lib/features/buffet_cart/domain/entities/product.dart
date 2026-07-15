import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final double price; // AZN
  final String category;
  final String emoji;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.emoji = '🍽️',
  });

  @override
  List<Object?> get props => [id, name, price, category, emoji];
}

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get total => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}
