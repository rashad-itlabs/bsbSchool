import 'package:equatable/equatable.dart';

/// The `submission` object of a homework: present once the student's work has
/// been marked as handed in, null otherwise. Every field is optional on the
/// server.
class HomeworkSubmission extends Equatable {
  /// When the submission was recorded (`marked_at`).
  final DateTime? markedAt;

  final String? notes;

  /// URL of the file handed in, and its original file name.
  final String? documentUrl;
  final String? originalName;

  final String? grade;
  final String? teacherComment;

  const HomeworkSubmission({
    this.markedAt,
    this.notes,
    this.documentUrl,
    this.originalName,
    this.grade,
    this.teacherComment,
  });

  @override
  List<Object?> get props =>
      [markedAt, notes, documentUrl, originalName, grade, teacherComment];
}
