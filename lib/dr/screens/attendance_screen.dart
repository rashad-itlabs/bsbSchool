import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection_container.dart';
import '../../features/attendance/domain/entities/attendance_record.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/widgets/attendance_week_overview.dart';
import '../theme/dr_colors.dart';
import '../widgets/dr_widgets.dart';

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
                const DrBackHeader(title: 'Davamiyyət'),
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

class _Body extends StatelessWidget {
  final AttendanceState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == AttendanceStatus.error) {
      return _Message(
        text: state.errorMessage ?? 'Xəta baş verdi',
        onRetry: () =>
            context.read<AttendanceBloc>().add(const AttendanceRefreshed()),
      );
    }

    final summary = state.summary;
    final records = state.recentRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _stat(context, '${summary.attendanceRate}%', 'İştirak',
                  DrColors.accentGreen),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _stat(
                  context, '${summary.absent}', 'Qayıb', DrColors.red),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _stat(context, '${summary.present}', 'Gəlib',
                  DrColors.accentGreen),
            ),
            const SizedBox(width: 15),
            Expanded(
              child:
                  _stat(context, '${summary.late}', 'Gecikmə', DrColors.teal),
            ),
          ],
        ),
        const SizedBox(height: 30),
        AttendanceWeekOverview(records: records),
        const SizedBox(height: 30),
        const DrSectionHeader(title: 'Son qeydlər'),
        if (records.isEmpty)
          const _Message(text: 'Qeyd tapılmadı')
        else
          DrListCard(
            children: [
              for (var i = 0; i < records.length; i++)
                _log(context, records[i], divider: i != records.length - 1),
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
    final tag = _statusTag(record);
    final title = record.section ?? record.subject ?? 'Dərs';
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
            TextButton(onPressed: onRetry, child: const Text('Yenidən cəhd et')),
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

_StatusTag _statusTag(AttendanceRecord record) {
  if (record.isAbsent) return const _StatusTag('Qayıb', DrColors.red);
  if (record.isLate) return const _StatusTag('Gecikib', DrColors.teal);
  if (record.isPresent) return const _StatusTag('Gəlib', DrColors.accentGreen);
  return _StatusTag(record.status, DrColors.accentGreen);
}
