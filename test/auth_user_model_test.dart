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
  "role": "parent",
  "email": "parent@bsb.edu.az"
}
''';

/// The real response for a parent whose account has no student linked yet.
const _unlinkedParentBody = '''
{
  "name": "Tahir Alizade",
  "child_name": null,
  "role": "parent",
  "user_id": null,
  "class_id": null,
  "class_name": null,
  "token": "32|jXlEO2XsPsQEOqJocYQU3H4mpiR27vbSjn3AlTyZ4ea790a5"
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

  // `role` decides which shell AuthGate mounts, so it has to survive being
  // cached — otherwise a teacher is demoted to the student portal on relaunch.
  test('role survives the toJson/fromJson round trip', () {
    const teacher = AuthUserModel(
      id: 4108,
      name: 'Elena Borisovna',
      childName: '',
      role: 'teacher',
      email: 'teacher@bsb.edu.az',
    );

    final restored = AuthUserModel.fromJson(
      jsonDecode(jsonEncode(teacher.toJson())) as Map<String, dynamic>,
    );

    expect(restored.role, 'teacher');
    expect(restored.isTeacher, isTrue);
  });

  group('a parent with no student linked', () {
    AuthUserModel unlinkedParent() => AuthSessionModel.fromJson(
          jsonDecode(_unlinkedParentBody) as Map<String, dynamic>,
        ).user as AuthUserModel;

    // A `?? 0` default here used to make `user_id: null` indistinguishable
    // from a real student id, so the AddChildScreen branch never fired.
    test('keeps a null user_id null instead of collapsing it to 0', () {
      expect(unlinkedParent().id, isNull);
    });

    test('needs a child', () {
      expect(unlinkedParent().needsChild, isTrue);
    });

    test('survives the toJson/fromJson round trip still needing a child', () {
      final restored = AuthUserModel.fromJson(
        jsonDecode(jsonEncode(unlinkedParent().toJson()))
            as Map<String, dynamic>,
      );

      expect(restored.id, isNull);
      expect(restored.needsChild, isTrue);
    });

    test('a parent with a student linked does not need a child', () {
      final session = AuthSessionModel.fromJson(
        jsonDecode(_loginBody) as Map<String, dynamic>,
      );

      expect(session.user.isParent, isTrue);
      expect(session.user.needsChild, isFalse);
    });

    // Parent-only, per the requirement: a teacher has no student to link, so
    // a roleless or teacher account must never be sent to AddChildScreen.
    test('is parent-only', () {
      for (final role in ['teacher', 'student', 'admin', '']) {
        expect(
          AuthUserModel(name: 'X', childName: '', role: role, email: 'x@y.z')
              .needsChild,
          isFalse,
          reason: role,
        );
      }
    });
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
