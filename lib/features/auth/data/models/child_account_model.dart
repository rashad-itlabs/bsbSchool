import '../../domain/entities/child_account.dart';

class ChildAccountModel extends ChildAccount {
  const ChildAccountModel({
    super.childId,
    super.classId,
    super.username,
    super.className,
    super.childName,
    super.childSurname,
    super.email,
    super.password,
    super.paymentId,
  });

  /// Lets [AuthUserModel.toJson] serialize a list typed as the plain entity.
  factory ChildAccountModel.from(ChildAccount child) {
    return ChildAccountModel(
      childId: child.childId,
      classId: child.classId,
      username: child.username,
      className: child.className,
      childName: child.childName,
      childSurname: child.childSurname,
      email: child.email,
      password: child.password,
      paymentId: child.paymentId,
    );
  }

  factory ChildAccountModel.fromJson(Map<String, dynamic> json) {
    return ChildAccountModel(
      childId: _asInt(json['child_id']),
      classId: _asInt(json['class_id']),
      username: _asString(json['username']),
      className: _asString(json['class_name']),
      childName: _asString(json['child_name']),
      childSurname: _asString(json['child_surname']),
      email: _asString(json['email']),
      password: _asString(json['password']),
      paymentId: _asString(json['payment_id']),
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'class_id': classId,
        'username': username,
        'class_name': className,
        'child_name': childName,
        'child_surname': childSurname,
        'email': email,
        'password': password,
        'payment_id': paymentId,
      };

  static int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _asString(dynamic value) => value?.toString().trim() ?? '';
}
