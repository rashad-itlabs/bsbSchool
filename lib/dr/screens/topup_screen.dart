import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../../core/l10n/l10n.dart';

/// Port of `topup.html` — amount entry + payment card form.
class TopUpScreen extends StatefulWidget {
  /// Amount to open with — the sum the parent picked on the tuition sheet.
  /// Null keeps the default quick amount.
  final double? initialAmount;

  const TopUpScreen({super.key, this.initialAmount});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  late final TextEditingController _amount;

  /// Index of the highlighted quick button, or -1 when the amount came from
  /// somewhere else and matches none of them.
  late int _quick;

  static const _quickValues = [10, 50, 100, 200];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount;
    _amount = TextEditingController(
      text: initial == null ? '50' : _plain(initial),
    );
    _quick = initial == null
        ? 1
        : _quickValues.indexWhere((v) => v == initial);
  }

  /// Drops the decimals when there are none to show: `15678.00` reads better
  /// as `15678` in a 56pt field.
  static String _plain(double value) {
    final text = value.toStringAsFixed(2);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }

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
          DrBackHeader(title: context.l10n.balanceTopUp),
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
                    Text(context.l10n.topUpCardSection,
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
                DrTextField(
                    label: context.l10n.cardNumberField,
                    hint: '0000 0000 0000 0000',
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: DrTextField(label: context.l10n.cardExpiry, hint: 'AA/İİ')),
                    SizedBox(width: 16),
                    Expanded(
                        child: DrTextField(
                            label: 'CVV', hint: '•••', obscure: true)),
                  ],
                ),
                const SizedBox(height: 20),
                DrTextField(
                    label: context.l10n.cardHolder, hint: context.l10n.cardHolderHint),
              ],
            ),
          ),
          const SizedBox(height: 30),
          DrPrimaryButton(
            label: context.l10n.payNow,
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
