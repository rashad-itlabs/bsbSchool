import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

/// Port of `history.html` — filter chips + grouped transactions.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _Tx {
  final String emoji;
  final Color color;
  final String title;
  final String sub;
  final String amount;
  final bool positive;
  const _Tx(this.emoji, this.color, this.title, this.sub, this.amount,
      {this.positive = false});
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _filter = 0;
  static const _filters = ['Hamısı', 'Mədaxil', 'Yeməkxana', 'Təhsil', 'Digər'];

  static const _groups = <String, List<_Tx>>{
    'Bu gün': [
      _Tx('☕', DrColors.orange, 'Yeməkxana', '12:30 • Kartla ödəniş',
          '- 12.50 ₼'),
    ],
    'Dünən': [
      _Tx('📚', DrColors.purple, 'İllik təhsil haqqı',
          '09:15 • Hissə-hissə ödəniş', '- 1250.00 ₼'),
    ],
    '1 May 2026': [
      _Tx('↓', DrColors.accentGreen, 'Balans artırımı', '14:00 • Visa ****4242',
          '+ 3000.00 ₼', positive: true),
      _Tx('👕', DrColors.teal, 'Məktəbli forması', '11:20 • Mağaza', '- 85.00 ₼'),
    ],
    '28 Aprel 2026': [
      _Tx('🚌', DrColors.red, 'Məktəbli avtobusu', '08:00 • Aylıq abunə',
          '- 120.00 ₼'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: ListView(
        children: [
          const DrBackHeader(title: 'Tarixçə'),
          DrChipBar(
            labels: _filters,
            selectedIndex: _filter,
            onSelected: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 10),
          for (final entry in _groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
              child: Text(entry.key,
                  style: TextStyle(
                      fontSize: 13,
                      color: context.dr.textMuted,
                      fontWeight: FontWeight.w500)),
            ),
            DrListCard(
              children: [
                for (var i = 0; i < entry.value.length; i++)
                  DrTransactionTile(
                    leading: DrEmojiBadge(
                        emoji: entry.value[i].emoji,
                        color: entry.value[i].color),
                    title: entry.value[i].title,
                    subtitle: entry.value[i].sub,
                    divider: i != entry.value.length - 1,
                    trailing: Text(
                      entry.value[i].amount,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: entry.value[i].positive
                            ? DrColors.accentGreen
                            : context.dr.textMain,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
