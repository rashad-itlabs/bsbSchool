import 'package:equatable/equatable.dart';

/// The authenticated user returned by the login endpoint.
class AuthUser extends Equatable {
  final int id;

  /// The account holder (parent) — shown on the profile screen.
  final String name;

  /// The student tied to this account — shown in the dashboard header.
  final String childName;

  final String email;

  /// The student's class, straight from the login response. Nullable because
  /// an account without an active student session has neither.
  final int? classId;
  final String? className;

  const AuthUser({
    required this.id,
    required this.name,
    required this.childName,
    required this.email,
    this.classId,
    this.className,
  });

  /// First letter of the first two words — e.g. "Samir Aliyev" -> "SA".
  static String initialsOf(String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '';
    return words.take(2).map((w) => w.substring(0, 1).toUpperCase()).join();
  }

  @override
  List<Object?> get props => [id, name, childName, email, classId, className];
}
