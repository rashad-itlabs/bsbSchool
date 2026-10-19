import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart';
import '../../core/l10n/app_dates.dart';
import '../../features/attendance/domain/entities/attendance_permission.dart';
import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/widgets/attendance_month_calendar.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../../core/l10n/l10n.dart';

/// Port of `attendance.html`, backed by `GET /attendance` — stat cards for the
/// month shown in the calendar and the session log of the selected day.
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>()..add(const AttendanceFetched()),
      child: const _AttendanceView(),
    );
  }
}

class _AttendanceView extends StatelessWidget {
  const _AttendanceView();

  @override
  Widget build(BuildContext context) {
    return DrScaffold(
      child: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          final bloc = context.read<AttendanceBloc>();

          return RefreshIndicator(
            onRefresh: () async => bloc.add(const AttendanceRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                DrBackHeader(title: context.l10n.attendanceTitle),
                _Body(state: state),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final AttendanceState state;
  const _Body({required this.state});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  /// The calendar day whose sessions are listed; opens on today.
  late DateTime _selectedDay = _today();

  /// The month shown in the calendar; the stat cards are computed from it.
  late DateTime _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month);

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSelected(AttendanceRecord record) {
    final d = record.date;
    return d != null &&
        d.year == _selectedDay.year &&
        d.month == _selectedDay.month &&
        d.day == _selectedDay.day;
  }

  bool _inVisibleMonth(AttendanceRecord record) {
    final d = record.date;
    return d != null &&
        d.year == _visibleMonth.year &&
        d.month == _visibleMonth.month;
  }

  /// The rate follows the website (QƏRAR-07): (P + L) ÷ (P + L + A + E) — an
  /// excused lesson counts as missed, but is not an absence on the card.
  ({int present, int absent, int late, int rate}) _monthStats(
      List<AttendanceRecord> records) {
    var present = 0, absent = 0, late = 0, excused = 0;
    for (final r in records.where(_inVisibleMonth)) {
      if (r.isExcused) {
        excused++;
      } else if (r.isAbsent) {
        absent++;
      } else if (r.isLate) {
        late++;
      } else if (r.isPresent) {
        present++;
      }
    }
    final total = present + absent + late + excused;
    final rate = total == 0 ? 0 : (((present + late) / total) * 100).round();
    return (present: present, absent: absent, late: late, rate: rate);
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _visibleMonth = DateTime(month.year, month.month);
      final today = _today();
      final isCurrentMonth =
          month.year == today.year && month.month == today.month;
      // Back on the current month -> today; a past month -> its 1st.
      _selectedDay =
      isCurrentMonth ? today : DateTime(month.year, month.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.isLoading && state.records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == AttendanceStatus.error) {
      return _Message(
        text: state.errorMessage ?? context.l10n.commonError,
        onRetry: () =>
            context.read<AttendanceBloc>().add(const AttendanceRefreshed()),
      );
    }

    final records = state.recentRecords;
    final stats = _monthStats(records);
    final dayRecords = records.where(_isSelected).toList();
    // 19.10.2026 — the school excused the child for the selected day.
    final permission = state.permissionOn(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _stat(context, '${stats.rate}%',
                  context.l10n.attendanceRate, context.dr.accent),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _stat(context, '${stats.absent}',
                  context.l10n.attendanceAbsent, DrColors.red),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _stat(context, '${stats.present}',
                  context.l10n.attendancePresent, context.dr.accent),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _stat(context, '${stats.late}',
                  context.l10n.attendanceLate, DrColors.teal),
            ),
          ],
        ),
        const SizedBox(height: 30),
        AttendanceMonthCalendar(
          records: records,
          permissions: state.permissions,
          selectedDay: _selectedDay,
          onDaySelected: (day) => setState(() => _selectedDay = day),
          onMonthChanged: _onMonthChanged,
        ),
        const SizedBox(height: 30),
        DrSectionHeader(title: AppDates.full(context, _selectedDay)),
        if (permission != null) ...[
          _PermissionNote(permission: permission),
          if (dayRecords.isNotEmpty) const SizedBox(height: 12),
        ],
        // On a permission day with nothing logged the note above says it all.
        if (dayRecords.isEmpty && permission == null)
          _Message(text: context.l10n.attendanceEmpty)
        else if (dayRecords.isNotEmpty)
          DrListCard(
            children: [
              for (var i = 0; i < dayRecords.length; i++)
                _log(context, dayRecords[i],
                    divider: i != dayRecords.length - 1),
            ],
          ),
      ],
    );
  }

  Widget _stat(BuildContext context, String value, String label, Color color) {
    return DrCard(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 5),
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 11, color: context.dr.textMuted)),
        ],
      ),
    );
  }

  /// One lesson: its time, the subject with the teacher under it, and the
  /// status as a tinted pill. No date — the section header above names the
  /// day — and no separate dot, which said the same as the pill.
  Widget _log(BuildContext context, AttendanceRecord record,
      {bool divider = true}) {
    final tag = _statusTag(context, record);

    return DrTransactionTile(
      leading: _LessonTime(record: record),
      title: record.lessonName ?? context.l10n.attendanceLesson,
      subtitle: record.teacher ?? '—',
      divider: divider,
      trailing: _StatusPill(tag: tag),
    );
  }
}

/// «Şagird 17–20 oktyabr tarixlərinə icazəlidir» above the lessons of a
/// permission day (server 19.10.2026, `permissions`), in the excused blue; a
/// one-day permission names its day, a part-day one adds its leaving or
/// arriving time.
///
/// Shown only for a day the permission covers — the one picked in the
/// calendar, which opens on today. It names the permission's own dates (owner,
/// 19.10.2026): the server's ready text said «bu günə» («for today»), which
/// told neither which days nor how long.
class _PermissionNote extends StatelessWidget {
  final AttendancePermission permission;
  const _PermissionNote({required this.permission});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The range as the school entered it — weekend days inside it included,
    // as the parent asked for it; its school days only if the server left the
    // ends out (`dates` is never empty, see the model).
    final from = permission.dateFrom ?? permission.dates.first;
    final to = permission.dateTo ?? permission.dates.last;
    final oneDay =
        from.year == to.year && from.month == to.month && from.day == to.day;
    final dates = AppDates.dayRange(context, from, to);
    final time = permission.time;

    final text = [
      oneDay ? l10n.attendancePermitDay(dates) : l10n.attendancePermitRange(dates),
      // A leave or arrive without a time reads as the whole day — the
      // server's rule too.
      if (permission.kind == 'leave' && time != null)
        l10n.attendancePermitLeaveAt(time),
      if (permission.kind == 'arrive' && time != null)
        l10n.attendancePermitArriveAt(time),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DrColors.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DrColors.blue.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded,
              size: 22, color: DrColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.dr.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The status as a small rounded pill in its own colour.
class _StatusPill extends StatelessWidget {
  final _StatusTag tag;
  const _StatusPill({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tag.color,
        ),
      ),
    );
  }
}

/// The lesson's clock time (server `start_time` / `end_time`, 17.10.2026):
/// start bold, end muted below; a dash when the record has no lesson slot.
/// Tabular figures keep the column aligned row to row; a minimum width rather
/// than a fixed one lets it grow with large text scales.
class _LessonTime extends StatelessWidget {
  final AttendanceRecord record;
  const _LessonTime({required this.record});

  @override
  Widget build(BuildContext context) {
    const digits = [FontFeature.tabularFigures()];
    final start = record.startShort;
    final end = record.endShort;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            start ?? '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: start == null ? context.dr.textMuted : context.dr.textMain,
              fontFeatures: digits,
            ),
          ),
          if (end != null)
            Text(
              end,
              style: TextStyle(
                fontSize: 11,
                color: context.dr.textMuted,
                fontFeatures: digits,
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.dr.textMuted)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(
                onPressed: onRetry, child: Text(context.l10n.commonRetry)),
          ],
        ],
      ),
    );
  }
}

/// A small status badge derived from the record's raw status text.
class _StatusTag {
  final String label;
  final Color color;
  const _StatusTag(this.label, this.color);
}

/// Takes a [context] because the "present" tag paints the brand accent as a dot
/// and as text, both of which need the light theme's darker variant.
_StatusTag _statusTag(BuildContext context, AttendanceRecord record) {
  // Before the absent check: an excused lesson may still arrive as `Absent`
  // with the `excused` flag (backend E-038).
  if (record.isExcused) {
    return _StatusTag(context.l10n.attendanceExcusedTag, DrColors.blue);
  }
  if (record.isAbsent) {
    return _StatusTag(context.l10n.attendanceAbsent, DrColors.red);
  }
  if (record.isLate) {
    return _StatusTag(context.l10n.attendanceLateTag, DrColors.teal);
  }
  if (record.isPresent) {
    return _StatusTag(context.l10n.attendancePresent, context.dr.accent);
  }
  if (record.isMeeting) {
    return _StatusTag(context.l10n.attendanceMeetingTag, DrColors.purple);
  }
  return _StatusTag(record.status, context.dr.accent);
}