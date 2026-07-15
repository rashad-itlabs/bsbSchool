import 'package:equatable/equatable.dart';

import 'homework.dart';

/// The full `GET /homework` payload: the student's class plus the homework
/// list scoped to it. [classId] is null when the student has no session yet.
class HomeworkContent extends Equatable {
  final int? classId;
  final String? className;
  final List<Homework> homeworks;

  const HomeworkContent({
    this.classId,
    this.className,
    this.homeworks = const [],
  });

  @override
  List<Object?> get props => [classId, className, homeworks];
}
