import 'package:flutter/material.dart';

import '../../../../dr/theme/dr_colors.dart';
import '../../../../dr/widgets/dr_widgets.dart';
import '../../domain/entities/school_event.dart';
import '../../../../core/l10n/app_dates.dart';
import '../../../../core/l10n/l10n.dart';

/// The dashboard's school calendar: a month grid whose days carry a coloured
/// dot per event, plus the month's entries listed underneath — one day's, once
/// that day is tapped in the grid.
///
/// The whole year arrives in one `GET /getEvent` call, so paging between months
/// is pure local state — no refetch.
class EventsCalendarCard extends StatefulWidget {
  final List<SchoolEvent> events;

  /// Shows a spinner in place of the grid on the very first load.
  final bool loading;

  /// Non-null only when the load failed; rendered with a retry affordance.
  final String? errorMessage;
  final VoidCallback? onRetry;

  const EventsCalendarCard({
    super.key,
    required this.events,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<EventsCalendarCard> createState() => _EventsCalendarCardState();
}

class _EventsCalendarCardState extends State<EventsCalendarCard> {
  /// How many entries the inline list shows before collapsing into a "+N".
  static const _maxListedEvents = 6;

  /// First day of the month on screen.
  late DateTime _visibleMonth;

  /// A day tapped in the grid: the list under it narrows to that day. Null —
  /// the list covers the whole month on screen.
  DateTime? _selectedDay;

  /// The "+N" under the list was tapped: every entry is shown.
  /// Reset whenever the list switches between month and day.
  bool _showAll = false;

  /// Events bucketed by day, rebuilt only when the feed itself changes — the
  /// alternative is re-scanning ~200 entries for all 42 cells on every rebuild.
  Map<DateTime, List<SchoolEvent>> _byDay = const {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _byDay = _groupByDay(widget.events);
  }

  @override
  void didUpdateWidget(covariant EventsCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.events, widget.events)) {
      _byDay = _groupByDay(widget.events);
    }
  }

  /// Expands multi-day entries across every day they cover so the grid can look
  /// a day up directly.
  Map<DateTime, List<SchoolEvent>> _groupByDay(List<SchoolEvent> events) {
    final map = <DateTime, List<SchoolEvent>>{};

    for (final event in events) {
      final start = event.date;
      final last = event.lastDay;
      if (start == null || last == null) continue;

      // Guards against a mis-entered end date turning into a huge loop.
      final span = last.difference(start).inDays.clamp(0, 365);
      for (var i = 0; i <= span; i++) {
        final day = DateTime(start.year, start.month, start.day + i);
        map.putIfAbsent(day, () => []).add(event);
      }
    }

    return map;
  }

  List<SchoolEvent> _eventsOn(DateTime day) =>
      _byDay[DateTime(day.year, day.month, day.day)] ?? const [];

  /// Every entry touching the month on screen, once each — a multi-day one
  /// that began the month before included — in calendar order.
  List<SchoolEvent> _eventsOfVisibleMonth() {
    final first = _visibleMonth;
    final last = DateTime(first.year, first.month + 1, 0);

    return widget.events.where((event) {
      final start = event.date;
      final end = event.lastDay;
      return start != null &&
          end != null &&
          !start.isAfter(last) &&
          !end.isBefore(first);
    }).toList()
      ..sort((a, b) {
        final byDate = a.date!.compareTo(b.date!);
        return byDate != 0 ? byDate : (a.time ?? '').compareTo(b.time ?? '');
      });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      // The list under the grid belongs to the month on screen.
      _selectedDay = null;
      _showAll = false;
    });
  }

  /// Narrows the list to [day]; [day] again (or null) widens it back to the
  /// month.
  void _selectDay(DateTime? day) {
    setState(() {
      _selectedDay = day == _selectedDay ? null : day;
      _showAll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DrGlowCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _monthHeader(),
          const SizedBox(height: 18),
          if (widget.loading)
            _placeholder(
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(context.dr.accent),
                ),
              ),
            )
          else if (widget.errorMessage != null)
            _placeholder(_error(widget.errorMessage!))
          else ...[
            _weekdayRow(),
            const SizedBox(height: 8),
            // Horizontal drags don't fight the dashboard's vertical scroll, so
            // the month can be swiped as well as stepped with the arrows.
            GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -100) _shiftMonth(1);
                if (v > 100) _shiftMonth(-1);
              },
              behavior: HitTestBehavior.opaque,
              child: _monthGrid(),
            ),
            const SizedBox(height: 16),
            _listPanel(),
          ],
        ],
      ),
    );
  }

  Widget _monthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  AppDates.monthTitle(context, _visibleMonth.month),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.dr.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${_visibleMonth.year}',
                style: TextStyle(fontSize: 13, color: context.dr.textMuted),
              ),
            ],
          ),
        ),
        _arrow(Icons.chevron_left_rounded, () => _shiftMonth(-1)),
        const SizedBox(width: 8),
        _arrow(Icons.chevron_right_rounded, () => _shiftMonth(1)),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.dr.bgDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.dr.border),
        ),
        child: Icon(icon, size: 20, color: context.dr.textMain),
      ),
    );
  }

  Widget _weekdayRow() {
    return Row(
      children: List.generate(7, (i) => AppDates.weekdayShort(context, i + 1))
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.dr.textMuted,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _monthGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month);
    // `weekday` is 1 = Monday, matching the grid's leading column.
    final leadingBlanks = first.weekday - 1;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) const Expanded(child: SizedBox()),
      for (var day = 1; day <= daysInMonth; day++)
        Expanded(
          child: _dayCell(DateTime(_visibleMonth.year, _visibleMonth.month, day)),
        ),
    ];
    // Pads the tail so the last row's cells keep the same width as the rest.
    while (cells.length % 7 != 0) {
      cells.add(const Expanded(child: SizedBox()));
    }

    return Column(
      children: [
        for (var row = 0; row < cells.length ~/ 7; row++)
          Row(children: cells.sublist(row * 7, row * 7 + 7)),
      ],
    );
  }

  Widget _dayCell(DateTime day) {
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final isSelected = day == _selectedDay;
    final events = _eventsOn(day);
    final isWeekend = day.weekday >= DateTime.saturday;

    // A red entry tints the whole date, not just its dot.
    final red = events
        .map((event) => eventColor(context, event.colorHex))
        .where(isRedEventColor)
        .firstOrNull;

    final Color textColor;
    if (isSelected) {
      textColor = Colors.black;
    } else if (isToday) {
      textColor = context.dr.accent;
    } else if (red != null) {
      textColor = context.dr.textMain;
    } else if (isWeekend) {
      textColor = context.dr.textMuted.withValues(alpha: 0.55);
    } else {
      textColor = context.dr.textMain;
    }

    return GestureDetector(
      onTap: () => _selectDay(day),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? DrColors.accentGreen
                    : red?.withValues(alpha: 0.25) ?? Colors.transparent,
                shape: BoxShape.circle,
                border: !isSelected && isToday
                    ? Border.all(
                        color: context.dr.accent.withValues(alpha: 0.5),
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: DrColors.accentGreen.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _dots(events, muted: isSelected),
          ],
        ),
      ),
    );
  }

  /// One dot per distinct category colour on that day, capped at three so a
  /// busy day doesn't widen the cell.
  Widget _dots(List<SchoolEvent> events, {required bool muted}) {
    if (events.isEmpty) return const SizedBox(height: 5);

    final colors = <Color>[];
    for (final event in events) {
      final color = eventColor(context, event.colorHex);
      if (!colors.contains(color)) colors.add(color);
      if (colors.length == 3) break;
    }

    return SizedBox(
      height: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: colors
            .map(
              (color) => Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  // On the neon-green selected pill the true category colours
                  // read as mud, so they flip to black there.
                  color: muted ? Colors.black.withValues(alpha: 0.55) : color,
                  shape: BoxShape.circle,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// The month's entries; with a day tapped in the grid, that day's, under a
  /// header that closes back to the month.
  Widget _listPanel() {
    final day = _selectedDay;
    final events = day == null ? _eventsOfVisibleMonth() : _eventsOn(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: context.dr.border),
        const SizedBox(height: 14),
        if (day != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  AppDates.dayMonth(context, day),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.dr.textMain,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _selectDay(null),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.dr.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (events.isEmpty)
          Text(
            day == null
                ? context.l10n.eventsNoneThisMonth
                : context.l10n.eventsNoneToday,
            style: TextStyle(fontSize: 12, color: context.dr.textMuted),
          )
        else ...[
          for (final event
              in events.take(_showAll ? events.length : _maxListedEvents))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _showEventSheet(event),
                // The month list says each entry's days; under a day's header
                // they would only repeat it.
                child: _eventRow(event, showDays: day == null),
              ),
            ),
          if (!_showAll && events.length > _maxListedEvents)
            GestureDetector(
              onTap: () => setState(() => _showAll = true),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  context.l10n.eventsMore(events.length - _maxListedEvents),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.dr.accent,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// The language the entries are shown in — the app's, not the one the feed
  /// was requested in: the bloc doesn't reload on a language switch, so the
  /// text is picked from `translations` at build time.
  String get _lang => Localizations.localeOf(context).languageCode;

  /// The entry in full: title, its days (and time), and the description with
  /// its line breaks. Scrolls when the text is taller than the sheet.
  void _showEventSheet(SchoolEvent event) {
    final color = eventColor(context, event.colorHex);
    final description = event.descriptionIn(_lang).trim();
    final start = event.date;
    final last = event.lastDay;
    final when = [
      if (start != null && last != null) AppDates.dayRange(context, start, last),
      if (event.time != null) event.time!,
    ].join(' · ');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.dr.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.dr.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  event.titleIn(_lang),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: context.dr.textMain,
                  ),
                ),
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    when,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(height: 1, color: context.dr.border),
                  const SizedBox(height: 14),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: context.dr.textMain,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Title and description wrap in full — they used to be cut to one line
  /// each, with the description's line breaks folded into " • ". The colour bar
  /// is the row's left border, so it grows with the text. [showDays] puts the
  /// entry's days above the title.
  Widget _eventRow(SchoolEvent event, {required bool showDays}) {
    final color = eventColor(context, event.colorHex);
    final description = event.descriptionIn(_lang).trim();
    final start = event.date;
    final last = event.lastDay;

    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDays && start != null && last != null) ...[
                  Text(
                    AppDates.dayRange(context, start, last),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  event.titleIn(_lang),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: context.dr.textMain,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: context.dr.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (event.time != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.time!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Keeps the grid from jumping between the loading, error and loaded states.
  Widget _placeholder(Widget child) {
    return SizedBox(
      height: 200,
      child: Center(child: child),
    );
  }

  Widget _error(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded, size: 24, color: context.dr.textMuted),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: context.dr.textMuted),
        ),
        if (widget.onRetry != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.onRetry,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                context.l10n.commonRetry,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.dr.accent,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Turns the panel's `#rrggbb` (or `#aarrggbb`) category colour into a [Color],
/// falling back to the theme's accent when the value is missing or malformed.
///
/// Pure black — which the panel uses for mourning days — is remapped to the
/// theme's main text colour: as sent it is invisible on the dark palette, and
/// flipping it to a fixed grey would only move the problem to the light one.
Color eventColor(BuildContext context, String? hex) {
  final raw = hex?.trim().replaceFirst('#', '');
  if (raw == null || (raw.length != 6 && raw.length != 8)) {
    return context.dr.accent;
  }

  final value = int.tryParse(raw, radix: 16);
  if (value == null) return context.dr.accent;

  final color = Color(raw.length == 6 ? 0xFF000000 | value : value);
  return color == const Color(0xFF000000) ? context.dr.textMain : color;
}

/// Whether a category colour reads as red — the panel's `#dc3545`, or any
/// other strong red it may offer later. Its pink (`#d63384`) and orange
/// (`#fd7e14`) swatches stay out.
bool isRedEventColor(Color color) {
  final hsv = HSVColor.fromColor(color);
  return hsv.saturation >= 0.5 &&
      hsv.value >= 0.4 &&
      (hsv.hue >= 345 || hsv.hue <= 10);
}
