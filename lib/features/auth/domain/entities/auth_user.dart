import 'package:equatable/equatable.dart';

import 'child_account.dart';

/// The authenticated user returned by the login endpoint.
class AuthUser extends Equatable {
  /// The student tied to this account (`user_id` in the login response).
  /// Null for a parent whose account has no student linked to it yet — see
  /// [needsChild].
  final int? id;

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

  @override
  List<Object?> get props =>
      [id, name, childName, role, email, classId, className, children];
}
