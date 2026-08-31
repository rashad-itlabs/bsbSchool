import 'package:bsbschool/dr/screens/event_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../dr/theme/dr_colors.dart';
import '../../../../dr/widgets/dr_widgets.dart';
import '../../domain/entities/school_event.dart';
import '../../../../core/l10n/app_dates.dart';
import '../../../../core/l10n/l10n.dart';

/// The dashboard's school calendar: a month grid whose days carry a coloured
/// dot per event, plus the selected day's entries listed underneath.
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
  static const _maxListedEvents = 4;

  /// First day of the month on screen.
  late DateTime _visibleMonth;

  /// The day whose events are listed under the grid.
  late DateTime _selectedDay;

  /// Events bucketed by day, rebuilt only when the feed itself changes — the
  /// alternative is re-scanning ~200 entries for all 42 cells on every rebuild.
  Map<DateTime, List<SchoolEvent>> _byDay = const {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
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

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);

      // The panel under the grid must belong to the month on screen, so the
      // selection follows along: today when it falls in the new month, its
      // first day otherwise.
      final now = DateTime.now();
      final isCurrentMonth =
          now.year == _visibleMonth.year && now.month == _visibleMonth.month;
      _selectedDay = isCurrentMonth
          ? DateTime(now.year, now.month, now.day)
          : _visibleMonth;
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
            _selectedDayPanel(),
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
                  AppDates.month(context, _visibleMonth.month),
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

    final Color textColor;
    if (isSelected) {
      textColor = Colors.black;
    } else if (isToday) {
      textColor = context.dr.accent;
    } else if (isWeekend) {
      textColor = context.dr.textMuted.withValues(alpha: 0.55);
    } else {
      textColor = context.dr.textMain;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
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
                color: isSelected ? DrColors.accentGreen : Colors.transparent,
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

  Widget _selectedDayPanel() {
    final events = _eventsOn(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: context.dr.border),
        const SizedBox(height: 14),
        Text(
          AppDates.dayMonth(context, _selectedDay),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.dr.textMain,
          ),
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          Text(
            context.l10n.eventsNoneToday,
            style: TextStyle(fontSize: 12, color: context.dr.textMuted),
          )
        else ...[
          for (final event in events.take(_maxListedEvents))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                  onTap: (){
                    /// eventDetail
                    showModalBottomSheet(
                        context: context,
                        builder: (context){
                          return Container(
                            padding: EdgeInsets.all(15),
                            //color: Colors.grey,
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height:10),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    width: 100,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                SizedBox(height:12),
                                Text(event.title),
                                SizedBox(height:2),
                                Text(DateFormat('dd.MM.yyyy').format(event.date!),style: TextStyle(
                                  fontSize: 12,
                                ),),
                                SizedBox(height:5),
                                Divider(
                                  height: 0.3,
                                ),
                                SizedBox(height:5),
                                Text('Description:',style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),),
                                SizedBox(height:5),
                                Text(event.description),
                                SizedBox(height:32),
                              ],
                            ),
                          );
                        }
                    );
                    // Navigator.of(context).push(CupertinoSheetRoute(
                    //     builder: (context){
                    //       return EventDetailScreen(event:event);
                    //     }
                    // ));
                  },
                  child: _eventRow(event)),
            ),
          if (events.length > _maxListedEvents)
            Text(
              've daha ${events.length - _maxListedEvents} tədbir',
              style: TextStyle(fontSize: 11, color: context.dr.textMuted),
            ),
        ],
      ],
    );
  }

  Widget _eventRow(SchoolEvent event) {
    final color = eventColor(context, event.colorHex);
    final description = event.description.trim().replaceAll('\n', ' • ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          // Matches the two text lines rather than stretching the whole row.
          height: description.isEmpty ? 16 : 32,
          margin: const EdgeInsets.only(top: 2, right: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.dr.textMain,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.dr.textMuted),
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
