import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.name,
    required super.childName,
    required super.email,
    super.classId,
    super.className,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      // The login response names it `user_id`; the copy we cache back through
      // [toJson] (and any nested `user` object) names it `id`.
      id: _asInt(json['user_id'] ?? json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      childName: json['child_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      classId: _asInt(json['class_id']),
      className: _asNullableString(json['className'] ?? json['class_name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'child_name': childName,
        'email': email,
        'class_id': classId,
        'className': className,
      };

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _asNullableString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
