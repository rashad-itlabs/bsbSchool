import 'dart:convert';

import 'package:bsbschool/features/auth/data/models/auth_session_model.dart';
import 'package:bsbschool/features/auth/data/models/auth_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _loginBody = '''
{
  "token": "1|abc",
  "user_id": 12,
  "class_id": 94,
  "className": "Class Group 7",
  "name": "Rashad Aliyev",
  "child_name": "Saleh Aliyev",
  "email": "parent@bsb.edu.az"
}
''';

void main() {
  test('login response exposes user_id, class_id and className', () {
    final session = AuthSessionModel.fromJson(
      jsonDecode(_loginBody) as Map<String, dynamic>,
    );

    expect(session.token, '1|abc');
    expect(session.user.id, 12);
    expect(session.user.classId, 94);
    expect(session.user.className, 'Class Group 7');
  });

  test('cached user survives the toJson/fromJson round trip', () {
    final original = AuthSessionModel.fromJson(
      jsonDecode(_loginBody) as Map<String, dynamic>,
    ).user as AuthUserModel;

    final restored = AuthUserModel.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );

    expect(restored, original);
  });
}
