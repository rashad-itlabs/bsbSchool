import 'package:flutter/material.dart';

import '../../core/l10n/app_dates.dart';
import '../theme/dr_colors.dart';

/// A bare month calendar in a dialog: arrows to change the month, a
/// Monday-first grid, and a tap on a day picks it and closes. No "Select date"
/// header, no year list and no typed entry — unlike [showDatePicker].
///
/// Returns null when dismissed. Days outside [firstDate]..[lastDate] are shown
/// faded and can't be picked.
Future<DateTime?> showDrDayPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: context.dr.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: _DayPicker(
          initialDate: _dayOf(initialDate),
          firstDate: _dayOf(firstDate),
          lastDate: _dayOf(lastDate),
        ),
      ),
    ),
  );
}

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

class _DayPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _DayPicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_DayPicker> createState() => _DayPickerState();
}

class _DayPickerState extends State<_DayPicker> {
  late DateTime _month =
      DateTime(widget.initialDate.year, widget.initialDate.month);

  DateTime get _firstMonth =>
      DateTime(widget.firstDate.year, widget.firstDate.month);
  DateTime get _lastMonth =>
      DateTime(widget.lastDate.year, widget.lastDate.month);

  void _shift(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Monday-first grid: how many blanks before the 1st.
    final leading = DateTime(_month.year, _month.month, 1).weekday - 1;
    final rows = ((leading + daysInMonth) / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _arrow(Icons.chevron_left_rounded,
                _month.isAfter(_firstMonth) ? () => _shift(-1) : null),
            Expanded(
              child: Text(
                AppDates.monthYear(context, _month),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.dr.textMain,
                ),
              ),
            ),
            _arrow(Icons.chevron_right_rounded,
                _month.isBefore(_lastMonth) ? () => _shift(1) : null),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var weekday = 1; weekday <= 7; weekday++)
              Expanded(
                child: Text(
                  AppDates.weekdayShort(context, weekday),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: context.dr.textMuted),
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
                          DateTime(_month.year, _month.month, dayNumber));
                    }),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap) {
    return Opacity(
      opacity: onTap == null ? 0.3 : 1,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 24, color: context.dr.textMuted),
        ),
      ),
    );
  }

  Widget _dayCell(DateTime day) {
    final enabled =
        !day.isBefore(widget.firstDate) && !day.isAfter(widget.lastDate);
    final isSelected = day == widget.initialDate;
    final now = DateTime.now();
    final isToday = day == DateTime(now.year, now.month, now.day);

    final cell = Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // Filled lime keeps black text legible on both themes.
          color: isSelected ? DrColors.accentGreen : null,
          shape: BoxShape.circle,
          border: isToday && !isSelected
              ? Border.all(color: context.dr.accent, width: 1.5)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? Colors.black
                : enabled
                    ? context.dr.textMain
                    : context.dr.textMuted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );

    if (!enabled) return cell;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(day),
      behavior: HitTestBehavior.opaque,
      child: cell,
    );
  }
}
