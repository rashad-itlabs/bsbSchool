import 'package:equatable/equatable.dart';

import 'child_account.dart';

/// The authenticated user returned by the login endpoint.
class AuthUser extends Equatable {
  /// The student tied to this account (`user_id` in the login response).
  /// Null for a parent whose account has no student linked to it yet — see
  /// [needsChild].
  final int? id;

  /// The account row itself, from the login response's `parent_ids`.
  ///
  /// Deliberately separate from [id]: for a student or a teacher the two are
  /// the same, but for a parent [id] is *their student*, which `/selectChild`
  /// moves and which both parents of one child share. Anything that must
  /// identify the person who signed in — [pushExternalId] — needs this one.
  final int? accountId;

  /// The push identity the backend names for itself (`push_external_id`).
  ///
  /// Taken verbatim when it is there. The backend is what addresses the
  /// notification, so it gets to spell the address — a change on that side
  /// reaches the device on the next sign-in with no app release.
  final String? pushId;

  /// The account holder (parent) — shown on the profile screen.
  final String name;

  /// The student tied to this account — shown in the dashboard header.
  final String childName;

  final String role;

  final String email;

  /// The student's class, straight from the login response. Nullable because
  /// an account without an active student session has neither.
  final int? classId;
  final String? className;

  /// Every student linked to this account (the login response's `info`), each
  /// with the credentials the school issued for them. Empty for a teacher or a
  /// student account — only a parent login carries it.
  final List<ChildAccount> children;

  const AuthUser({
    this.id,
    this.accountId,
    this.pushId,
    required this.name,
    required this.childName,
    required this.role,
    required this.email,
    this.classId,
    this.className,
    this.children = const [],
  });

  /// First letter of the first two words — e.g. "Samir Aliyev" -> "SA".
  static String initialsOf(String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '';
    return words.take(2).map((w) => w.substring(0, 1).toUpperCase()).join();
  }

  /// Drives which shell [AuthGate] mounts. The login endpoint is the only
  /// source of [role], so match leniently and treat anything else as a
  /// student/parent account.
  bool get isTeacher => role.trim().toLowerCase() == 'teacher';

  bool get isParent => role.trim().toLowerCase() == 'parent';

  /// A parent can log in before the school has linked a student to their
  /// account — the response then carries `user_id: null` and the app has no
  /// student whose data it could show. [AuthGate] sends these accounts to
  /// `AddChildScreen` to enter an admission number instead of the dashboard.
  /// Deliberately parent-only: a teacher has no student to link.
  bool get needsChild => isParent && id == null;

  /// How OneSignal — and therefore the backend — addresses this device.
  ///
  /// [pushId] wins when the response carries it: `push_external_id: "66"`
  /// makes the address `66`, exactly what Laravel puts in `include_aliases`.
  /// Keeping the two in one field on the server is the point — the app never
  /// has to agree on a format, it just repeats what it was told.
  ///
  /// Otherwise it is composed as `{role}_{id}` — `parent_66`, `student_3139`,
  /// `teacher_4108` — from [accountId] (`parent_ids`), or from [id] when even
  /// that is absent. The role is part of the composed form because a parent
  /// and a student are numbered in different tables, so `66` on its own would
  /// eventually address two different people. That caveat applies to a raw
  /// [pushId] too, and is the backend's to resolve.
  ///
  /// Null for a parent with no student linked yet and no `parent_ids` — there
  /// is nothing stable to key on, and that account can't see the app anyway
  /// (see [needsChild]).
  String? get pushExternalId {
    final given = pushId?.trim();
    if (given != null && given.isNotEmpty) return given;

    final key = accountId ?? id;
    if (key == null) return null;

    final slug = role.trim().toLowerCase();
    return '${slug.isEmpty ? 'user' : slug}_$key';
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        pushId,
        name,
        childName,
        role,
        email,
        classId,
        className,
        children,
      ];
}
