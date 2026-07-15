import 'package:equatable/equatable.dart';

/// One entry of a group's `results` array returned by `GET /examinations`.
///
/// Everything but [id]/[absent] is nullable on the server: a result can be
/// catalogued (subject + exam name) long before it is actually marked.
class ExamResult extends Equatable {
  final int id;

  /// The subject the exam belongs to (`English`, `Riyaziyyat`, ...).
  final String? subject;

  /// The exam label (`Formative 1`, `Mid Term`, `End of Term`, ...).
  final String? exam;

  /// The class group the exam was sat in (`Class Group 7`).
  final String? className;

  /// Kept as text on purpose: the server sends numbers (`88.00`), or `null`
  /// interchangeably, and the list only ever displays it.
  final String? mark;

  /// Letter grade for the [mark] (`A`, `A*`, ...). Null until the exam is marked.
  final String? grade;

  /// Numeric weight of the [grade] used for averages (`0` when not scored yet).
  final num? gradePoint;

  final String? behaviour;
  final String? effort;
  final String? note;

  /// The student did not sit the exam.
  final bool absent;

  const ExamResult({
    required this.id,
    this.subject,
    this.exam,
    this.className,
    this.mark,
    this.grade,
    this.gradePoint,
    this.behaviour,
    this.effort,
    this.note,
    this.absent = false,
  });

  /// True once the exam has an actual mark (and the student was present).
  bool get isGraded => !absent && mark != null && mark!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        subject,
        exam,
        className,
        mark,
        grade,
        gradePoint,
        behaviour,
        effort,
        note,
        absent,
      ];
}
