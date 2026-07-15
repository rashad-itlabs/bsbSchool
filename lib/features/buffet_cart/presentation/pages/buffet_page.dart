import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../balance/presentation/cubit/balance_cubit.dart';
import '../../domain/entities/product.dart';
import '../cubit/buffet_cubit.dart';

class BuffetPage extends StatelessWidget {
  const BuffetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BuffetCubit>()..loadProducts(),
      child: const _BuffetView(),
    );
  }
}

class _BuffetView extends StatelessWidget {
  const _BuffetView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bufet')),
      body: BlocConsumer<BuffetCubit, BuffetState>(
        listenWhen: (p, c) =>
            c.message != null && c.message != p.message,
        listener: (context, state) {
          // Keep the global balance in sync after a successful order.
          if (state.status == BuffetStatus.orderPlaced &&
              state.newBalance != null) {
            context.read<BalanceCubit>().syncAmount(state.newBalance!);
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        },
        builder: (context, state) {
          if (state.status == BuffetStatus.loading ||
              state.status == BuffetStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, i) {
                    final product = state.products[i];
                    final qty = state.cart[product.id]?.quantity ?? 0;
                    return _ProductCard(product: product, quantity: qty);
                  },
                ),
              ),
              if (state.cart.isNotEmpty) _CartBar(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  const _ProductCard({required this.product, required this.quantity});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BuffetCubit>();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.emoji, style: const TextStyle(fontSize: 36)),
            const Spacer(),
            Text(product.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(product.category,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${product.price.toStringAsFixed(2)} AZN',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                if (quantity == 0)
                  IconButton.filled(
                    onPressed: () => cubit.addToCart(product),
                    icon: const Icon(Icons.add, size: 18),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => cubit.removeOne(product.id),
                        icon: const Icon(Icons.remove_circle_outline),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text('$quantity'),
                      IconButton(
                        onPressed: () => cubit.addToCart(product),
                        icon: const Icon(Icons.add_circle),
                        color: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final BuffetState state;
  const _CartBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final processing = state.status == BuffetStatus.processing;
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${state.cartCount} məhsul',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  Text('${state.cartTotal.toStringAsFixed(2)} AZN',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: processing
                    ? null
                    : () => context.read<BuffetCubit>().checkout(),
                icon: processing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.shopping_cart_checkout),
                label: const Text('Sifariş et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
