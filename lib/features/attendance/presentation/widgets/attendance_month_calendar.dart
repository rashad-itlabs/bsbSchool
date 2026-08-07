import 'package:flutter/material.dart';

import '../../../../dr/theme/dr_colors.dart';
import '../../../../dr/widgets/dr_widgets.dart';
import '../../domain/entities/attendance_record.dart';

/// The month overview as a real calendar grid: one cell per day of the shown
/// month, tinted by the attendance logged that day, with arrows to walk back
/// through the months the API returned records for.
class AttendanceMonthCalendar extends StatefulWidget {
  final List<AttendanceRecord> records;
  const AttendanceMonthCalendar({super.key, required this.records});

  @override
  State<AttendanceMonthCalendar> createState() =>
      _AttendanceMonthCalendarState();
}

class _AttendanceMonthCalendarState extends State<AttendanceMonthCalendar> {
  static const _labels = ['Be', 'Ça', 'Ç', 'Ca', 'C', 'Ş', 'B'];
  static const _azMonths = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'İyun',
    'İyul', 'Avqust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
  ];

  /// Null until the user taps an arrow, i.e. "the month today falls in".
  DateTime? _month;

  /// The calendar always opens on the current month so today is on screen;
  /// other months are one arrow tap away.
  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  DateTime get _visibleMonth => _month ?? _currentMonth;

  /// Navigation is bounded by the data: the oldest logged month up to the
  /// newest of (today, last logged session). The current month is always inside
  /// the range, so the default month is never out of bounds.
  DateTime get _firstMonth {
    final dates = widget.records.map((r) => r.date).whereType<DateTime>();
    if (dates.isEmpty) return _currentMonth;
    final oldest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final oldestMonth = DateTime(oldest.year, oldest.month);
    return oldestMonth.isBefore(_currentMonth) ? oldestMonth : _currentMonth;
  }

  DateTime get _lastMonth {
    final dates = widget.records.map((r) => r.date).whereType<DateTime>();
    if (dates.isEmpty) return _currentMonth;
    final newest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final newestMonth = DateTime(newest.year, newest.month);
    return newestMonth.isAfter(_currentMonth) ? newestMonth : _currentMonth;
  }

  void _shift(int months) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + months);
    if (target.isBefore(_firstMonth) || target.isAfter(_lastMonth)) return;
    setState(() => _month = target);
  }

  @override
  Widget build(BuildContext context) {
    final month = _visibleMonth;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first grid: how many blanks before the 1st.
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final rows = ((leading + daysInMonth) / 7).ceil();

    final canGoBack = !_visibleMonth.isAtSameMomentAs(_firstMonth) &&
        _visibleMonth.isAfter(_firstMonth);
    final canGoForward = _visibleMonth.isBefore(_lastMonth);

    return DrGlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _arrow(Icons.chevron_left_rounded,
                  canGoBack ? () => _shift(-1) : null),
              Expanded(
                child: Text(
                  '${_azMonths[month.month - 1]} ${month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              _arrow(Icons.chevron_right_rounded,
                  canGoForward ? () => _shift(1) : null),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final label in _labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 10, color: context.dr.textMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Builder(builder: (context) {
                        final dayNumber = row * 7 + col - leading + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        return _dayCell(
                            context,
                            DateTime(month.year, month.month, dayNumber));
                      }),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          _legend(context, month),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap) {
    return Opacity(
      opacity: onTap == null ? 0.3 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 22, color: context.dr.textMuted),
        ),
      ),
    );
  }

  Widget _dayCell(BuildContext context, DateTime day) {
    final status = _statusOn(day);
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final color = status == null ? null : _statusColor(context, status);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: context.dr.accent, width: 1.5)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 12,
            // Today keeps full weight/contrast even with no session logged, so
            // the ringed cell doesn't read as a faded one.
            fontWeight: status == null && !isToday
                ? FontWeight.w400
                : FontWeight.w600,
            color: color ??
                (isToday ? context.dr.textMain : context.dr.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, DateTime month) {
    // Counted per day, not per record, so the numbers match the coloured cells.
    var present = 0, late = 0, absent = 0;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      switch (_statusOn(DateTime(month.year, month.month, d))) {
        case _DayStatus.present:
          present++;
        case _DayStatus.late:
          late++;
        case _DayStatus.absent:
          absent++;
        case null:
          break;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _legendItem(context, _DayStatus.present, 'Gəlib', present),
        _legendItem(context, _DayStatus.late, 'Gecikib', late),
        _legendItem(context, _DayStatus.absent, 'Qayıb', absent),
      ],
    );
  }

  Widget _legendItem(
      BuildContext context, _DayStatus status, String label, int count) {
    final color = _statusColor(context, status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label $count',
            style: TextStyle(fontSize: 11, color: context.dr.textMuted)),
      ],
    );
  }

  /// The worst status logged on [day] wins (absent > late > present) so a single
  /// missed lesson shows up even when the other sessions were attended.
  _DayStatus? _statusOn(DateTime day) {
    final onDay = widget.records.where((r) {
      final d = r.date;
      return d != null &&
          d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    });
    if (onDay.isEmpty) return null;
    if (onDay.any((r) => r.isAbsent)) return _DayStatus.absent;
    if (onDay.any((r) => r.isLate)) return _DayStatus.late;
    return _DayStatus.present;
  }

  Color _statusColor(BuildContext context, _DayStatus status) {
    return switch (status) {
      _DayStatus.present => context.dr.accent,
      _DayStatus.late => DrColors.teal,
      _DayStatus.absent => DrColors.red,
    };
  }
}

enum _DayStatus { present, late, absent }
