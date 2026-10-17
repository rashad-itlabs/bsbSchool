import 'package:equatable/equatable.dart';

import 'homework_status_info.dart';
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

  /// The teacher's mark, when there is one. Present for «done» — but also for
  /// «not done» and «absent» (codes 3 / 6), so it does NOT mean "submitted".
  final HomeworkSubmission? submission;

  /// The server's status (`status` key, `status_code`, `status_label` in the
  /// request language); null on a server older than 08.10.2026.
  final String? status;
  final int? statusCode;
  final String? statusLabel;

  /// This status's entry in the response's `statuses` dictionary (labels in
  /// every language, colour, hint); null when the server sent no dictionary.
  final HomeworkStatusInfo? statusInfo;

  /// Marked as done. The server's status decides; only a server without one
  /// falls back to "there is a mark", which used to be the whole rule.
  bool get isSubmitted =>
      status != null ? status == 'submitted' : submission != null;

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
    this.status,
    this.statusCode,
    this.statusLabel,
    this.statusInfo,
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
        status,
        statusCode,
        statusLabel,
        statusInfo,
      ];
}
