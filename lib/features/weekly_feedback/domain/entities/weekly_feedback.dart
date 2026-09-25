import 'package:equatable/equatable.dart';

/// One entry of the `data` array of the weekly feedback endpoint: a teacher's
/// comment on the student for the week that was asked for.
class WeeklyFeedback extends Equatable {
  /// What the comment is about (`kind`, e.g. `student`), and the server's own
  /// heading for it (`kind_label`, e.g. "About your child").
  final String? kind;
  final String? kindLabel;

  final String? teacher;

  /// The subjects the comment covers, as the server sends them: one
  /// comma-separated string.
  final String? subjects;

  /// The feedback itself (`text`).
  final String text;

  /// Files the teacher attached (`files`).
  final List<FeedbackAttachment> files;

  /// The day it was written (`date`).
  final DateTime? date;

  const WeeklyFeedback({
    required this.text,
    this.kind,
    this.kindLabel,
    this.teacher,
    this.subjects,
    this.files = const [],
    this.date,
  });

  @override
  List<Object?> get props =>
      [kind, kindLabel, teacher, subjects, text, files, date];
}

/// A file a teacher uploaded alongside a [WeeklyFeedback].
class FeedbackAttachment extends Equatable {
  /// File name as shown to the parent, e.g. `quiz_results.pdf`.
  final String name;

  /// Absolute URL the file downloads from.
  final String url;

  const FeedbackAttachment({required this.name, required this.url});

  /// Lower-case extension without the dot, or '' when the name has none.
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  @override
  List<Object?> get props => [name, url];
}
