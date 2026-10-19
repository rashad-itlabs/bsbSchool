import 'package:equatable/equatable.dart';

import 'homework.dart';
import 'homework_status_info.dart';

/// The full `GET /homework` payload: the student's class plus the homework
/// list scoped to it. [classId] is null when the student has no session yet.
class HomeworkContent extends Equatable {
  final int? classId;
  final String? className;
  final List<Homework> homeworks;

  /// The server's `statuses` dictionary in the order it sent it — the
  /// website's «Статус» filter order — which the filter sheet lists. Empty
  /// on a server older than 16.10.2026.
  final List<HomeworkStatusInfo> statuses;

  const HomeworkContent({
    this.classId,
    this.className,
    this.homeworks = const [],
    this.statuses = const [],
  });

  @override
  List<Object?> get props => [classId, className, homeworks, statuses];
}
