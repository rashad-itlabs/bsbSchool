import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../../core/l10n/l10n.dart';

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
  /// A method rather than a const list: the labels are translated, so they
  /// have to be resolved against the context on every build.
  List<String> _filterLabels(BuildContext context) => [
    context.l10n.commonAll,
    context.l10n.historyIncome,
    context.l10n.historyCanteen,
    context.l10n.historyTuition,
    context.l10n.historyOther,
  ];

  // Placeholder rows until the endpoint lands — merchant names and times are
  // sample data, not interface text, so they are not translated.
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
          DrBackHeader(title: context.l10n.historyTitle),
          DrChipBar(
            labels: _filterLabels(context),
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
                            ? context.dr.accent
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
