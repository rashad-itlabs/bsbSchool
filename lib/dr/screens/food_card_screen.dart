import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import 'cafeteria_screen.dart';

/// Port of `idcard.html` — daily-limit card + barcode card slider + purchases.
class FoodCardScreen extends StatefulWidget {
  const FoodCardScreen({super.key});

  @override
  State<FoodCardScreen> createState() => _FoodCardScreenState();
}

class _FoodCardScreenState extends State<FoodCardScreen> {
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
      child: ListView(
        children: [
          const DrBackHeader(title: 'Mənim Food Kartım', showBack: false),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: _LimitCard(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: _BarcodeCard(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (i) {
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
            action: 'Hamısı',
            onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CafeteriaScreen())),
          ),
          const DrListCard(
            children: [
              DrTransactionTile(
                leading: DrEmojiBadge(emoji: '☕', color: DrColors.orange),
                title: 'Latte',
                subtitle: 'Bu gün, 10:15',
                trailing: _Amount('- 2.50 ₼'),
              ),
              DrTransactionTile(
                leading: DrEmojiBadge(emoji: '🥗', color: DrColors.teal),
                title: 'Toyuqlu salat',
                subtitle: 'Dünən, 12:30',
                trailing: _Amount('- 5.00 ₼'),
              ),
              DrTransactionTile(
                leading: DrEmojiBadge(emoji: '🥪', color: DrColors.red),
                title: 'Klub sendviç',
                subtitle: 'Dünən, 09:40',
                trailing: _Amount('- 4.50 ₼'),
                divider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  final String text;
  const _Amount(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700));
}

class _LimitCard extends StatelessWidget {
  const _LimitCard();
  @override
  Widget build(BuildContext context) {
    return DrGlowCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _amountColumn(context, 'Cart number', '10000033455',
                  DrColors.accentGreen),
              _amountColumn(context, 'Balance', '7.50 ₼', context.dr.textMain,
                  alignEnd: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountColumn(
      BuildContext context, String label, String value, Color valueColor,
      {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.dr.textMuted)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}

class _BarcodeCard extends StatelessWidget {
  const _BarcodeCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('STUDENT ID',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 16)),
              Container(
                width: 35,
                height: 25,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const Spacer(),
          const _Barcode(),
          const SizedBox(height: 10),
          const Text('BSB-5621-SALEKH',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: DrColors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('Ready to Scan',
                  style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
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
    const widths = <double>[3, 1, 2, 1, 1, 3, 2, 1, 1, 2, 3, 1, 2, 2, 1, 1, 3,
      1, 2, 1, 2, 3, 1, 1, 2, 1, 3, 2, 1, 1, 2, 1, 3, 1, 2, 2, 1, 3, 1, 2, 1, 1];
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
