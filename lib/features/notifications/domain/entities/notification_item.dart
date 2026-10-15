import 'package:equatable/equatable.dart';

/// What a feed entry is about — the filter pills on the notifications tab and
/// the entry's emoji. [homework] and [teacher] have no pill (owner,
/// 15.10.2026): those entries are listed under "all" only.
///
/// Its own enum, not `NotificationKind`: that one is the list of switches on
/// the settings card, and a teacher's message or a school announcement is not
/// something a parent turns off. Attendance, exam and cafeteria entries do not
/// exist yet — the server will send them once those notices are generated
/// automatically, and they land in their pill without an app update.
enum NotificationCategory {
  attendance,
  exam,
  cafeteria,
  homework,
  teacher,
  system;

  /// The server's `category` (15.10.2026); null for a value this build does
  /// not know, so the entry falls back to what its other fields say.
  static NotificationCategory? parse(String? value) =>
      switch (value?.trim().toLowerCase()) {
        'attendance' => attendance,
        'exam' || 'examination' => exam,
        'cafeteria' || 'buffet' || 'bufet' || 'food_card' => cafeteria,
        'homework' || 'home_work' => homework,
        'teacher' => teacher,
        'system' || 'school' => system,
        _ => null,
      };
}

/// One entry of the `data` array returned by `GET /notifications`.
///
/// A single feed carries both class-wide and student-specific messages; the
/// [sendType] tells them apart (`student` vs `class`).
class NotificationItem extends Equatable {
  final int id;

  /// Who the message was targeted at: `student`, `class`, `parent` — or
  /// `school` for an admin push (see [isSchoolPush]).
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

  /// Where the entry comes from. `push` — an announcement the school sent from
  /// the admin panel as a push notification (15.10.2026); null for a teacher's
  /// message or a homework entry, which predate the field.
  final String? source;

  /// The server's `category`, as sent — read through [category].
  final String? categoryName;

  const NotificationItem({
    required this.id,
    this.sendType = 'student',
    this.title = '',
    this.message = '',
    this.className,
    this.sender,
    this.file,
    this.date,
    this.source,
    this.categoryName,
  });

  /// Normalised target buckets so the UI never string-compares raw text.
  bool get isForStudent => sendType.toLowerCase() == 'student';
  bool get isForClass => sendType.toLowerCase() == 'class';

  /// A school announcement (admin push). Its `id` is the push's own id — the
  /// `notification_id` a tapped push carries — and may equal a teacher
  /// message's id, so the two are only ever matched together with this flag.
  bool get isSchoolPush =>
      source?.toLowerCase() == 'push' || sendType.toLowerCase() == 'school';

  /// Which pill the entry is listed under. A server without `category` (or a
  /// value this build does not know) still sorts its school announcements into
  /// [NotificationCategory.system]; everything else from it is a teacher's —
  /// it gives no way to tell a homework entry apart.
  NotificationCategory get category =>
      NotificationCategory.parse(categoryName) ??
      (isSchoolPush
          ? NotificationCategory.system
          : NotificationCategory.teacher);

  bool get hasFile => file != null && file!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    sendType,
    title,
    message,
    className,
    sender,
    file,
    date,
    source,
    categoryName,
  ];
}
