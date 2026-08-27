import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../cubit/weekly_plan_cubit.dart';
import '../../../../core/l10n/l10n.dart';

class WeeklyPlanPage extends StatelessWidget {
  const WeeklyPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WeeklyPlanCubit>()..loadPlan(),
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.featureWeeklyPlan)),
        body: BlocBuilder<WeeklyPlanCubit, WeeklyPlanState>(
          builder: (context, state) {
            if (state.status == WeeklyPlanStatus.loading ||
                state.status == WeeklyPlanStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == WeeklyPlanStatus.error) {
              return Center(child: Text(state.message ?? context.l10n.commonErrorShort));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.days.length,
              itemBuilder: (context, i) {
                final day = state.days[i];
                return Card(
                  child: ExpansionTile(
                    initiallyExpanded: i == 0,
                    title: Text(day.day,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(context.l10n.weeklyLessonCount(day.lessons.length)),
                    children: day.lessons
                        .map((l) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                child: Text('${l.order}',
                                    style: const TextStyle(fontSize: 12)),
                              ),
                              title: Text(l.subject),
                              subtitle:
                                  Text(context.l10n.weeklyTeacherRoom(l.teacher, l.room)),
                              trailing: Text(l.time,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
