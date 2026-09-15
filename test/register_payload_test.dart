import 'dart:typed_data';

import 'package:bsbschool/core/error/exceptions.dart';
import 'package:bsbschool/features/auth/data/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What `/register` answers on success — no token, no user.
const _okBody = '''
{"success": true, "message": "Qeydiyyat tamamlandı"}
''';

/// Records what was asked, so the test can pin the payload the endpoint is
/// actually handed. Same harness as `attach_child_test.dart`.
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
  String body = _okBody,
  int statusCode = 200,
}) {
  final adapter = _RecordingAdapter(body: body, statusCode: statusCode);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://online.bsb.edu.az/api/v1',
      validateStatus: (status) => status != null && status < 500,
    ),
  )..httpClientAdapter = adapter;
  return (AuthServiceImpl(dio), adapter);
}

Future<void> _register(AuthServiceImpl service, {String phone = '0501234567'}) {
  return service.registerParent(
    name: 'Ceyhun Alizade',
    email: 'ceyhun@bsb.edu.az',
    phone: phone,
    password: 'sifre123',
    admissionNo: 'BSB-4021',
  );
}

void main() {
  test('posts every field to /register, under the keys it validates on',
      () async {
    final (service, adapter) = _service();

    await _register(service);

    expect(adapter.request?.path, '/register');
    expect(adapter.request?.data, {
      '_name_nameController': 'Ceyhun Alizade',
      '_emailController': 'ceyhun@bsb.edu.az',
      '_phoneController': '0501234567',
      '_passwordController': 'sifre123',
      '_admissionController': 'BSB-4021',
    });
  });

  // The one the parent typed reaches the wire verbatim: no normalising, no
  // stripping of the `+` or the spaces. Whatever is missing from the database
  // did not go missing here.
  test('the phone is sent exactly as it was typed', () async {
    final (service, adapter) = _service();

    await _register(service, phone: '+994 50 123 45 67');

    final data = adapter.request?.data as Map<String, dynamic>;
    expect(data['_phoneController'], '+994 50 123 45 67');
  });

  test('the relation rides along only when the form has one', () async {
    final (service, adapter) = _service();

    await service.registerParent(
      name: 'Ceyhun Alizade',
      email: 'ceyhun@bsb.edu.az',
      phone: '0501234567',
      password: 'sifre123',
      admissionNo: 'BSB-4021',
      relation: 'father',
    );

    expect((adapter.request?.data as Map)['relation'], 'father');
  });

  // The endpoint answers per-field, keyed the same way the request was — this
  // is the contract `RegisterBloc._serverFields` maps back onto the form.
  test('a rejected phone comes back under the key it was sent as', () async {
    final (service, _) = _service(
      statusCode: 422,
      body: '''
{
  "message": "Məlumatlar yanlışdır",
  "errors": {"_phoneController": ["Bu nömrə artıq istifadə olunub"]}
}
''',
    );

    await expectLater(
      _register(service),
      throwsA(isA<FieldValidationException>().having(
        (e) => e.fieldErrors['_phoneController'],
        'phone error',
        'Bu nömrə artıq istifadə olunub',
      )),
    );
  });
}
