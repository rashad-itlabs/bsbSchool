import 'package:equatable/equatable.dart';

/// One entry of the `data` array returned by `GET /attendance`.
class AttendanceRecord extends Equatable {
  final int id;

  /// The lesson day (`date`).
  final DateTime? date;

  /// All nullable on the server — a record may be logged without them.
  final String? subject;
  final String? section;
  final String? className;
  final String? teacher;

  /// Raw status text: `Present`, `Late`, `Absent`, `Meeting`, `Excused`.
  final String status;

  /// The school excused the lesson (QƏRAR-107, server 17.10.2026). Until the
  /// server sends `Excused` as the [status] itself (`.env` API_RAW_EXCUSED,
  /// backend question E-038) such a lesson arrives as `Absent` with this flag.
  final bool excused;

  /// What the school wrote when it excused the lesson (`excused_notes`, server
  /// 20.10.2026) — the permission's note, not the teacher's [note]; a text the
  /// [note] already says is left out. Only on an excused lesson; empty when
  /// nobody wrote one, and on an older server.
  final List<String> excusedNotes;

  /// The same in the app language, worded by the server (`excused_notes_text`,
  /// «İcazə: …»).
  final List<String> excusedNotesText;

  /// Effort score the teacher logged (0 when not graded).
  final int effort;

  /// Free-text remark, when present.
  final String? note;

  /// The lesson's bell slot (`period`, e.g. `Period 3`) and raw `HH:mm:ss`
  /// clock times (`start_time` / `end_time`, server since 17.10.2026). All null
  /// for a record logged without a lesson slot, and on an older server.
  final String? period;
  final String? startTime;
  final String? endTime;

  /// A late arrival (QƏRAR-114, server 19.10.2026): when the child came in
  /// (`late_at`, `HH:mm`) and how many minutes after the lesson began
  /// (`late_minutes`). Only on `Late`; null on a Late logged before 19.10,
  /// one without a lesson slot, and on an older server.
  final String? lateAt;
  final int? lateMinutes;

  /// `Absent` here, but present or late in another lesson at the same time
  /// (a parallel option or support group; server 19.10.2026) — the website
  /// says so under the absence. [inOtherLessonText] is the server's wording
  /// in the app language.
  final bool inOtherLesson;
  final String? inOtherLessonText;

  const AttendanceRecord({
    required this.id,
    this.date,
    this.subject,
    this.section,
    this.className,
    this.teacher,
    this.status = 'Present',
    this.excused = false,
    this.excusedNotes = const [],
    this.excusedNotesText = const [],
    this.effort = 0,
    this.note,
    this.period,
    this.startTime,
    this.endTime,
    this.lateAt,
    this.lateMinutes,
    this.inOtherLesson = false,
    this.inOtherLessonText,
  });

  /// Normalised status buckets so the UI never string-compares raw text.
  bool get isPresent => status.toLowerCase() == 'present';
  bool get isLate => status.toLowerCase() == 'late';

  /// Excused either way the server says it — the raw word, or `Absent` plus
  /// the [excused] flag — so the app needs no change when the server flips.
  bool get isExcused => excused || status.toLowerCase() == 'excused';

  /// A real absence: an excused lesson is not one (the website, QƏRAR-107).
  bool get isAbsent => status.toLowerCase() == 'absent' && !isExcused;

  /// An excused lesson the school left a note on — the one whose pill opens it.
  bool get hasExcusedNote => isExcused && excusedNotes.isNotEmpty;

  /// Away at a meeting during the lesson — 27 marks since September; nothing
  /// on the server counts it (backend docs), and neither do the stat cards.
  bool get isMeeting => status.toLowerCase() == 'meeting';

  /// What the lesson is called on screen. The server's [section] is the
  /// section's auto-name — `Geography-Year 5 <form tutor> <teacher>`, 1019 of
  /// 1020 sections on 17.10.2026 — which repeats the subject, the class and
  /// the teacher already shown beside it, so the [subject] stands in for it.
  /// A name the school gave the section itself (`sections.display_name`) does
  /// not start with the subject that way, and is kept. Null when the record
  /// carries neither.
  String? get lessonName {
    final subject = this.subject?.trim();
    final section = this.section?.trim();
    if (section == null || section.isEmpty) {
      return (subject == null || subject.isEmpty) ? null : subject;
    }
    if (subject == null || subject.isEmpty) return section;
    return section.startsWith('$subject-') ? subject : section;
  }

  /// `09:20:00` -> `09:20`; null when the record has no lesson slot.
  String? get startShort => _short(startTime);
  String? get endShort => _short(endTime);

  static String? _short(String? clock) {
    if (clock == null || clock.length < 5) return clock;
    return clock.substring(0, 5);
  }

  @override
  List<Object?> get props => [
        id,
        date,
        subject,
        section,
        className,
        teacher,
        status,
        excused,
        excusedNotes,
        excusedNotesText,
        effort,
        note,
        period,
        startTime,
        endTime,
        lateAt,
        lateMinutes,
        inOtherLesson,
        inOtherLessonText,
      ];
}
