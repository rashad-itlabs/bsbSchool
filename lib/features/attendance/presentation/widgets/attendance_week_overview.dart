import 'package:flutter/material.dart';

import '../../../../dr/theme/dr_colors.dart';
import '../../../../dr/widgets/dr_widgets.dart';
import '../../domain/entities/attendance_record.dart';

/// The "current month overview" card: one dot per weekday of the current week,
/// coloured by the attendance logged that day. Shared by the dashboard and the
/// attendance screen so both stay in sync.
class AttendanceWeekOverview extends StatelessWidget {
  final List<AttendanceRecord> records;
  const AttendanceWeekOverview({super.key, required this.records});

  static const _labels = ['Be', 'Ça', 'Ç', 'Ca', 'C', 'Ş', 'B'];
  static const _azMonths = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'İyun',
    'İyul', 'Avqust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
  ];

  @override
  Widget build(BuildContext context) {
    // Mon..Sun of the current week: green present, teal late, red absent,
    // faded when there is no logged session for that day.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return DrGlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_azMonths[now.month - 1]} ayı üzrə icmal',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_labels.length, (i) {
              final day = monday.add(Duration(days: i));
              return Column(
                children: [
                  Text(_labels[i],
                      style: TextStyle(
                          fontSize: 10, color: context.dr.textMuted)),
                  const SizedBox(height: 8),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: _dotColor(day), shape: BoxShape.circle),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  /// The worst status logged on [day] wins (absent > late > present) so a single
  /// missed lesson shows up even when the other sessions were attended.
  Color _dotColor(DateTime day) {
    final onDay = records.where((r) {
      final d = r.date;
      return d != null &&
          d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    });
    if (onDay.isEmpty) return Colors.white.withValues(alpha: 0.05);
    if (onDay.any((r) => r.isAbsent)) return DrColors.red;
    if (onDay.any((r) => r.isLate)) return DrColors.teal;
    return DrColors.accentGreen;
  }
}
