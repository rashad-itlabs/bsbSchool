import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Port of `topup.html` — amount entry + payment card form.
class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _amount = TextEditingController(text: '50');
  int _quick = 1;
  static const _quickValues = [10, 50, 100, 200];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: ListView(
        children: [
          const DrBackHeader(title: 'Balansı artır'),
          const SizedBox(height: 20),
          // Amount input
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IntrinsicWidth(
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: context.dr.textMain),
                    decoration: const InputDecoration(
                        border: InputBorder.none, isCollapsed: true),
                  ),
                ),
                const SizedBox(width: 8),
                Text('₼',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: context.dr.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < _quickValues.length; i++) ...[
                if (i != 0) const SizedBox(width: 10),
                Expanded(child: _quickBtn(i)),
              ],
            ],
          ),
          const SizedBox(height: 40),
          DrCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ödəniş kartı',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text('VISA',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.9))),
                        const SizedBox(width: 10),
                        _mastercard(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const DrTextField(
                    label: 'Kartın nömrəsi',
                    hint: '0000 0000 0000 0000',
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(
                        child: DrTextField(label: 'Müddət', hint: 'AA/İİ')),
                    SizedBox(width: 16),
                    Expanded(
                        child: DrTextField(
                            label: 'CVV', hint: '•••', obscure: true)),
                  ],
                ),
                const SizedBox(height: 20),
                const DrTextField(
                    label: 'Kart Sahibinin Adı', hint: 'AD VƏ SOYAD'),
              ],
            ),
          ),
          const SizedBox(height: 30),
          DrPrimaryButton(
            label: 'Ödəniş et',
            trailingIcon: Icons.arrow_forward,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _quickBtn(int i) {
    final active = i == _quick;
    return GestureDetector(
      onTap: () {
        setState(() {
          _quick = i;
          _amount.text = _quickValues[i].toString();
        });
      },
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? DrColors.accentGreen : context.dr.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: active ? DrColors.accentGreen : context.dr.border),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: DrColors.accentGreen.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Text('+ ${_quickValues[i]}',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: active ? Colors.black : context.dr.textMain)),
      ),
    );
  }

  Widget _mastercard() {
    return SizedBox(
      width: 28,
      height: 18,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                  color: Color(0xFFEA001B), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                  color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                  shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
