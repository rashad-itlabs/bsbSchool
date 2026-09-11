import 'dart:typed_data';

import 'package:bsbschool/core/error/exceptions.dart';
import 'package:bsbschool/features/auth/data/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// One student, in the shape `info` entries arrive in.
const _child = '''
{
  "child_id": 4021,
  "class_id": 91,
  "class_name": "Class Group 4",
  "child_name": "Nigar",
  "child_surname": "Alizade",
  "email": "std_4021@bsb.edu.az",
  "password": "Kd83nQpz",
  "payment_id": "NA4021"
}
''';

/// What `/attachChild` answers with when it echoes the whole session back —
/// the shape `/login` uses, minus the token.
const _fullUserBody = '''
{
  "success": true,
  "message": "Şagird hesabınıza əlavə edildi",
  "user": {
    "name": "Ceyhun Alizade",
    "child_name": "Nigar Alizade",
    "role": "parent",
    "user_id": 4021,
    "parent_ids": 66,
    "class_id": 91,
    "class_name": "Class Group 4",
    "info": [$_child]
  }
}
''';

/// The leaner answer: the refreshed roster and nothing else.
const _rosterOnlyBody = '''
{
  "success": true,
  "message": "Şagird hesabınıza əlavə edildi",
  "info": [$_child]
}
''';

/// Answers every request from a canned body while recording what was asked,
/// so the test can pin the path and payload the service actually sends.
class _RecordingAdapter implements HttpClientAdapter {
  final String body;
  final int statusCode;

  RequestOptions? request;

  _RecordingAdapter({required this.body, this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(AuthServiceImpl, _RecordingAdapter) _service({
  required String body,
  int statusCode = 200,
}) {
  final adapter = _RecordingAdapter(body: body, statusCode: statusCode);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://online.bsb.edu.az/api/v1',
      // Mirrors ApiClient: 4xx bodies are read, not thrown away.
      validateStatus: (status) => status != null && status < 500,
    ),
  )..httpClientAdapter = adapter;
  return (AuthServiceImpl(dio), adapter);
}

void main() {
  test('posts the admission number to /attachChild', () async {
    final (service, adapter) = _service(body: _fullUserBody);

    await service.attachChild(admissionNo: 'BSB-4021');

    expect(adapter.request?.path, '/attachChild');
    expect(adapter.request?.data, {'admission_no': 'BSB-4021'});
  });

  test('sends the relation only when there is one', () async {
    final (service, adapter) = _service(body: _fullUserBody);

    await service.attachChild(admissionNo: 'BSB-4021', relation: 'father');

    expect(adapter.request?.data, {
      'admission_no': 'BSB-4021',
      'relation': 'father',
    });
  });

  test('reads the whole session back when the endpoint echoes one', () async {
    final (service, _) = _service(body: _fullUserBody);

    final user = await service.attachChild(admissionNo: 'BSB-4021');

    expect(user?.id, 4021);
    expect(user?.accountId, 66);
    expect(user?.role, 'parent');
    expect(user?.children, hasLength(1));
    expect(user?.children.single.paymentId, 'NA4021');
  });

  // The response has no `user_id` and no name — nothing that reads as a user.
  // Taking the roster anyway is what keeps the new student from staying
  // invisible until the next login; the repository folds it into the cached
  // session, which still holds every scalar.
  test('takes the roster when that is all the endpoint sends', () async {
    final (service, _) = _service(body: _rosterOnlyBody);

    final user = await service.attachChild(admissionNo: 'BSB-4021');

    expect(user, isNotNull);
    expect(user?.children, hasLength(1));
    expect(user?.children.single.childId, 4021);
    // Nothing was claimed about the account itself, so the repository's merge
    // keeps what it had.
    expect(user?.id, isNull);
    expect(user?.role, isEmpty);
  });

  test('an empty roster is treated as no roster at all', () async {
    final (service, _) = _service(
      body: '{"success": true, "message": "ok", "info": []}',
    );

    final user = await service.attachChild(admissionNo: 'BSB-4021');

    expect(user, isNull);
  });

  test('a bare acknowledgement is a success with nothing to cache', () async {
    final (service, _) = _service(body: '{"success": true, "message": "ok"}');

    final user = await service.attachChild(admissionNo: 'BSB-4021');

    expect(user, isNull);
  });

  // Laravel's validation body: the message under the field is the specific
  // one, so it is what the form shows.
  test('surfaces the per-field message a 422 carries', () async {
    final (service, _) = _service(
      statusCode: 422,
      body: '''
{
  "message": "The given data was invalid.",
  "errors": {"admission_no": ["Bu şagird artıq hesabınıza bağlıdır."]}
}
''',
    );

    expect(
      () => service.attachChild(admissionNo: 'BSB-4021'),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          'Bu şagird artıq hesabınıza bağlıdır.',
        ),
      ),
    );
  });

  // A 200 that isn't one — the endpoint reports failure in the body.
  test('trusts `success: false` over the status code', () async {
    final (service, _) = _service(
      body: '{"success": false, "message": "Şagird tapılmadı."}',
    );

    expect(
      () => service.attachChild(admissionNo: 'BSB-4021'),
      throwsA(
        isA<ValidationException>()
            .having((e) => e.message, 'message', 'Şagird tapılmadı.'),
      ),
    );
  });
}
