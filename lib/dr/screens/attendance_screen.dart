import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../core/l10n/app_dates.dart';
import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/widgets/attendance_month_calendar.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';
import '../../core/l10n/l10n.dart';

/// Port of `attendance.html`, backed by `GET /attendance` — summary stat cards
/// and the recent session log for the logged-in student.
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

    final summary = state.summary;
    final records = state.recentRecords;
    final dayRecords = records.where(_isSelected).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _stat(context, '${summary.attendanceRate}%', context.l10n.attendanceRate,
                  context.dr.accent),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _stat(
                  context, '${summary.absent}', context.l10n.attendanceAbsent, DrColors.red),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _stat(context, '${summary.present}', context.l10n.attendancePresent,
                  context.dr.accent),
            ),
            const SizedBox(width: 15),
            Expanded(
              child:
                  _stat(context, '${summary.late}', context.l10n.attendanceLate, DrColors.teal),
            ),
          ],
        ),
        const SizedBox(height: 30),
        AttendanceMonthCalendar(
          records: records,
          selectedDay: _selectedDay,
          onDaySelected: (day) => setState(() => _selectedDay = day),
        ),
        const SizedBox(height: 30),
        DrSectionHeader(title: AppDates.full(context, _selectedDay)),
        if (dayRecords.isEmpty)
          _Message(text: context.l10n.attendanceEmpty)
        else
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

  Widget _log(BuildContext context, AttendanceRecord record,
      {bool divider = true}) {
    final tag = _statusTag(context, record);
    final title = record.section ?? record.subject ?? context.l10n.attendanceLesson;
    final subtitle = [
      if (record.date != null) DateFormat('dd MMM yyyy').format(record.date!),
      if (record.teacher != null) record.teacher!,
    ].join(' • ');

    return DrTransactionTile(
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: tag.color, shape: BoxShape.circle),
      ),
      title: title,
      subtitle: subtitle.isEmpty ? '—' : subtitle,
      divider: divider,
      trailing: Text(tag.label,
          style: TextStyle(fontSize: 12, color: tag.color)),
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
            TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
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
  if (record.isAbsent) return _StatusTag(context.l10n.attendanceAbsent, DrColors.red);
  if (record.isLate) return _StatusTag(context.l10n.attendanceLateTag, DrColors.teal);
  if (record.isPresent) return _StatusTag(context.l10n.attendancePresent, context.dr.accent);
  return _StatusTag(record.status, context.dr.accent);
}
