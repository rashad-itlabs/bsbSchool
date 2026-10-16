import 'package:equatable/equatable.dart';

import 'homework_submission.dart';

/// One entry of the `data` array returned by `GET /homework`.
class Homework extends Equatable {
  final int id;

  /// The homework title (`homework_name`).
  final String name;

  /// Raw HTML from the server (`<p>...</p>`). The UI strips the tags.
  final String description;

  /// All nullable on the server — sometimes catalogued without them.
  final String? subject;
  final String? section;
  final String? teacher;

  /// When the homework was set.
  final DateTime? homeworkDate;

  /// Deadline the student submits by.
  final DateTime? submitDate;

  /// When the teacher evaluates it.
  final DateTime? evaluationDate;

  /// When the teacher posted it to the system (`created_at`, school time).
  /// Null on a server older than 15.10.2026.
  final DateTime? createdAt;

  /// The moment it moves to the inactive tab (`archive_at`): the deadline day
  /// at 08:00 school time. The server owns this rule (`HomeworkArchive`, the
  /// website reads the same one) — the app only compares it with the clock.
  /// Null when there is no usable deadline.
  final DateTime? archiveAt;

  /// Absolute URL of an attached file, when present.
  final String? documentUrl;

  final int? classId;
  final int? subjectId;

  /// The student's hand-in; null until it has been marked as submitted.
  final HomeworkSubmission? submission;

  bool get isSubmitted => submission != null;

  const Homework({
    required this.id,
    required this.name,
    this.description = '',
    this.subject,
    this.section,
    this.teacher,
    this.homeworkDate,
    this.submitDate,
    this.evaluationDate,
    this.createdAt,
    this.archiveAt,
    this.documentUrl,
    this.classId,
    this.subjectId,
    this.submission,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        subject,
        section,
        teacher,
        homeworkDate,
        submitDate,
        evaluationDate,
        createdAt,
        archiveAt,
        documentUrl,
        classId,
        subjectId,
        submission,
      ];
}
