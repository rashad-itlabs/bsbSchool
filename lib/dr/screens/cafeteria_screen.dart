import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Port of `cafeteria.html` — daily limit, weekly bar chart, recent purchases.
class CafeteriaScreen extends StatelessWidget {
  const CafeteriaScreen({super.key});

  static const _bars = <List<dynamic>>[
    ['B.e', 0.40, false],
    ['Ç.a', 0.70, false],
    ['Ç', 0.25, true],
    ['C.a', 0.0, false],
    ['C', 0.0, false],
  ];

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: ListView(
        children: [
          const DrBackHeader(title: 'Qidalanma'),
          _limitCard(context),
          const SizedBox(height: 30),
          DrSectionHeader(title: 'Həftəlik statistika'),
          DrCard(
            child: SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _bars.map((b) {
                  final active = b[2] as bool;
                  final h = b[1] as double;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomCenter,
                            heightFactor: h == 0 ? 0.01 : h,
                            child: Container(
                              width: 30,
                              decoration: BoxDecoration(
                                color: active
                                    ? DrColors.accentGreen
                                    : context.dr.bgSurfaceLight,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                            color: DrColors.accentGreen
                                                .withValues(alpha: 0.4),
                                            blurRadius: 12)
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(b[0] as String,
                            style: TextStyle(
                                fontSize: 12,
                                color: active
                                    ? context.dr.textMain
                                    : context.dr.textMuted,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 30),
          DrSectionHeader(title: 'Son əməliyyatlar', action: 'Hamısı'),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _limitCard(BuildContext context) {
    return DrGlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Günlük limit',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_outlined,
                    size: 16, color: context.dr.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xərclənib',
                      style:
                          TextStyle(fontSize: 12, color: context.dr.textMuted)),
                  const SizedBox(height: 4),
                  const Text('2.50 ₼',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: DrColors.accentGreen)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Qalıq',
                      style:
                          TextStyle(fontSize: 12, color: context.dr.textMuted)),
                  const SizedBox(height: 4),
                  const Text('7.50 ₼',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: Colors.black.withValues(alpha: 0.3)),
                FractionallySizedBox(
                  widthFactor: 0.25,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: DrColors.accentGreen,
                      boxShadow: [
                        BoxShadow(
                            color: DrColors.accentGreen.withValues(alpha: 0.4),
                            blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Ümumi limit: 10.00 ₼',
                style: TextStyle(fontSize: 12, color: context.dr.textMuted)),
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
