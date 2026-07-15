import 'package:equatable/equatable.dart';

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

  /// Absolute URL of an attached file, when present.
  final String? documentUrl;

  final int? classId;
  final int? subjectId;

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
    this.documentUrl,
    this.classId,
    this.subjectId,
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
        documentUrl,
        classId,
        subjectId,
      ];
}
