import '../../domain/entities/auth_user.dart';
import 'child_account_model.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    super.id,
    super.accountId,
    super.pushId,
    required super.name,
    required super.childName,
    required super.role,
    required super.email,
    super.classId,
    super.className,
    super.children,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      // The login response names it `user_id`; the copy we cache back through
      // [toJson] (and any nested `user` object) names it `id`. Kept null when
      // absent rather than defaulting to 0, because a parent with no student
      // linked yet is exactly the `user_id: null` case — see
      // [AuthUser.needsChild].
      id: _asInt(json['user_id'] ?? json['id']),
      // The account's own row. `user_id` is the student, not the parent — see
      // [AuthUser.accountId]. `parent_ids` is what the login endpoint calls it
      // (plural, though it holds one); the singular spellings are accepted so
      // a rename on the Laravel side doesn't silently orphan every device.
      accountId: _asInt(
        json['parent_ids'] ?? json['parent_id'] ?? json['account_id'],
      ),
      // The address the backend itself hands out. Kept as text, not parsed to
      // an int: it is an identity string, and the day it becomes `parent_66`
      // the app should carry it through unchanged.
      pushId: _asNullableString(json['push_external_id']),
      name: json['name'] as String? ?? '',
      childName: json['child_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      email: json['email'] as String? ?? '',
      classId: _asInt(json['class_id']),
      className: _asNullableString(json['className'] ?? json['class_name']),
      // `info` — the students linked to a parent account, with the login the
      // school issued for each. Absent for teacher / student logins.
      children: _asChildren(json['info']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // Read back by [fromJson], so the cached session keeps addressing the
        // same OneSignal user across restarts.
        'account_id': accountId,
        'push_external_id': pushId,
        'name': name,
        'child_name': childName,
        'role': role,
        'email': email,
        'class_id': classId,
        'className': className,
        'info':
            children.map((c) => ChildAccountModel.from(c).toJson()).toList(),
      };

  static List<ChildAccountModel> _asChildren(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => ChildAccountModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _asNullableString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
