import 'package:equatable/equatable.dart';

/// One entry of the `data` array returned by `GET /notifications`.
///
/// A single feed carries both class-wide and student-specific messages; the
/// [sendType] tells them apart (`student` vs `class`).
class NotificationItem extends Equatable {
  final int id;

  /// Who the message was targeted at: `student` or `class`.
  final String sendType;

  final String title;
  final String message;

  /// The class the message belongs to, when the server scopes it to one.
  final String? className;

  /// Display name of the teacher / staff member who sent it.
  final String? sender;

  /// Optional attachment URL; null when the message has none.
  final String? file;

  /// When the notification was sent.
  final DateTime? date;

  const NotificationItem({
    required this.id,
    this.sendType = 'student',
    this.title = '',
    this.message = '',
    this.className,
    this.sender,
    this.file,
    this.date,
  });

  /// Normalised target buckets so the UI never string-compares raw text.
  bool get isForStudent => sendType.toLowerCase() == 'student';
  bool get isForClass => sendType.toLowerCase() == 'class';

  bool get hasFile => file != null && file!.isNotEmpty;

  @override
  List<Object?> get props =>
      [id, sendType, title, message, className, sender, file, date];
}
