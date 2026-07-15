import 'package:flutter/material.dart';

import '../theme/dr_colors.dart';
import '../widgets/dr_ring.dart';
import '../widgets/dr_widgets.dart';
import 'topup_screen.dart';

/// Port of `schedule.html` — payment progress donut + schedule table.
class TuitionScreen extends StatelessWidget {
  const TuitionScreen({super.key});

  static const _rows = <List<String>>[
    ['22/09/2026', '1250.00 ₼', '13750.00 ₼'],
    ['22/10/2026', '1250.00 ₼', '12500.00 ₼'],
    ['22/11/2026', '1250.00 ₼', '11250.00 ₼'],
    ['22/12/2026', '1250.00 ₼', '10000.00 ₼'],
    ['22/01/2027', '1250.00 ₼', '8750.00 ₼'],
    ['22/02/2027', '1250.00 ₼', '7500.00 ₼'],
    ['22/03/2027', '1250.00 ₼', '6250.00 ₼'],
    ['22/04/2027', '1250.00 ₼', '5000.00 ₼'],
    ['22/05/2027', '1250.00 ₼', '3750.00 ₼'],
    ['22/06/2027', '1250.00 ₼', '2500.00 ₼'],
    ['22/07/2027', '1250.00 ₼', '1250.00 ₼'],
    ['22/08/2027', '1250.00 ₼', '0.00 ₼'],
  ];

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: ListView(
        children: [
          const DrBackHeader(title: 'Ödəniş cədvəli', showBack: false),
          const SizedBox(height: 10),
          Center(
            child: DrRing(
              progress: 1 / 12,
              size: 220,
              stroke: 24,
              color: DrColors.accentGreen,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ödəniş',
                      style:
                          TextStyle(fontSize: 14, color: context.dr.textMuted)),
                  const SizedBox(height: 4),
                  const Text('1/12',
                      style: TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          DrCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ödəniş bölməsi',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Pul köçürməsi üçün düyməni sıxın.',
                    style:
                        TextStyle(fontSize: 13, color: context.dr.textMuted)),
                const SizedBox(height: 24),
                DrPrimaryButton(
                  label: 'Ödəniş et',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TopUpScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Ödəniş Cədvəli',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _tableHeader(context),
          const SizedBox(height: 4),
          for (var i = 0; i < _rows.length; i++)
            _tableRow(context, _rows[i],
                paid: i == 0, last: i == _rows.length - 1),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _tableHeader(BuildContext context) {
    TextStyle s = TextStyle(
      fontSize: 11,
      color: context.dr.textMuted,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(child: Text('ÖDƏNİŞ TARİXİ', style: s)),
          Expanded(
              child: Text('ÖDƏNİŞ MƏBLƏĞİ',
                  style: s, textAlign: TextAlign.center)),
          Expanded(
              child:
                  Text('QALIQ BORC', style: s, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _tableRow(BuildContext context, List<String> row,
      {required bool paid, required bool last}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: context.dr.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (paid) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: DrColors.accentGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(row[0],
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: Text(row[1],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(row[2],
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, color: context.dr.textMuted)),
          ),
        ],
      ),
    );
  }
}
