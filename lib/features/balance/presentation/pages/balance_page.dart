import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../cubit/balance_cubit.dart';

/// Expects a [BalanceCubit] to be provided above it in the tree
/// (see HomePage / injection_container).
class BalancePage extends StatelessWidget {
  const BalancePage({super.key});

  static const _presets = [5.0, 10.0, 20.0, 50.0];

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Balans')),
      body: BlocConsumer<BalanceCubit, BalanceState>(
        listenWhen: (p, c) => c.message != null && c.message != p.message,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!)));
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BalanceCard(amount: state.amount),
              const SizedBox(height: 24),
              const Text('Sürətli artırma',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presets
                    .map((v) => ActionChip(
                          label: Text('+${v.toStringAsFixed(0)} AZN'),
                          onPressed: () =>
                              context.read<BalanceCubit>().topUp(v),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              const Text('Xüsusi məbləğ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  hintText: 'Məbləğ (AZN)',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final value = double.tryParse(
                      controller.text.trim().replaceAll(',', '.'));
                  if (value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Düzgün məbləğ daxil edin')),
                    );
                    return;
                  }
                  context.read<BalanceCubit>().topUp(value);
                  controller.clear();
                },
                icon: const Icon(Icons.add_card),
                label: const Text('Balansı artır'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double amount;
  const _BalanceCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mövcud balans',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '${amount.toStringAsFixed(2)} AZN',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
