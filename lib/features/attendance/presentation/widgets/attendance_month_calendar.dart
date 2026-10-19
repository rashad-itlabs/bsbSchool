import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../dr/theme/dr_colors.dart';
import '../../../../dr/widgets/dr_widgets.dart';
import '../../domain/entities/attendance_permission.dart';
import '../../domain/entities/attendance_record.dart';
import '../../../../core/l10n/app_dates.dart';
import '../../../../core/l10n/l10n.dart';

/// The month overview as a real calendar grid: one cell per day of the shown
/// month, tinted by the attendance logged that day, with arrows to walk back
/// through the months the API returned records for.
///
/// Today and past days are tappable and report through [onDaySelected]; the
/// [selectedDay] cell is filled so the list below it reads as "this day".
/// Whenever the user walks to another month, [onMonthChanged] reports the
/// first day of the newly shown month.
class AttendanceMonthCalendar extends StatefulWidget {
  final List<AttendanceRecord> records;

  /// The child's permissions (server 19.10.2026): a covered day with nothing
  /// logged yet — a lesson not started, a future day — reads as excused, and
  /// a future one is tappable so its "excused" line can be read.
  final List<AttendancePermission> permissions;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<DateTime>? onMonthChanged; // YENİ
  const AttendanceMonthCalendar({
    super.key,
    required this.records,
    this.permissions = const [],
    this.selectedDay,
    this.onDaySelected,
    this.onMonthChanged, // YENİ
  });

  @override
  State<AttendanceMonthCalendar> createState() =>
      _AttendanceMonthCalendarState();
}

class _AttendanceMonthCalendarState extends State<AttendanceMonthCalendar> {
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
  /// Logged days and permission days — next month's permission is reachable.
  Iterable<DateTime> get _dates => [
        ...widget.records.map((r) => r.date).whereType<DateTime>(),
        for (final p in widget.permissions) ...p.dates,
      ];

  DateTime get _firstMonth {
    final dates = _dates;
    if (dates.isEmpty) return _currentMonth;
    final oldest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final oldestMonth = DateTime(oldest.year, oldest.month);
    return oldestMonth.isBefore(_currentMonth) ? oldestMonth : _currentMonth;
  }

  DateTime get _lastMonth {
    final dates = _dates;
    if (dates.isEmpty) return _currentMonth;
    final newest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final newestMonth = DateTime(newest.year, newest.month);
    return newestMonth.isAfter(_currentMonth) ? newestMonth : _currentMonth;
  }

  void _shift(int months) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + months);
    if (target.isBefore(_firstMonth) || target.isAfter(_lastMonth)) return;
    setState(() => _month = target);
    widget.onMonthChanged?.call(target); // YENİ: valideynə xəbər ver
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
                  AppDates.monthYear(context, month),
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
              for (var weekday = 1; weekday <= 7; weekday++)
                Expanded(
                  child: Text(
                    AppDates.weekdayShort(context, weekday),
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
    final selected = widget.selectedDay;
    final isSelected = selected != null &&
        day.year == selected.year &&
        day.month == selected.month &&
        day.day == selected.day;
    // Future days have nothing logged yet, so only today and earlier respond —
    // except a permission day, whose "excused" line is worth reading ahead.
    final canTap = widget.onDaySelected != null &&
        (!day.isAfter(DateTime(now.year, now.month, now.day)) ||
            _permitted(day));
    final isMixed = status == _DayStatus.mixed;
    // A mixed day has no single colour: it is painted half and half instead,
    // and its number stays neutral so it reads on both halves.
    final color = status == null || isMixed
        ? null
        : _statusColor(context, status);
    final alpha = isSelected ? 0.4 : 0.15;
    final fill = isMixed
        ? null
        : isSelected
        ? (color ?? context.dr.accent).withValues(alpha: alpha)
        : color?.withValues(alpha: alpha);

    final cell = Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          gradient: isMixed ? _mixedGradient(context, alpha) : null,
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
            fontWeight: status == null && !isToday && !isSelected
                ? FontWeight.w400
                : FontWeight.w600,
            color: color ??
                (isToday || isSelected || isMixed
                    ? context.dr.textMain
                    : context.dr.textMuted),
          ),
        ),
      ),
    );

    if (!canTap) return cell;
    return GestureDetector(
      onTap: () => widget.onDaySelected!(day),
      behavior: HitTestBehavior.opaque,
      child: cell,
    );
  }

  Widget _legend(BuildContext context, DateTime month) {
    // Counted per day, not per record, so the numbers match the coloured cells.
    var present = 0, late = 0, absent = 0, mixed = 0, excused = 0;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (var d = 1; d <= daysInMonth; d++) {
      switch (_statusOn(DateTime(month.year, month.month, d))) {
        case _DayStatus.present:
          present++;
        case _DayStatus.late:
          late++;
        case _DayStatus.absent:
          absent++;
        case _DayStatus.mixed:
          mixed++;
        case _DayStatus.excused:
          excused++;
        case null:
          break;
      }
    }

    // Two to a row (owner, 19.10.2026): on one line the labels were squeezed
    // into ellipses on a narrow phone. A long label still shrinks with an
    // ellipsis inside its half rather than overflowing. The excused item only
    // shows in a month that has such a day.
    final items = [
      _legendItem(context, _DayStatus.present, context.l10n.attendancePresent, present),
      _legendItem(context, _DayStatus.late, context.l10n.attendanceLateTag, late),
      _legendItem(context, _DayStatus.absent, context.l10n.attendanceAbsent, absent),
      _legendItem(context, _DayStatus.mixed, context.l10n.attendanceMixed, mixed),
      if (excused > 0)
        _legendItem(context, _DayStatus.excused, context.l10n.attendanceExcusedTag, excused),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: items[i]),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < items.length
                    ? items[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _legendItem(
      BuildContext context, _DayStatus status, String label, int count) {
    final isMixed = status == _DayStatus.mixed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isMixed ? null : _statusColor(context, status),
            gradient: isMixed ? _mixedGradient(context, 1) : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text('$label $count',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: context.dr.textMuted)),
        ),
      ],
    );
  }

  /// A day with both a missed and an attended session is [_DayStatus.mixed];
  /// otherwise the worst status logged on [day] wins (absent > late > present).
  /// Excused lessons (QƏRAR-107) don't colour a day — the website's rule — and
  /// a day excused from start to end is [_DayStatus.excused]. So is a
  /// permission day with nothing logged yet (19.10.2026: its lessons have not
  /// started, the server sends no record for them). Once a lesson is logged,
  /// the records decide — a child who came anyway reads as present.
  _DayStatus? _statusOn(DateTime day) {
    final logged = widget.records.where((r) {
      final d = r.date;
      return d != null &&
          d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    });
    if (logged.isEmpty) return _permitted(day) ? _DayStatus.excused : null;
    final onDay = logged.where((r) => !r.isExcused);
    if (onDay.isEmpty) return _DayStatus.excused;
    final anyAbsent = onDay.any((r) => r.isAbsent);
    if (anyAbsent && onDay.any((r) => !r.isAbsent)) return _DayStatus.mixed;
    if (anyAbsent) return _DayStatus.absent;
    if (onDay.any((r) => r.isLate)) return _DayStatus.late;
    return _DayStatus.present;
  }

  bool _permitted(DateTime day) => widget.permissions.any((p) => p.covers(day));

  Color _statusColor(BuildContext context, _DayStatus status) {
    return switch (status) {
      _DayStatus.present => context.dr.accent,
      _DayStatus.late => DrColors.teal,
      _DayStatus.absent => DrColors.red,
      _DayStatus.excused => DrColors.blue,
    // Only used where a single colour is unavoidable; cells and the legend
    // dot paint [_mixedGradient] instead.
      _DayStatus.mixed => DrColors.red,
    };
  }

  /// Present green top-left, absent red bottom-right, with a hard diagonal
  /// edge: the left/right split turned 45° clockwise.
  Gradient _mixedGradient(BuildContext context, double alpha) {
    final green = _statusColor(context, _DayStatus.present).withValues(alpha: alpha);
    final red = _statusColor(context, _DayStatus.absent).withValues(alpha: alpha);
    return LinearGradient(
      colors: [green, green, red, red],
      stops: const [0, 0.5, 0.5, 1],
      transform: const GradientRotation(math.pi / 4),
    );
  }
}

enum _DayStatus { present, late, absent, mixed, excused }