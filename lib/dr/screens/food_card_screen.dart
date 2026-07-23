import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/buffet_cart/domain/entities/buffet_card.dart';
import '../../features/buffet_cart/domain/entities/buffet_transaction.dart';
import '../../features/buffet_cart/presentation/bloc/buffet_card_bloc.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import 'cafeteria_screen.dart';

/// Port of `idcard.html`, backed by `GET /getBuffetCart` — the daily-limit
/// card, the barcode card slider and the recent buffet purchases.
class FoodCardScreen extends StatelessWidget {
  const FoodCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BuffetCardBloc>()..add(const BuffetCardFetched()),
      child: const _FoodCardView(),
    );
  }
}

class _FoodCardView extends StatefulWidget {
  const _FoodCardView();

  @override
  State<_FoodCardView> createState() => _FoodCardViewState();
}

class _FoodCardViewState extends State<_FoodCardView> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<BuffetCardBloc, BuffetCardState>(
        builder: (context, state) {
          final bloc = context.read<BuffetCardBloc>();
          return RefreshIndicator(
            onRefresh: () async => bloc.add(const BuffetCardRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const DrBackHeader(title: 'Bufet Kartım', showBack: false),
                ..._body(context, state),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, BuffetCardState state) {
    final card = state.card;

    if (card == null && state.isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (card == null && state.status == BuffetCardStatus.error) {
      return [
        _Message(
          text: state.errorMessage ?? 'Xəta baş verdi',
          onRetry: () =>
              context.read<BuffetCardBloc>().add(const BuffetCardRefreshed()),
        ),
      ];
    }

    if (card == null) {
      return const [_Message(text: 'Bufet kartı tapılmadı')];
    }

    final transactions = state.recentTransactions;

    return [
      const SizedBox(height: 8),
      SizedBox(
        height: 150,
        child: PageView(
          controller: _controller,
          onPageChanged: (i) => setState(() => _index = i),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _LimitCard(card: card),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 4),
            //   child: _BarcodeCard(card: card),
            // ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(1, (i) {
          final active = i == _index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? DrColors.accentGreen : context.dr.border,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
      const SizedBox(height: 24),
      DrSectionHeader(
        title: 'Son əməliyyatlar',
        // action: 'Hamısı',
        onAction: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CafeteriaScreen())),
      ),
      if (transactions.isEmpty)
        const _Message(text: 'Hələ əməliyyat yoxdur')
      else
        DrListCard(
          children: [
            for (var i = 0; i < transactions.length; i++)
              _TransactionTile(
                transaction: transactions[i],
                divider: i != transactions.length - 1,
              ),
          ],
        ),
    ];
  }
}

/// Formats an AZN amount as `X.XX ₼`.
String _money(num value) => '${value.toStringAsFixed(2)} ₼';

class _TransactionTile extends StatelessWidget {
  final BuffetTransaction transaction;
  final bool divider;
  const _TransactionTile({required this.transaction, this.divider = true});

  @override
  Widget build(BuildContext context) {
    final date = transaction.date;
    final subtitle = date == null
        ? '—'
        : DateFormat('dd MMM yyyy, HH:mm').format(date);
    final amount = transaction.amount;

    return DrTransactionTile(
      leading: const DrEmojiBadge(emoji: '🍽️', color: DrColors.orange),
      title: transaction.title ?? 'Alış',
      subtitle: subtitle,
      trailing: _Amount(amount == null ? '—' : '- ${_money(amount)}'),
    );
  }
}

class _Amount extends StatelessWidget {
  final String text;
  const _Amount(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  );
}

class _LimitCard extends StatelessWidget {
  final BuffetCard card;
  const _LimitCard({required this.card});

  @override
  Widget build(BuildContext context) {
    // Money cards show the AZN balance; meal-only cards (money_balance == null)
    // show the remaining daily allowance instead.
    final money = card.moneyBalance;
    final (balanceLabel, balanceValue) = money != null
        ? ('Balans', _money(money))
        : ('Qalıq', '${card.balance ?? 0} ₼');

    final usage = card.usage;
    final fixedUsage = card.fixedUsage;
    final usageText = (usage != null && fixedUsage != null)
        ? 'Günlük: $usage/$fixedUsage'
        : null;

    return DrGlowCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _amountColumn(
                context,
                'Kart nömrəsi',
                card.cardId1 ?? '—',
                DrColors.accentGreen,
              ),
              _amountColumn(
                context,
                balanceLabel,
                balanceValue,
                context.dr.textMain,
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  [
                    card.fullName,
                  ].where((e) => e != null && e.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                ),
              ),
              if (usageText != null)
                Text(
                  usageText,
                  style: TextStyle(fontSize: 12, color: context.dr.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountColumn(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.dr.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

///
///
/// ikinci slider ucun
///
///
// class _BarcodeCard extends StatelessWidget {
//   final BuffetCard card;
//   const _BarcodeCard({required this.card});

//   @override
//   Widget build(BuildContext context) {
//     final name = card.fullName.isEmpty
//         ? 'STUDENT'
//         : card.fullName.toUpperCase();
//     final code = card.cardId1 ?? '—';

//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   name,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: 1,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//               Container(
//                 width: 35,
//                 height: 25,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
//                   ),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//             ],
//           ),
//           const Spacer(),
//           const _Barcode(),
//           const SizedBox(height: 10),
//           Text(
//             code,
//             style: const TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 2,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 8,
//                 height: 8,
//                 decoration: const BoxDecoration(
//                   color: DrColors.green,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 'Ready to Scan',
//                 style: TextStyle(
//                   color: Color(0xFF666666),
//                   fontSize: 11,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//           const Spacer(),
//         ],
//       ),
//     );
//   }
// }

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.dr.textMuted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Yenidən cəhd et'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Faux Code-128 barcode rendered with stripes.
class _Barcode extends StatelessWidget {
  const _Barcode();
  @override
  Widget build(BuildContext context) {
    const widths = <double>[
      3,
      1,
      2,
      1,
      1,
      3,
      2,
      1,
      1,
      2,
      3,
      1,
      2,
      2,
      1,
      1,
      3,
      1,
      2,
      1,
      2,
      3,
      1,
      1,
      2,
      1,
      3,
      2,
      1,
      1,
      2,
      1,
      3,
      1,
      2,
      2,
      1,
      3,
      1,
      2,
      1,
      1,
    ];
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widths.length; i++)
            Container(
              width: widths[i],
              color: i.isEven ? Colors.black : Colors.transparent,
            ),
        ],
      ),
    );
  }
}
